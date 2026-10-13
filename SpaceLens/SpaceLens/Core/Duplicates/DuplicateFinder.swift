import CryptoKit
import Foundation

struct DuplicateFile: Identifiable, Hashable, Sendable {
    let url: URL
    let logicalSize: Int64
    let allocatedSize: Int64
    let modificationDate: Date?

    var id: URL { url }
    var name: String { url.lastPathComponent }

    var scanItem: ScanItem {
        ScanItem(
            id: url,
            url: url,
            name: name,
            kind: .file,
            logicalSize: logicalSize,
            allocatedSize: allocatedSize,
            modificationDate: modificationDate,
            skippedItemCount: 0
        )
    }
}

struct DuplicateGroup: Identifiable, Equatable, Sendable {
    let id: String
    let files: [DuplicateFile]

    var fileSize: Int64 { files.first?.logicalSize ?? 0 }
    var potentialSpace: Int64 { fileSize * Int64(max(files.count - 1, 0)) }
}

struct DuplicateScanProgress: Equatable, Sendable {
    enum Stage: Sendable {
        case discovering
        case hashing
    }

    var stage: Stage = .discovering
    var discoveredFileCount = 0
    var candidateFileCount = 0
    var hashedFileCount = 0
    var skippedFileCount = 0
    var currentPath = ""
}

enum DuplicateScanEvent: Sendable {
    case progress(DuplicateScanProgress)
    case finished([DuplicateGroup])
}

actor DuplicateFinder {
    private struct Candidate: Sendable {
        let file: DuplicateFile
    }

    private let fileManager: FileManager
    private let progressInterval: Int
    private let chunkSize: Int

    init(
        fileManager: FileManager = .default,
        progressInterval: Int = 100,
        chunkSize: Int = 1_048_576
    ) {
        self.fileManager = fileManager
        self.progressInterval = max(progressInterval, 1)
        self.chunkSize = max(chunkSize, 4_096)
    }

    nonisolated func findDuplicates(in scope: AuthorizedScanScope) -> AsyncThrowingStream<DuplicateScanEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let groups = try await findDuplicates(in: scope) { progress in
                        continuation.yield(.progress(progress))
                    }
                    continuation.yield(.finished(groups))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func findDuplicates(
        in scope: AuthorizedScanScope,
        progressHandler: @Sendable (DuplicateScanProgress) -> Void
    ) throws -> [DuplicateGroup] {
        var progress = DuplicateScanProgress()
        let candidates = try discoverCandidates(in: scope, progress: &progress, handler: progressHandler)
        let sizeGroups = Dictionary(grouping: candidates, by: { $0.file.logicalSize })
            .filter { $0.value.count > 1 }
        progress.stage = .hashing
        progress.candidateFileCount = sizeGroups.values.reduce(0) { $0 + $1.count }
        progressHandler(progress)

        var hashedGroups: [String: [DuplicateFile]] = [:]
        for candidates in sizeGroups.values {
            for candidate in candidates {
                try Task.checkCancellation()
                progress.currentPath = candidate.file.url.path
                do {
                    let digest = try hash(candidate)
                    let key = "\(candidate.file.logicalSize):\(digest)"
                    hashedGroups[key, default: []].append(candidate.file)
                } catch is CancellationError {
                    throw CancellationError()
                } catch {
                    progress.skippedFileCount += 1
                }
                progress.hashedFileCount += 1
                if progress.hashedFileCount.isMultiple(of: progressInterval) {
                    progressHandler(progress)
                }
            }
        }

        progressHandler(progress)
        return hashedGroups.compactMap { key, files in
            guard files.count > 1 else { return nil }
            return DuplicateGroup(
                id: key,
                files: files.sorted { $0.url.path.localizedStandardCompare($1.url.path) == .orderedAscending }
            )
        }
        .sorted { $0.potentialSpace > $1.potentialSpace }
    }

    private func discoverCandidates(
        in scope: AuthorizedScanScope,
        progress: inout DuplicateScanProgress,
        handler: @Sendable (DuplicateScanProgress) -> Void
    ) throws -> [Candidate] {
        let keys: Set<URLResourceKey> = [
            .isDirectoryKey,
            .isRegularFileKey,
            .isSymbolicLinkKey,
            .fileSizeKey,
            .fileAllocatedSizeKey,
            .totalFileAllocatedSizeKey,
            .contentModificationDateKey,
            .fileResourceIdentifierKey,
            .volumeIdentifierKey
        ]
        let rootValues = try scope.rootURL.resourceValues(forKeys: [.volumeIdentifierKey])
        guard let enumerator = fileManager.enumerator(
            at: scope.rootURL,
            includingPropertiesForKeys: Array(keys),
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            throw CocoaError(.fileReadUnknown)
        }

        var candidates: [Candidate] = []
        var seenFileIdentifiers: Set<String> = []
        while let url = enumerator.nextObject() as? URL {
            try Task.checkCancellation()
            progress.currentPath = url.path
            do {
                let values = try url.resourceValues(forKeys: keys)
                if values.isSymbolicLink == true {
                    enumerator.skipDescendants()
                    continue
                }
                if let rootVolume = rootValues.volumeIdentifier,
                   let itemVolume = values.volumeIdentifier,
                   String(describing: rootVolume) != String(describing: itemVolume) {
                    if values.isDirectory == true { enumerator.skipDescendants() }
                    progress.skippedFileCount += 1
                    continue
                }
                guard values.isRegularFile == true, let fileSize = values.fileSize, fileSize > 0 else {
                    continue
                }
                if let identifier = values.fileResourceIdentifier {
                    guard seenFileIdentifiers.insert(String(describing: identifier)).inserted else {
                        continue
                    }
                }
                let logicalSize = Int64(fileSize)
                let allocatedSize = Int64(values.totalFileAllocatedSize ?? values.fileAllocatedSize ?? fileSize)
                candidates.append(
                    Candidate(
                        file: DuplicateFile(
                            url: url,
                            logicalSize: logicalSize,
                            allocatedSize: allocatedSize,
                            modificationDate: values.contentModificationDate
                        )
                    )
                )
                progress.discoveredFileCount += 1
                if progress.discoveredFileCount.isMultiple(of: progressInterval) {
                    handler(progress)
                }
            } catch {
                progress.skippedFileCount += 1
            }
        }
        handler(progress)
        return candidates
    }

    private func hash(_ candidate: Candidate) throws -> String {
        let handle = try FileHandle(forReadingFrom: candidate.file.url)
        defer { try? handle.close() }
        var hasher = SHA256()
        while true {
            try Task.checkCancellation()
            guard let data = try handle.read(upToCount: chunkSize), !data.isEmpty else { break }
            hasher.update(data: data)
        }

        let currentValues = try candidate.file.url.resourceValues(forKeys: [
            .isRegularFileKey,
            .fileSizeKey,
            .contentModificationDateKey
        ])
        guard currentValues.isRegularFile == true,
              Int64(currentValues.fileSize ?? -1) == candidate.file.logicalSize,
              currentValues.contentModificationDate == candidate.file.modificationDate else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
}
