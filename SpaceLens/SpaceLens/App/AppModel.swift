import AppKit
import Observation

@MainActor
@Observable
final class AppModel {
    struct TrashAlert: Identifiable {
        enum Kind {
            case confirmation(TrashRequest)
            case message(title: String, message: String)
        }

        let id = UUID()
        let kind: Kind
    }

    enum ItemFilter: String, CaseIterable, Identifiable {
        case all = "All items"
        case folders = "Folders"
        case files = "Files"

        var id: Self { self }
    }

    enum MinimumSizeFilter: String, CaseIterable, Identifiable {
        case any = "Any size"
        case oneHundredMegabytes = "100 MB+"
        case oneGigabyte = "1 GB+"
        case tenGigabytes = "10 GB+"

        var id: Self { self }

        var bytes: Int64 {
            switch self {
            case .any: 0
            case .oneHundredMegabytes: 100_000_000
            case .oneGigabyte: 1_000_000_000
            case .tenGigabytes: 10_000_000_000
            }
        }
    }

    enum InsightFilter: String, CaseIterable, Identifiable {
        case all
        case largeFiles
        case notModifiedInYear

        var id: Self { self }

        var title: String {
            switch self {
            case .all: "All items"
            case .largeFiles: "Large files"
            case .notModifiedInYear: "Not modified in 1 year"
            }
        }

        var systemImage: String {
            switch self {
            case .all: "square.grid.2x2"
            case .largeFiles: "externaldrive.fill.badge.plus"
            case .notModifiedInYear: "clock.arrow.trianglehead.counterclockwise.rotate.90"
            }
        }

        func matches(_ item: ScanItem, referenceDate: Date = .now) -> Bool {
            switch self {
            case .all:
                return true
            case .largeFiles:
                return !item.isFolder && item.allocatedSize >= 1_000_000_000
            case .notModifiedInYear:
                guard !item.isFolder, let modificationDate = item.modificationDate else { return false }
                let cutoff = Calendar.current.date(
                    byAdding: .year,
                    value: -1,
                    to: referenceDate
                ) ?? referenceDate
                return modificationDate <= cutoff
            }
        }
    }

    struct InsightSummary: Equatable {
        let itemCount: Int
        let allocatedSize: Int64
    }

    enum Phase: Equatable {
        case welcome
        case scanning
        case results
        case failed(String)
    }

    enum DuplicateScanState: Equatable {
        case idle
        case scanning(DuplicateScanProgress)
        case finished([DuplicateGroup])
        case failed(String)
    }

    private(set) var phase: Phase = .welcome
    private(set) var rootURL: URL?
    private(set) var authorizedScope: AuthorizedScanScope?
    private(set) var items: [ScanItem] = []
    private(set) var progress = ScanProgress()
    var selection: ScanItem.ID? {
        didSet {
            if previewURL != nil {
                previewURL = previewableSelectedItem?.url
            }
        }
    }
    var previewURL: URL?
    var trashAlert: TrashAlert?
    var searchText = ""
    var itemFilter: ItemFilter = .all
    var minimumSizeFilter: MinimumSizeFilter = .any
    var insightFilter: InsightFilter = .all
    var isDuplicateFinderPresented = false
    private(set) var duplicateScanState: DuplicateScanState = .idle
    @ObservationIgnored
    var sortOrder: [KeyPathComparator<ScanItem>]

    private let scanner: DirectoryScanner
    private let trashService: TrashService
    private let duplicateFinder: DuplicateFinder
    private var scanTask: Task<Void, Never>?
    private var duplicateScanTask: Task<Void, Never>?
    private var scanID = UUID()
    private var backStack: [URL] = []
    private var cachedResults: [URL: ScanResult] = [:]

    init(
        scanner: DirectoryScanner = DirectoryScanner(),
        trashService: TrashService = TrashService(),
        duplicateFinder: DuplicateFinder = DuplicateFinder()
    ) {
        self.scanner = scanner
        self.trashService = trashService
        self.duplicateFinder = duplicateFinder
        sortOrder = [KeyPathComparator(\ScanItem.allocatedSize, order: .reverse)]
    }

    var selectedItem: ScanItem? {
        guard let selection else { return nil }
        return items.first { $0.id == selection }
    }

