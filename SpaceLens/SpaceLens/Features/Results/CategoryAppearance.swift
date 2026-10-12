import SwiftUI

extension ItemClassification.Category {
    var systemImage: String {
        switch self {
        case .folder: "folder.fill"
        case .application: "app.fill"
        case .archive: "archivebox.fill"
        case .video: "film.fill"
        case .audio: "waveform"
        case .image: "photo.fill"
        case .document: "doc.text.fill"
        case .developer: "chevron.left.forwardslash.chevron.right"
        case .other: "doc.fill"
        }
    }

    var color: Color {
        switch self {
        case .folder: .blue
        case .application: .indigo
        case .archive: .purple
        case .video: .pink
        case .audio: .orange
        case .image: .teal
        case .document: .cyan
        case .developer: .mint
        case .other: .gray
        }
    }
}
