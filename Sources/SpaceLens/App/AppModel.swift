import AppKit
import Observation

@MainActor
@Observable
final class AppModel {
    enum Phase: Equatable {
        case welcome
        case scanning
        case results
        case failed(String)
    }

    private(set) var phase: Phase = .welcome
    private(set) var rootURL: URL?
    private(set) var items: [ScanItem] = []
    private(set) var progress = ScanProgress()
    var selection: ScanItem.ID?
    var sortOrder = [KeyPathComparator(\ScanItem.allocatedSize, order: .reverse)]

    private let scanner: DirectoryScanner
    private var scanTask: Task<Void, Never>?

    init(scanner: DirectoryScanner = DirectoryScanner()) {
        self.scanner = scanner
    }

    var selectedItem: ScanItem? {
        guard let selection else { return nil }
        return items.first { $0.id == selection }
    }

    var displayedItems: [ScanItem] {
        Array(items.sorted(using: sortOrder).prefix(100))
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
        startScan(at: url)
    }

    func startScan(at url: URL) {
        cancelScan()
        rootURL = url
        items = []
        selection = nil
        progress = ScanProgress()
        phase = .scanning

        scanTask = Task { [weak self, scanner] in
            do {
                for try await event in scanner.scan(url: url) {
                    guard !Task.isCancelled else { return }
                    switch event {
                    case .progress(let update):
                        self?.progress = update
                    case .finished(let result):
                        self?.items = result.items
                        self?.progress = result.progress
                        self?.phase = .results
                    }
                }
            } catch is CancellationError {
                self?.phase = self?.items.isEmpty == false ? .results : .welcome
            } catch {
                self?.phase = .failed(error.localizedDescription)
            }
        }
    }

    func cancelScan() {
        scanTask?.cancel()
        scanTask = nil
        if phase == .scanning {
            phase = items.isEmpty ? .welcome : .results
        }
    }

    func revealSelectedItem() {
        guard let selectedItem else { return }
        NSWorkspace.shared.activateFileViewerSelecting([selectedItem.url])
    }
}
