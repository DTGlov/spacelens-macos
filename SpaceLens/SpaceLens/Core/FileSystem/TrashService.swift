import Foundation

struct FileIdentity: Equatable, Sendable {
    let volumeNumber: UInt64
    let fileNumber: UInt64

    static func read(from url: URL, fileManager: FileManager = .default) throws -> FileIdentity {
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        guard
            let volumeNumber = (attributes[.systemNumber] as? NSNumber)?.uint64Value,
            let fileNumber = (attributes[.systemFileNumber] as? NSNumber)?.uint64Value
        else {
            throw TrashServiceError.identityUnavailable
        }
        return FileIdentity(volumeNumber: volumeNumber, fileNumber: fileNumber)
    }
}

struct TrashRequest: Sendable {
    let item: ScanItem
    let authorizedScope: AuthorizedScanScope
    let expectedIdentity: FileIdentity
    let assessment: SafetyAssessment
}

struct TrashResult: Sendable {
    let item: ScanItem
}

enum TrashServiceError: LocalizedError, Equatable {
    case outsideAuthorizedScope
    case protectedItem
    case symbolicLink
    case incompleteFolder
    case identityUnavailable
    case itemChanged

    var errorDescription: String? {
        switch self {
        case .outsideAuthorizedScope:
            "The item is no longer inside the folder you authorized."
        case .protectedItem:
            "SpaceLens won’t move protected or unknown items to Trash."
        case .symbolicLink:
            "SpaceLens won’t move symbolic links to Trash."
        case .incompleteFolder:
            "SpaceLens couldn’t inspect every item in this folder, so it won’t move the folder to Trash."
        case .identityUnavailable:
            "SpaceLens couldn’t verify this item’s filesystem identity."
        case .itemChanged:
            "The item changed after you selected it. Scan again before trying to move it to Trash."
        }
    }
}

actor TrashService {
    typealias TrashOperation = @Sendable (URL) throws -> Void

    private let trashOperation: TrashOperation

    init(trashOperation: @escaping TrashOperation = TrashService.moveUsingFileManager) {
        self.trashOperation = trashOperation
    }

    func prepare(item: ScanItem, authorizedScope: AuthorizedScanScope) throws -> TrashRequest {
        try validate(item: item, authorizedScope: authorizedScope)
        let classification = ItemClassification.classify(item)
        let assessment = SafetyAssessment.assess(item, classification: classification)
        guard assessment.level != .protectedOrUnknown else {
            throw TrashServiceError.protectedItem
        }

        return TrashRequest(
            item: item,
            authorizedScope: authorizedScope,
            expectedIdentity: try FileIdentity.read(from: item.url),
            assessment: assessment
        )
    }

    func moveToTrash(_ request: TrashRequest) throws -> TrashResult {
        try validate(item: request.item, authorizedScope: request.authorizedScope)
        let currentIdentity = try FileIdentity.read(from: request.item.url)
        guard currentIdentity == request.expectedIdentity else {
            throw TrashServiceError.itemChanged
        }

        let currentAssessment = SafetyAssessment.assess(
            request.item,
            classification: ItemClassification.classify(request.item)
        )
        guard currentAssessment.level != .protectedOrUnknown else {
            throw TrashServiceError.protectedItem
        }

        try trashOperation(request.item.url)
        return TrashResult(item: request.item)
    }

    private func validate(item: ScanItem, authorizedScope: AuthorizedScanScope) throws {
        guard authorizedScope.contains(item.url) else {
            throw TrashServiceError.outsideAuthorizedScope
        }
        guard item.kind != .symbolicLink else {
            throw TrashServiceError.symbolicLink
        }
        guard item.skippedItemCount == 0 else {
            throw TrashServiceError.incompleteFolder
        }
    }

    private static func moveUsingFileManager(_ url: URL) throws {
        var resultingURL: NSURL?
        try FileManager.default.trashItem(at: url, resultingItemURL: &resultingURL)
    }
}
