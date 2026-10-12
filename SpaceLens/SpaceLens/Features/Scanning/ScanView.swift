import SwiftUI

struct ScanView: View {
    let model: AppModel

    var body: some View {
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
        .background(Color.accentColor.opacity(0.035))
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

            HStack(spacing: 32) {
                ScanMetric(
                    value: model.progress.discoveredSize.formatted(.byteCount(style: .file)),
                    label: "Discovered"
                )
                ScanMetric(
                    value: model.progress.scannedItemCount.formatted(),
                    label: "Items inspected"
                )
            }

            VStack(alignment: .leading, spacing: 10) {
                ProgressView()
                    .controlSize(.small)
                Text(model.progress.currentPath.isEmpty ? "Preparing scan…" : model.progress.currentPath)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
            }

            Button("Cancel scan", role: .cancel) {
                model.cancelScan()
            }
            .keyboardShortcut(.cancelAction)
        }
        .frame(maxWidth: 460, alignment: .leading)
    }
}

private struct ScanMetric: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .semibold))
                .monospacedDigit()
            Text(label)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}
