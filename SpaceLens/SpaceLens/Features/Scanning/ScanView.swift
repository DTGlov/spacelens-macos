import SwiftUI

struct ScanView: View {
    let model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            ScanBackdrop()

            GeometryReader { proxy in
                ScrollView {
                    Group {
                        if proxy.size.width >= 960 {
                            HStack(spacing: 56) {
                                scanDetails
                                StorageMapArtwork(mode: .scanning)
                                    .frame(maxWidth: 460)
                            }
                        } else {
                            VStack(spacing: 40) {
                                scanDetails
                                StorageMapArtwork(mode: .scanning)
                                    .frame(maxWidth: 560)
                            }
                        }
                    }
                    .frame(maxWidth: 1_040)
                    .padding(.horizontal, 50)
                    .padding(.vertical, 56)
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .center)
                }
            }
        }
    }

    private var scanDetails: some View {
        VStack(alignment: .leading, spacing: 28) {
            Label("Scanning in progress", systemImage: "externaldrive.fill.badge.magnifyingglass")
                .font(.headline)
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 10) {
                Text(model.rootURL?.lastPathComponent ?? "Selected folder")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .lineLimit(2)
                Text("SpaceLens is measuring files without opening or changing their contents.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                ScanMetric(
                    value: model.progress.discoveredSize.formatted(.byteCount(style: .file)),
                    label: "Space mapped",
                    systemImage: "internaldrive"
                )
                ScanMetric(
                    value: model.progress.scannedItemCount.formatted(),
                    label: "Items inspected",
                    systemImage: "doc.on.doc"
                )
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(scanStatus)
                        .font(.callout.weight(.medium))
                        .lineLimit(1)
                    Spacer()
                    Label("Live", systemImage: "circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tint)
                }

                ScanActivityTrack(reduceMotion: reduceMotion)

                Text(model.progress.currentPath.isEmpty ? "Preparing the storage map…" : model.progress.currentPath)
                    .font(.caption.monospaced())
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
            }
            .padding(16)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(.primary.opacity(0.07))
            }

            Button("Cancel scan", role: .cancel) {
                model.cancelScan()
            }
            .buttonStyle(.bordered)
            .keyboardShortcut(.cancelAction)
        }
        .frame(maxWidth: 460, alignment: .leading)
    }

    private var scanStatus: String {
        guard !model.progress.currentPath.isEmpty else { return "Preparing scan" }
        let currentURL = URL(fileURLWithPath: model.progress.currentPath)
        let folderName = currentURL.deletingLastPathComponent().lastPathComponent
        return folderName.isEmpty ? "Mapping storage" : "Mapping \(folderName)"
    }
}

private struct ScanBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)

            LinearGradient(
                colors: [
                    Color.indigo.opacity(colorScheme == .dark ? 0.18 : 0.11),
                    Color.blue.opacity(colorScheme == .dark ? 0.10 : 0.07),
                    Color.teal.opacity(colorScheme == .dark ? 0.16 : 0.10),
                ],
                startPoint: .top,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [Color.cyan.opacity(colorScheme == .dark ? 0.14 : 0.18), .clear],
                center: .leading,
                startRadius: 30,
                endRadius: 620
            )

            RadialGradient(
                colors: [Color.purple.opacity(colorScheme == .dark ? 0.15 : 0.10), .clear],
                center: .bottomTrailing,
                startRadius: 20,
                endRadius: 560
            )
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

private struct ScanMetric: View {
    let value: String
    let label: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Image(systemName: systemImage)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.tint)
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .semibold))
                .monospacedDigit()
            Text(label)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.primary.opacity(0.07))
        }
        .accessibilityElement(children: .combine)
    }
}

private struct ScanActivityTrack: View {
    let reduceMotion: Bool

    var body: some View {
        GeometryReader { proxy in
            let trackWidth = proxy.size.width

            Capsule()
                .fill(.primary.opacity(0.08))
                .overlay(alignment: .leading) {
                    if reduceMotion {
                        LinearGradient(
                            colors: [.blue, .cyan, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: trackWidth * 0.42)
                        .clipShape(Capsule())
                    } else {
                        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                            let cycle = timeline.date.timeIntervalSinceReferenceDate
                                .truncatingRemainder(dividingBy: 2.4) / 2.4
                            let highlightWidth = max(trackWidth * 0.34, 90)

                            LinearGradient(
                                colors: [.clear, .blue, .cyan, .purple, .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: highlightWidth)
                            .offset(x: (trackWidth + highlightWidth) * cycle - highlightWidth)
                        }
                        .clipShape(Capsule())
                    }
                }
                .overlay {
                    Capsule()
                        .strokeBorder(.white.opacity(0.10))
                }
        }
        .frame(height: 8)
        .accessibilityElement()
        .accessibilityLabel("Scan in progress")
        .accessibilityValue("SpaceLens is mapping the selected folder")
    }
}
