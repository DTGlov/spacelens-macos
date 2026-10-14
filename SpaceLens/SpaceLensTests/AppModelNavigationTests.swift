import Foundation
import Testing
@testable import SpaceLens

@MainActor
struct AppModelNavigationTests {
    @Test
    func enteringAChildFolderEnablesBackAndParentNavigation() throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let childURL = rootURL.appending(path: "Child", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: childURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: rootURL) }

        let model = AppModel()
        model.beginSession(at: rootURL)
        model.navigate(to: childURL)

        #expect(model.rootURL == childURL.standardizedFileURL.resolvingSymlinksInPath())
        #expect(model.canGoBack)
        #expect(model.canGoUp)

        model.goUp()

        #expect(model.rootURL == rootURL.standardizedFileURL.resolvingSymlinksInPath())
    }
}

@MainActor
struct AppModelInsightTests {
    @Test
    func selectedInsightCanReturnToOverview() {
        let model = AppModel()

        model.toggleInsight(.largeFiles)
        #expect(model.insightFilter == .largeFiles)

        model.showOverview()
        #expect(model.insightFilter == .all)
    }

    @Test
    func selectingTheActiveInsightAgainShowsOverview() {
        let model = AppModel()

        model.toggleInsight(.notModifiedInYear)
        model.toggleInsight(.notModifiedInYear)

        #expect(model.insightFilter == .all)
    }
}

struct VolumeCapacityTests {
    @Test
    func calculatesFolderShareOfDiskCapacity() throws {
        let capacity = try #require(VolumeCapacity(totalBytes: 1_000))

        #expect(capacity.folderShare(for: 125) == 0.125)
    }

    @Test
    func clampsIncompleteOrImpossibleSizes() throws {
        let capacity = try #require(VolumeCapacity(totalBytes: 1_000))

        #expect(capacity.folderShare(for: -1) == 0)
        #expect(capacity.folderShare(for: 1_500) == 1)
    }
}
