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
    var excludedFolderCount = 0
    var currentPath = ""
}

struct ScanResult: Sendable {
    let items: [ScanItem]
    let progress: ScanProgress
    let findings: ScanFindings
}

struct ScanFindings: Equatable, Sendable {
    let largestFiles: [ScanItem]
    let largeFileCount: Int
    let largeFileAllocatedSize: Int64
    let oldLargeFileCount: Int
    let oldLargeFileAllocatedSize: Int64

    static let empty = ScanFindings(
        largestFiles: [],
        largeFileCount: 0,
        largeFileAllocatedSize: 0,
        oldLargeFileCount: 0,
        oldLargeFileAllocatedSize: 0
    )
}

enum ScanEvent: Sendable {
    case progress(ScanProgress)
    case finished(ScanResult)
}
