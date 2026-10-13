import Foundation

struct VolumeCapacity: Equatable, Sendable {
    let totalBytes: Int64

    init?(totalBytes: Int64) {
        guard totalBytes > 0 else { return nil }
        self.totalBytes = totalBytes
    }

    func folderShare(for allocatedBytes: Int64) -> Double {
        min(max(Double(allocatedBytes) / Double(totalBytes), 0), 1)
    }

    static func load(containing url: URL) -> VolumeCapacity? {
        guard let values = try? url.resourceValues(forKeys: [.volumeTotalCapacityKey]),
              let totalCapacity = values.volumeTotalCapacity else {
            return nil
        }

        return VolumeCapacity(totalBytes: Int64(totalCapacity))
    }
}
