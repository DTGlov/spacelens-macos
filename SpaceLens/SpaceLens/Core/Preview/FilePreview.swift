import Foundation

enum FilePreview {
    static func isAvailable(for item: ScanItem, fileManager: FileManager = .default) -> Bool {
        guard item.kind == .file || item.kind == .other else { return false }
        return fileManager.fileExists(atPath: item.url.path)
    }
}