    var previewableSelectedItem: ScanItem? {
        guard let selectedItem, FilePreview.isAvailable(for: selectedItem) else { return nil }
        return selectedItem
    }

    var canMoveSelectedItemToTrash: Bool {
        guard let selectedItem, selectedItem.skippedItemCount == 0 else { return false }
        let classification = ItemClassification.classify(selectedItem)
        return SafetyAssessment.assess(selectedItem, classification: classification).level != .protectedOrUnknown
    }

    var displayedItems: [ScanItem] {
        let filteredItems = items.filter { item in
            let matchesSearch = FileNameSearch.matches(item.name, query: searchText)
            let matchesMinimumSize = item.allocatedSize >= minimumSizeFilter.bytes
            let matchesInsight = insightFilter.matches(item)
            let matchesFilter = switch itemFilter {
            case .all: true
            case .folders: item.isFolder
            case .files: !item.isFolder
            }
            return matchesSearch && matchesMinimumSize && matchesInsight && matchesFilter
        }
        return Array(filteredItems.sorted(using: sortOrder).prefix(100))
    }

    var hasActiveFilters: Bool {
        !searchText.isEmpty
            || itemFilter != .all
            || minimumSizeFilter != .any
            || insightFilter != .all
    }

    func clearFilters() {
        searchText = ""
        itemFilter = .all
        minimumSizeFilter = .any
        insightFilter = .all
    }

    func insightSummary(for insight: InsightFilter) -> InsightSummary {
        let matchingItems = items.filter { insight.matches($0) }
        return InsightSummary(
            itemCount: matchingItems.count,
            allocatedSize: matchingItems.reduce(0) { $0 + $1.allocatedSize }
        )
    }

    var breadcrumbs: [URL] {
        guard let authorizedScope, let rootURL else { return [] }
        return authorizedScope.breadcrumbs(to: rootURL)
    }

    var canGoBack: Bool { !backStack.isEmpty }

    var canGoUp: Bool {
        guard let authorizedScope, let rootURL else { return false }
        return rootURL != authorizedScope.rootURL
    }

    func chooseFolder() {
        let panel = NSOpenPanel()
        panel.title = "Choose a folder to scan"
        panel.prompt = "Scan Folder"
        panel.message = "SpaceLens scans only the folder you choose. Nothing will be deleted."
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let url = panel.url else { return }
        beginSession(at: url)
    }

    func beginSession(at url: URL) {
        cancelDuplicateScan()
        isDuplicateFinderPresented = false
        authorizedScope = AuthorizedScanScope(rootURL: url)
        backStack = []
        cachedResults = [:]
        loadFolder(at: authorizedScope?.rootURL ?? url)
    }

    func openSelectedFolder() {
        guard let selectedItem else { return }
        openFolder(selectedItem)
    }

    func openFolder(_ item: ScanItem) {
        guard item.isFolder else { return }
        navigate(to: item.url)
    }

    func navigate(to url: URL) {
        guard let authorizedScope, authorizedScope.contains(url), url != rootURL else { return }
        if let rootURL {
            backStack.append(rootURL)
        }
        loadFolder(at: url)
    }

    func goBack() {
        guard let destination = backStack.popLast() else { return }
        loadFolder(at: destination)
    }

    func goUp() {
        guard let rootURL, canGoUp else { return }
        navigate(to: rootURL.deletingLastPathComponent())
    }

    private func loadFolder(at url: URL) {
        cancelScan()
        let canonicalURL = url.standardizedFileURL.resolvingSymlinksInPath()
        rootURL = canonicalURL
        searchText = ""
        itemFilter = .all
        minimumSizeFilter = .any
        insightFilter = .all
        items = []
        selection = nil
        progress = ScanProgress()

        if let cachedResult = cachedResults[canonicalURL] {
            apply(cachedResult)
            return
        }

        phase = .scanning
        let currentScanID = UUID()
        scanID = currentScanID

        scanTask = Task { [weak self, scanner] in
            do {
                for try await event in scanner.scan(url: canonicalURL) {
                    guard !Task.isCancelled else { return }
                    guard self?.scanID == currentScanID else { return }
                    switch event {
                    case .progress(let update):
                        self?.progress = update
                    case .finished(let result):
                        self?.cachedResults[canonicalURL] = result
                        self?.apply(result)
                    }
                }
            } catch is CancellationError {
                guard self?.scanID == currentScanID else { return }
                self?.phase = self?.items.isEmpty == false ? .results : .welcome
            } catch {
                guard self?.scanID == currentScanID else { return }
                self?.phase = .failed(error.localizedDescription)
            }
        }
    }

