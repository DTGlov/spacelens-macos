import Foundation
import Testing
@testable import SpaceLens

struct DuplicateFinderTests {
    @Test
    func confirmsMatchingContentAndRejectsSameSizedDifferentContent() async throws {
        let fixture = try DuplicateFixture()
        let nestedFolder = fixture.url.appending(path: "Nested", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: nestedFolder, withIntermediateDirectories: true)
        try Data("abcdef".utf8).write(to: fixture.url.appending(path: "first.bin"))
        try Data("abcdef".utf8).write(to: nestedFolder.appending(path: "second.bin"))
        try Data("ghijkl".utf8).write(to: fixture.url.appending(path: "different.bin"))

        let groups = try await completedGroups(
            from: DuplicateFinder(progressInterval: 1, chunkSize: 4_096),
            scope: AuthorizedScanScope(rootURL: fixture.url)
        )

        let group = try #require(groups.first)
        #expect(groups.count == 1)
        #expect(group.files.map(\.name).sorted() == ["first.bin", "second.bin"])
        #expect(group.fileSize == 6)
        #expect(group.potentialSpace == 6)
    }

    @Test
    func ignoresSymbolicLinksAndEmptyFiles() async throws {
        let fixture = try DuplicateFixture()
        let original = fixture.url.appending(path: "original.bin")
        try Data("content".utf8).write(to: original)
        try FileManager.default.createSymbolicLink(
            at: fixture.url.appending(path: "linked.bin"),
            withDestinationURL: original
        )
        try Data().write(to: fixture.url.appending(path: "empty-1.bin"))
        try Data().write(to: fixture.url.appending(path: "empty-2.bin"))

        let groups = try await completedGroups(
            from: DuplicateFinder(),
            scope: AuthorizedScanScope(rootURL: fixture.url)
        )

        #expect(groups.isEmpty)
    }

    @Test
    func doesNotReportHardLinksAsReclaimableCopies() async throws {
        let fixture = try DuplicateFixture()
        let original = fixture.url.appending(path: "original.bin")
        try Data("shared allocation".utf8).write(to: original)
        try FileManager.default.linkItem(
            at: original,
            to: fixture.url.appending(path: "hard-link.bin")
        )

        let groups = try await completedGroups(
            from: DuplicateFinder(),
            scope: AuthorizedScanScope(rootURL: fixture.url)
        )

        #expect(groups.isEmpty)
    }

    @Test
    func cancellationStopsAnActiveDuplicateScan() async throws {
        let fixture = try DuplicateFixture()
        for index in 0..<500 {
            try Data(repeating: UInt8(index % 255), count: 4_096)
                .write(to: fixture.url.appending(path: "\(index).bin"))
        }

        let stream = DuplicateFinder(progressInterval: 1).findDuplicates(
            in: AuthorizedScanScope(rootURL: fixture.url)
        )
        let task = Task<Bool, Error> {
            for try await event in stream {
                if case .finished = event { return true }
            }
            return false
        }
        task.cancel()

        let receivedFinishedEvent = try await task.value
        #expect(task.isCancelled)
        #expect(receivedFinishedEvent == false)
    }

    private func completedGroups(
        from finder: DuplicateFinder,
        scope: AuthorizedScanScope
    ) async throws -> [DuplicateGroup] {
        for try await event in finder.findDuplicates(in: scope) {
            if case .finished(let groups) = event {
                return groups
            }
        }
        throw CocoaError(.fileReadUnknown)
    }
}

private final class DuplicateFixture {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory
            .appending(path: "SpaceLensDuplicates-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }
}
