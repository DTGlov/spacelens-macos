import Foundation

actor DirectoryScanner {
    private struct FindingsAccumulator {
        private(set) var largestFiles: [ScanItem] = []
        private(set) var largeFileCount = 0
        private(set) var largeFileAllocatedSize: Int64 = 0
        private(set) var oldLargeFileCount = 0
        private(set) var oldLargeFileAllocatedSize: Int64 = 0
        let oldestIncludedDate: Date
        let largeFileThreshold: Int64
        let limit: Int

        mutating func record(_ item: ScanItem) {
            guard item.kind == .file, item.allocatedSize > 0 else { return }

            if item.allocatedSize >= largeFileThreshold {
                largeFileCount += 1
                largeFileAllocatedSize += item.allocatedSize
                if let modificationDate = item.modificationDate,
                   modificationDate <= oldestIncludedDate {
                    oldLargeFileCount += 1
                    oldLargeFileAllocatedSize += item.allocatedSize
                }
            }

            let insertionIndex = largestFiles.firstIndex {
                $0.allocatedSize < item.allocatedSize
            } ?? largestFiles.endIndex
            guard insertionIndex < limit else { return }
            largestFiles.insert(item, at: insertionIndex)
            if largestFiles.count > limit {
                largestFiles.removeLast()
            }
        }

        var findings: ScanFindings {
            ScanFindings(
                largestFiles: largestFiles,
                largeFileCount: largeFileCount,
                largeFileAllocatedSize: largeFileAllocatedSize,
                oldLargeFileCount: oldLargeFileCount,
                oldLargeFileAllocatedSize: oldLargeFileAllocatedSize
            )
        }
    }

    private let fileManager: FileManager
    private let progressInterval: Int
    private let largeFileThreshold: Int64
    private let findingsLimit: Int

    init(
        fileManager: FileManager = .default,
        progressInterval: Int = 250,
        largeFileThreshold: Int64 = 1_000_000_000,
        findingsLimit: Int = 200
    ) {
        self.fileManager = fileManager
        self.progressInterval = max(progressInterval, 1)
        self.largeFileThreshold = max(largeFileThreshold, 1)
        self.findingsLimit = max(findingsLimit, 1)
    }

    nonisolated func scan(
        url rootURL: URL,
        excluding excludedURLs: Set<URL> = []
    ) -> AsyncThrowingStream<ScanEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let result = try await scanDirectory(rootURL, excluding: excludedURLs) { progress in
                        continuation.yield(.progress(progress))
                    }
                    continuation.yield(.finished(result))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func scanDirectory(
        _ rootURL: URL,
        excluding excludedURLs: Set<URL>,
        progressHandler: @Sendable (ScanProgress) -> Void
    ) async throws -> ScanResult {
        try Task.checkCancellation()

        let rootValues = try rootURL.resourceValues(forKeys: [.isDirectoryKey, .volumeIdentifierKey])
        guard rootValues.isDirectory == true else {
            throw CocoaError(.fileReadUnsupportedScheme)
        }

        let childKeys: Set<URLResourceKey> = [
            .isDirectoryKey,
            .isRegularFileKey,
            .isSymbolicLinkKey,
            .fileSizeKey,
            .fileAllocatedSizeKey,
            .totalFileSizeKey,
            .totalFileAllocatedSizeKey,
            .contentModificationDateKey,
            .volumeIdentifierKey
        ]

        let children = try fileManager.contentsOfDirectory(
            at: rootURL,
            includingPropertiesForKeys: Array(childKeys),
            options: [.skipsHiddenFiles]
        )

        var progress = ScanProgress()
        var results: [ScanItem] = []
        let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: .now) ?? .distantPast
        var findings = FindingsAccumulator(
            oldestIncludedDate: oneYearAgo,
            largeFileThreshold: largeFileThreshold,
            limit: findingsLimit
        )

        for child in children {
            try Task.checkCancellation()
            guard let accumulator = try scanTree(
                at: child,
                rootVolumeIdentifier: rootValues.volumeIdentifier,
                keys: childKeys,
                excludedURLs: excludedURLs,
                progress: &progress,
                findings: &findings,
                progressHandler: progressHandler
            ) else { continue }
            results.append(accumulator.item)
        }

        progressHandler(progress)
        return ScanResult(items: results, progress: progress, findings: findings.findings)
    }

    private func scanTree(
        at url: URL,
        rootVolumeIdentifier: Any?,
        keys: Set<URLResourceKey>,
        excludedURLs: Set<URL>,
        progress: inout ScanProgress,
        findings: inout FindingsAccumulator,
        progressHandler: @Sendable (ScanProgress) -> Void
    ) throws -> (item: ScanItem, logicalSize: Int64, allocatedSize: Int64)? {
        try Task.checkCancellation()
        progress.currentPath = url.path

        if excludedURLs.contains(url.standardizedFileURL.resolvingSymlinksInPath()) {
            progress.excludedFolderCount += 1
            progressHandler(progress)
            return nil
        }

        let values: URLResourceValues
        do {
            values = try url.resourceValues(forKeys: keys)
        } catch {
            progress.skippedItemCount += 1
            return (makeSkippedItem(url: url), 0, 0)
        }

        if values.isSymbolicLink == true {
            progress.scannedItemCount += 1
            publishProgressIfNeeded(progress, handler: progressHandler)
            let item = ScanItem(
                id: url,
                url: url,
                name: url.lastPathComponent,
                kind: .symbolicLink,
                logicalSize: 0,
                allocatedSize: 0,
                modificationDate: values.contentModificationDate,
                skippedItemCount: 0
            )
            return (item, 0, 0)
        }

        if let rootVolumeIdentifier,
           let itemVolumeIdentifier = values.volumeIdentifier,
           !volumeIdentifiersMatch(rootVolumeIdentifier, itemVolumeIdentifier) {
            progress.skippedItemCount += 1
            return (makeSkippedItem(url: url), 0, 0)
        }

        if values.isDirectory == true {
            var logicalSize: Int64 = 0
            var allocatedSize: Int64 = 0
            let skippedBefore = progress.skippedItemCount

            do {
                let children = try fileManager.contentsOfDirectory(
                    at: url,
                    includingPropertiesForKeys: Array(keys),
                    options: [.skipsHiddenFiles]
                )
                for child in children {
                    guard let childResult = try scanTree(
                        at: child,
                        rootVolumeIdentifier: rootVolumeIdentifier,
                        keys: keys,
                        excludedURLs: excludedURLs,
                        progress: &progress,
                        findings: &findings,
                        progressHandler: progressHandler
                    ) else { continue }
                    logicalSize += childResult.logicalSize
                    allocatedSize += childResult.allocatedSize
                }
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                progress.skippedItemCount += 1
            }

            progress.scannedItemCount += 1
            publishProgressIfNeeded(progress, handler: progressHandler)
            let item = ScanItem(
                id: url,
                url: url,
                name: url.lastPathComponent,
                kind: .folder,
                logicalSize: logicalSize,
                allocatedSize: allocatedSize,
                modificationDate: values.contentModificationDate,
                skippedItemCount: progress.skippedItemCount - skippedBefore
            )
            return (item, logicalSize, allocatedSize)
        }

        let logicalSizeValue = values.totalFileSize ?? values.fileSize ?? 0
        let allocatedSizeValue = values.totalFileAllocatedSize ?? values.fileAllocatedSize ?? logicalSizeValue
        let logicalSize = Int64(logicalSizeValue)
        let allocatedSize = Int64(allocatedSizeValue)
        progress.scannedItemCount += 1
        progress.discoveredSize += allocatedSize
        publishProgressIfNeeded(progress, handler: progressHandler)
        let kind: ScanItem.Kind = values.isRegularFile == true ? .file : .other
        let item = ScanItem(
            id: url,
            url: url,
            name: url.lastPathComponent,
            kind: kind,
            logicalSize: logicalSize,
            allocatedSize: allocatedSize,
            modificationDate: values.contentModificationDate,
            skippedItemCount: 0
        )
        findings.record(item)
        return (item, logicalSize, allocatedSize)
    }

    private func publishProgressIfNeeded(
        _ progress: ScanProgress,
        handler: @Sendable (ScanProgress) -> Void
    ) {
        if progress.scannedItemCount.isMultiple(of: progressInterval) {
            handler(progress)
        }
    }

    private func makeSkippedItem(url: URL) -> ScanItem {
        ScanItem(
            id: url,
            url: url,
            name: url.lastPathComponent,
            kind: .other,
            logicalSize: 0,
            allocatedSize: 0,
            modificationDate: nil,
            skippedItemCount: 1
        )
    }

    private func volumeIdentifiersMatch(_ lhs: Any, _ rhs: Any) -> Bool {
        String(describing: lhs) == String(describing: rhs)
    }
}
