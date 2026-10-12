import SwiftUI

struct StorageMapArtwork: View {
    enum Mode {
        case welcome
        case scanning
    }

    let mode: Mode

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Storage overview", systemImage: "internaldrive")
                    .font(.headline)
                Spacer()
                Text(mode == .welcome ? "512 GB" : "Discovering…")
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 6) {
                VStack(spacing: 6) {
                    StorageArtworkTile(
                        title: mode == .welcome ? "Videos" : "Scanning",
                        detail: mode == .welcome ? "186 GB" : "Large files",
                        systemImage: mode == .welcome ? "film.fill" : "magnifyingglass",
                        color: .blue
                    )
                    HStack(spacing: 6) {
                        StorageArtworkTile(
                            title: "Apps",
                            detail: mode == .welcome ? "74 GB" : "Inspecting",
                            systemImage: "app.fill",
                            color: .indigo
                        )
                        StorageArtworkTile(
                            title: "Photos",
                            detail: mode == .welcome ? "52 GB" : "Inspecting",
                            systemImage: "photo.fill",
                            color: .teal
                        )
                    }
                    .frame(height: 94)
                }

                VStack(spacing: 6) {
                    StorageArtworkTile(
                        title: "Downloads",
                        detail: mode == .welcome ? "96 GB" : "Inspecting",
                        systemImage: "arrow.down.circle.fill",
                        color: .purple
                    )
                    .frame(height: 112)
                    StorageArtworkTile(
                        title: "Documents",
                        detail: mode == .welcome ? "38 GB" : "Inspecting",
                        systemImage: "doc.fill",
                        color: .mint
                    )
                    StorageArtworkTile(
                        title: "Other",
                        detail: mode == .welcome ? "66 GB" : "Inspecting",
                        systemImage: "square.grid.2x2.fill",
                        color: .gray
                    )
                    .frame(height: 54)
                }
                .frame(width: 138)
            }
            .frame(height: 250)

            HStack(spacing: 8) {
                Image(systemName: "square.fill")
                    .foregroundStyle(.blue)
                Text("Larger blocks use more space")
                Spacer()
                Text("Private and on-device")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.primary.opacity(0.09))
        }
        .shadow(color: .black.opacity(0.08), radius: 18, y: 8)
        .accessibilityHidden(true)
    }
}

private struct StorageArtworkTile: View {
    let title: String
    let detail: String
    let systemImage: String
    let color: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.gradient)

                if proxy.size.width >= 90, proxy.size.height >= 52 {
                    VStack(alignment: .leading, spacing: 4) {
                        Label(title, systemImage: systemImage)
                            .font(.callout.weight(.semibold))
                            .lineLimit(1)
                        Text(detail)
                            .font(.caption.monospacedDigit())
                            .opacity(0.85)
                    }
                    .foregroundStyle(.white)
                    .padding(10)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(.white.opacity(0.16))
            }
        }
    }
}
