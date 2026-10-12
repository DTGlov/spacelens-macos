import CoreGraphics
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

struct DirectoryScannerPerformanceTests {
    @Test
    func scansARepresentativeLargeFixtureWithinTheRegressionBudget() async throws {
        let fixture = try TemporaryDirectory()
        for folderIndex in 0..<25 {
            let folder = fixture.url.appending(path: "Folder-\(folderIndex)", directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            for fileIndex in 0..<100 {
                try Data([0]).write(to: folder.appending(path: "File-\(fileIndex).bin"))
            }
        }

        let clock = ContinuousClock()
        let start = clock.now
        let result = try await completedScan(from: DirectoryScanner(), url: fixture.url)
        let elapsed = start.duration(to: clock.now)

        #expect(result.progress.scannedItemCount == 2_525)
        #expect(elapsed < .seconds(5), "A 2,500-file scan took \(elapsed)")
    }

    private func completedScan(from scanner: DirectoryScanner, url: URL) async throws -> ScanResult {
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

struct FileNameSearchTests {
    @Test(arguments: ["ted", "ted lasso", "tedlasso", "TED-LASSO", "ted_lasso"])
    func treatsFilenameSeparatorsLikeSpaces(query: String) {
        #expect(FileNameSearch.matches("ted.lasso.s03e01.mkv", query: query))
    }

    @Test
    func stillRejectsUnrelatedNames() {
        #expect(!FileNameSearch.matches("ted.lasso.s03e01.mkv", query: "severance"))
    }
}

struct FilePreviewTests {
    @Test
    func allowsExistingFilesButNotFoldersOrMissingFiles() throws {
        let fixture = try TemporaryDirectory()
        let fileURL = fixture.url.appending(path: "preview.pdf")
        try Data([0]).write(to: fileURL)

        #expect(FilePreview.isAvailable(for: scanItem(at: fileURL, kind: .file)))
        #expect(!FilePreview.isAvailable(for: scanItem(at: fixture.url, kind: .folder)))
        #expect(!FilePreview.isAvailable(for: scanItem(at: fixture.url.appending(path: "missing.pdf"), kind: .file)))
    }

    private func scanItem(at url: URL, kind: ScanItem.Kind) -> ScanItem {
        ScanItem(
            id: url,
            url: url,
            name: url.lastPathComponent,
            kind: kind,
            logicalSize: 0,
            allocatedSize: 0,
            modificationDate: nil,
            skippedItemCount: 0
        )
    }
}

struct ItemClassificationTests {
  @Test(arguments: [
    ("backup.zip", ItemClassification.Category.archive),
    ("movie.mp4", ItemClassification.Category.video),
    ("photo.heic", ItemClassification.Category.image),
    ("notes.pdf", ItemClassification.Category.document),
    ("main.swift", ItemClassification.Category.developer),
  ])
  func classifiesCommonFileTypes(name: String, expectedCategory: ItemClassification.Category) {
    let item = scanItem(path: "/Users/example/Downloads/\(name)")

    #expect(ItemClassification.classify(item).category == expectedCategory)
  }

  @Test
  func recognizesApplicationBundles() {
    let item = scanItem(path: "/Applications/Example.app", kind: .folder)

    #expect(ItemClassification.classify(item).category == .application)
  }
}

struct SafetyAssessmentTests {
  @Test
  func recognizesOnlySpecificReproducibleLocations() {
    let cache = assessment(for: "/Users/example/Library/Caches/com.example/cache.bin")
    let derivedData = assessment(
      for: "/Users/example/Library/Developer/Xcode/DerivedData/App/Build")

    #expect(cache.level == .knownReproducible)
    #expect(derivedData.level == .knownReproducible)
  }

  @Test
  func requiresReviewForDownloadsAndUserContent() {
    #expect(assessment(for: "/Users/example/Downloads/archive.zip").level == .reviewCarefully)
    #expect(assessment(for: "/Users/example/Documents/budget.xlsx").level == .reviewCarefully)
  }

  @Test
  func protectsSystemCredentialsAndUnknownLocations() {
    #expect(
      assessment(for: "/System/Library/CoreServices/Finder.app", kind: .folder).level
        == .protectedOrUnknown)
    #expect(assessment(for: "/Users/example/.ssh/id_ed25519").level == .protectedOrUnknown)
    #expect(assessment(for: "/Volumes/External/mystery.bin").level == .protectedOrUnknown)
  }

  @Test
  func protectsFoldersWithUninspectedContents() {
    let item = scanItem(
      path: "/Users/example/Documents/Incomplete",
      kind: .folder,
      skippedItemCount: 1
    )

    #expect(
      SafetyAssessment.assess(item, classification: ItemClassification.classify(item)).level
        == .protectedOrUnknown)
  }

  private func assessment(for path: String, kind: ScanItem.Kind = .file) -> SafetyAssessment {
    let item = scanItem(path: path, kind: kind)
    return SafetyAssessment.assess(item, classification: ItemClassification.classify(item))
  }
}

struct TrashServiceTests {
  @Test
  func movesARevalidatedItemUsingTheInjectedTrashOperation() async throws {
    let fixture = try TemporaryDirectory()
    let cacheFolder = fixture.url.appending(path: "Library/Caches", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: cacheFolder, withIntermediateDirectories: true)
    let fileURL = cacheFolder.appending(path: "rebuildable.bin")
    let destinationURL = fixture.url.appending(path: "trashed.bin")
    try Data([0]).write(to: fileURL)
    let service = TrashService { url in
      try FileManager.default.moveItem(at: url, to: destinationURL)
    }

    let request = try await service.prepare(
      item: scanItem(path: fileURL.path),
      authorizedScope: AuthorizedScanScope(rootURL: fixture.url)
    )
    let result = try await service.moveToTrash(request)

    #expect(result.item.url == fileURL)
    #expect(!FileManager.default.fileExists(atPath: fileURL.path))
    #expect(FileManager.default.fileExists(atPath: destinationURL.path))
  }

