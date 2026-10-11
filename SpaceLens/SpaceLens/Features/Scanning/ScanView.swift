import SwiftUI

struct ScanView: View {
    let model: AppModel

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: "externaldrive.fill.badge.magnifyingglass")
                .font(.system(size: 48))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.tint)

            VStack(spacing: 8) {
                Text("Scanning \(model.rootURL?.lastPathComponent ?? "folder")")
                    .font(.title2.weight(.semibold))
                Text(ByteCountFormatter.string(fromByteCount: model.progress.discoveredSize, countStyle: .file))
                    .font(.system(.title3, design: .rounded, weight: .medium))
                    .contentTransition(.numericText())
                Text("\(model.progress.scannedItemCount.formatted()) items inspected")
                    .foregroundStyle(.secondary)
            }

            ProgressView()
                .controlSize(.small)

            Text(model.progress.currentPath)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: 520)

            Button("Cancel Scan", role: .cancel) {
                model.cancelScan()
            }
            Spacer()
        }
        .padding(40)
    }
}
