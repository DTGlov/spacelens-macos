import Foundation

struct ScanItem: Identifiable, Hashable, Sendable {
    enum Kind: String, Sendable {
        case folder
        case file
        case symbolicLink
        case other
    }

    let id: URL
    let url: URL
    let name: String
    let kind: Kind
    let logicalSize: Int64
    let allocatedSize: Int64
    let modificationDate: Date?
    let skippedItemCount: Int

    var isFolder: Bool { kind == .folder }
}

struct ScanProgress: Equatable, Sendable {
    var discoveredSize: Int64 = 0
    var scannedItemCount = 0
    var skippedItemCount = 0
    var currentPath = ""
}

struct ScanResult: Sendable {
    let items: [ScanItem]
    let progress: ScanProgress
}

enum ScanEvent: Sendable {
    case progress(ScanProgress)
    case finished(ScanResult)
}