  @Test
  func rejectsItemsOutsideTheAuthorizedScope() async throws {
    let authorized = try TemporaryDirectory()
    let outside = try TemporaryDirectory()
    let fileURL = outside.url.appending(path: "Library/Caches/file.bin")
    try FileManager.default.createDirectory(
      at: fileURL.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    try Data([0]).write(to: fileURL)
    let service = TrashService { _ in }

    do {
      _ = try await service.prepare(
        item: scanItem(path: fileURL.path),
        authorizedScope: AuthorizedScanScope(rootURL: authorized.url)
      )
      Issue.record("Expected the out-of-scope item to be rejected")
    } catch let error as TrashServiceError {
      #expect(error == .outsideAuthorizedScope)
    }
  }

  @Test
  func rejectsProtectedItemsEvenWhenTheServiceIsCalledDirectly() async throws {
    let fixture = try TemporaryDirectory()
    let fileURL = fixture.url.appending(path: "unknown.bin")
    try Data([0]).write(to: fileURL)
    let service = TrashService { _ in
      Issue.record("The Trash operation must not run for a protected item")
    }

    do {
      _ = try await service.prepare(
        item: scanItem(path: fileURL.path),
        authorizedScope: AuthorizedScanScope(rootURL: fixture.url)
      )
      Issue.record("Expected the protected item to be rejected")
    } catch let error as TrashServiceError {
      #expect(error == .protectedItem)
    }
  }

  @Test
  func rejectsAnItemWhoseIdentityChangedAfterConfirmation() async throws {
    let fixture = try TemporaryDirectory()
    let cacheFolder = fixture.url.appending(path: "Library/Caches", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: cacheFolder, withIntermediateDirectories: true)
    let fileURL = cacheFolder.appending(path: "changing.bin")
    try Data([0]).write(to: fileURL)
    let service = TrashService { _ in }
    let request = try await service.prepare(
      item: scanItem(path: fileURL.path),
      authorizedScope: AuthorizedScanScope(rootURL: fixture.url)
    )
    let changedRequest = TrashRequest(
      item: request.item,
      authorizedScope: request.authorizedScope,
      expectedIdentity: FileIdentity(
        volumeNumber: request.expectedIdentity.volumeNumber,
        fileNumber: request.expectedIdentity.fileNumber &+ 1
      ),
      assessment: request.assessment
    )

    do {
      _ = try await service.moveToTrash(changedRequest)
      Issue.record("Expected the changed item to be rejected")
    } catch let error as TrashServiceError {
      #expect(error == .itemChanged)
    }
  }
}

private func scanItem(
  path: String,
  kind: ScanItem.Kind = .file,
  skippedItemCount: Int = 0
) -> ScanItem {
  let url = URL(fileURLWithPath: path)
  return ScanItem(
    id: url,
    url: url,
    name: url.lastPathComponent,
    kind: kind,
    logicalSize: 0,
    allocatedSize: 0,
    modificationDate: nil,
    skippedItemCount: skippedItemCount
  )
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
