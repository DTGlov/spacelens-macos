import Foundation
import Testing
@testable import SpaceLens

struct DirectoryScannerTests {
    @Test
    func aggregatesNestedFileSizesIntoImmediateChildren() async throws {
        let fixture = try TemporaryDirectory()
        let folder = fixture.url.appending(path: "Folder", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try Data(repeating: 1, count: 1_024).write(to: folder.appending(path: "nested.bin"))
        try Data(repeating: 2, count: 512).write(to: fixture.url.appending(path: "top.bin"))

        let result = try await completedResult(from: DirectoryScanner(progressInterval: 1), url: fixture.url)

        #expect(result.items.count == 2)
        #expect(result.items.first(where: { $0.name == "Folder" })?.logicalSize == 1_024)
        #expect(result.items.first(where: { $0.name == "top.bin" })?.logicalSize == 512)
        #expect(result.progress.scannedItemCount == 3)
    }

    @Test
    func doesNotFollowSymbolicLinks() async throws {
        let fixture = try TemporaryDirectory()
        let target = fixture.url.appending(path: "target.bin")
        let link = fixture.url.appending(path: "target-link")
        try Data(repeating: 1, count: 2_048).write(to: target)
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: target)

        let result = try await completedResult(from: DirectoryScanner(), url: fixture.url)
        let linkedItem = try #require(result.items.first(where: { $0.name == "target-link" }))
        let targetItem = try #require(result.items.first(where: { $0.name == "target.bin" }))

        #expect(linkedItem.kind == .symbolicLink)
        #expect(linkedItem.logicalSize == 0)
        #expect(result.progress.discoveredSize == targetItem.allocatedSize)
    }

    @Test
    func cancellationStopsAnActiveScan() async throws {
        let fixture = try TemporaryDirectory()
        for index in 0..<2_000 {
            try Data([0]).write(to: fixture.url.appending(path: "\(index).bin"))
        }

        let stream = DirectoryScanner(progressInterval: 1).scan(url: fixture.url)
        let task = Task<Bool, Error> {
            for try await event in stream {
                if case .finished = event {
                    return true
                }
            }
            return false
        }
        task.cancel()

        let receivedFinishedEvent = try await task.value
        #expect(task.isCancelled)
        #expect(receivedFinishedEvent == false)
    }

    private func completedResult(from scanner: DirectoryScanner, url: URL) async throws -> ScanResult {
        for try await event in scanner.scan(url: url) {
            if case .finished(let result) = event {
                return result
            }
        }
        throw CocoaError(.fileReadUnknown)
    }
}

struct TreemapLayoutTests {
    @Test
    func createsProportionalNonOverlappingFrames() throws {
        let bounds = CGRect(x: 0, y: 0, width: 1_000, height: 600)
        let entries = TreemapLayout().entries(for: [50, 30, 20], in: bounds)

        #expect(entries.count == 3)
        #expect(entries.allSatisfy { bounds.contains($0.frame) })
        #expect(entries[0].frame.area / bounds.area == 0.5)
        #expect(entries[1].frame.area / bounds.area == 0.3)
        #expect(entries[2].frame.area / bounds.area == 0.2)

        for firstIndex in entries.indices {
            for secondIndex in entries.indices where firstIndex < secondIndex {
                #expect(entries[firstIndex].frame.intersection(entries[secondIndex].frame).area == 0)
            }
        }
    }

    @Test
    func ignoresItemsWithoutAllocatedSize() {
        let entries = TreemapLayout().entries(
            for: [100, 0, -1],
            in: CGRect(x: 0, y: 0, width: 500, height: 300)
        )

        #expect(entries == [TreemapLayout.Entry(index: 0, frame: CGRect(x: 0, y: 0, width: 500, height: 300))])
    }
}

struct AuthorizedScanScopeTests {
    @Test
    func acceptsOnlyRootAndDescendantPaths() {
        let scope = AuthorizedScanScope(rootURL: URL(fileURLWithPath: "/Users/example/Downloads"))

        #expect(scope.contains(URL(fileURLWithPath: "/Users/example/Downloads")))
        #expect(scope.contains(URL(fileURLWithPath: "/Users/example/Downloads/Archive/file.zip")))
        #expect(!scope.contains(URL(fileURLWithPath: "/Users/example/Downloads-old/file.zip")))
        #expect(!scope.contains(URL(fileURLWithPath: "/Users/example/Documents/file.zip")))
    }

    @Test
    func createsBreadcrumbsFromAuthorizedRoot() {
        let root = URL(fileURLWithPath: "/Users/example/Downloads")
        let scope = AuthorizedScanScope(rootURL: root)

        let breadcrumbs = scope.breadcrumbs(
            to: URL(fileURLWithPath: "/Users/example/Downloads/Archive/2025")
        )

        #expect(breadcrumbs.map(\.lastPathComponent) == ["Downloads", "Archive", "2025"])
    }

    @Test
    func rejectsDescendantSymlinkThatEscapesRoot() throws {
        let authorizedDirectory = try TemporaryDirectory()
        let outsideDirectory = try TemporaryDirectory()
        let outsideFile = outsideDirectory.url.appending(path: "private.bin")
        try Data([0]).write(to: outsideFile)
        let link = authorizedDirectory.url.appending(path: "escape")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: outsideDirectory.url)

        let scope = AuthorizedScanScope(rootURL: authorizedDirectory.url)

        #expect(!scope.contains(link.appending(path: "private.bin")))
    }
}

private extension CGRect {
    var area: CGFloat { width * height }
}

private final class TemporaryDirectory {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory
            .appending(path: "SpaceLensTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }
}