    private func apply(_ result: ScanResult) {
        items = result.items
        progress = result.progress
        phase = .results
    }

    func cancelScan() {
        scanTask?.cancel()
        scanTask = nil
        scanID = UUID()
        if phase == .scanning {
            phase = items.isEmpty ? .welcome : .results
        }
    }

    func revealSelectedItem() {
        guard let selectedItem else { return }
        NSWorkspace.shared.activateFileViewerSelecting([selectedItem.url])
    }

    func previewSelectedItem() {
        previewURL = previewableSelectedItem?.url
    }

    func requestMoveSelectedItemToTrash() {
        guard let selectedItem, let authorizedScope else { return }
        Task { [weak self, trashService] in
            do {
                let request = try await trashService.prepare(
                    item: selectedItem,
                    authorizedScope: authorizedScope
                )
                self?.trashAlert = TrashAlert(kind: .confirmation(request))
            } catch {
                self?.presentTrashError(error)
            }
        }
    }

    func presentDuplicateFinder() {
        isDuplicateFinderPresented = true
        if case .idle = duplicateScanState {
            startDuplicateScan()
        }
    }

    func dismissDuplicateFinder() {
        cancelDuplicateScan()
        isDuplicateFinderPresented = false
    }

    func startDuplicateScan() {
        guard let authorizedScope else { return }
        cancelDuplicateScan()
        duplicateScanState = .scanning(DuplicateScanProgress())
        duplicateScanTask = Task { [weak self, duplicateFinder] in
            do {
                for try await event in duplicateFinder.findDuplicates(in: authorizedScope) {
                    guard !Task.isCancelled else { return }
                    switch event {
                    case .progress(let progress):
                        self?.duplicateScanState = .scanning(progress)
                    case .finished(let groups):
                        self?.duplicateScanState = .finished(groups)
                    }
                }
            } catch is CancellationError {
                guard self?.isDuplicateFinderPresented == true else { return }
                self?.duplicateScanState = .idle
            } catch {
                self?.duplicateScanState = .failed(error.localizedDescription)
            }
        }
    }

    func cancelDuplicateScan() {
        duplicateScanTask?.cancel()
        duplicateScanTask = nil
        if case .scanning = duplicateScanState {
            duplicateScanState = .idle
        }
    }

    func previewDuplicate(_ file: DuplicateFile) {
        previewURL = file.url
    }

    func revealDuplicate(_ file: DuplicateFile) {
        NSWorkspace.shared.activateFileViewerSelecting([file.url])
    }

    func requestMoveDuplicateToTrash(_ file: DuplicateFile) {
        guard let authorizedScope else { return }
        Task { [weak self, trashService] in
            do {
                let request = try await trashService.prepare(
                    item: file.scanItem,
                    authorizedScope: authorizedScope
                )
                self?.trashAlert = TrashAlert(kind: .confirmation(request))
            } catch {
                self?.presentTrashError(error)
            }
        }
    }

    func confirmMoveToTrash(_ request: TrashRequest) {
        Task { [weak self, trashService] in
            do {
                let result = try await trashService.moveToTrash(request)
                guard let self else { return }
                let folderToReload = rootURL
                cachedResults = [:]
                if let folderToReload {
                    loadFolder(at: folderToReload)
                }
                if isDuplicateFinderPresented {
                    startDuplicateScan()
                }
                trashAlert = TrashAlert(
                    kind: .message(
                        title: "Moved to Trash",
                        message: "“\(result.item.name)” was moved to Trash. Its space becomes available after you empty Trash."
                    )
                )
            } catch {
                self?.presentTrashError(error)
            }
        }
    }

    private func presentTrashError(_ error: Error) {
        trashAlert = TrashAlert(
            kind: .message(
                title: "Couldn’t Move to Trash",
                message: error.localizedDescription
            )
        )
    }
}
