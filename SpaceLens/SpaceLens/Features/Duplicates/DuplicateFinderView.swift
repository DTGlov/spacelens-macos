import AppKit
import QuickLook
import SwiftUI

struct DuplicateFinderView: View {
    @Bindable var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
        }
        .frame(minWidth: 720, idealWidth: 820, minHeight: 520, idealHeight: 640)
        .quickLookPreview($model.previewURL)
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Duplicate files")
                    .font(.title2.weight(.semibold))
                Text("Files are matched by size and SHA-256 content hash.")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if case .finished = model.duplicateScanState {
                Button("Scan again", systemImage: "arrow.clockwise", action: model.startDuplicateScan)
            }
            Button("Close", action: model.dismissDuplicateFinder)
                .keyboardShortcut(.cancelAction)
        }
        .padding(18)
    }

    @ViewBuilder
    private var content: some View {
        switch model.duplicateScanState {
        case .idle:
            ContentUnavailableView {
                Label("Ready to find duplicates", systemImage: "doc.on.doc")
            } description: {
                Text("SpaceLens reads file contents but never changes them during a duplicate scan.")
            } actions: {
                Button("Find duplicates", action: model.startDuplicateScan)
            }
        case .scanning(let progress):
            DuplicateProgressView(progress: progress, cancel: model.cancelDuplicateScan)
        case .finished(let groups):
            DuplicateResultsView(
                groups: groups,
                preview: model.previewDuplicate,
                reveal: model.revealDuplicate,
                requestMoveToTrash: model.requestMoveDuplicateToTrash
            )
        case .failed(let message):
            ContentUnavailableView {
                Label("Duplicate scan couldn’t be completed", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Try again", action: model.startDuplicateScan)
            }
        }
    }
}

private struct DuplicateProgressView: View {
    let progress: DuplicateScanProgress
    let cancel: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            ProgressView()
                .controlSize(.large)
                .accessibilityLabel(
                    progress.stage == .discovering
                        ? "Finding candidate files"
                        : "Comparing file contents"
                )
            Text(progress.stage == .discovering ? "Finding candidate files…" : "Comparing file contents…")
                .font(.title3.weight(.semibold))
            if progress.stage == .hashing {
                Text(
                    "\(progress.hashedFileCount.formatted()) of \(progress.candidateFileCount.formatted()) candidates compared"
                )
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            } else {
                Text("\(progress.discoveredFileCount.formatted()) eligible files found")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Text(progress.currentPath)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .lineLimit(2)
                .truncationMode(.middle)
                .frame(maxWidth: 480)
            Button("Cancel", action: cancel)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(30)
    }
}

private struct DuplicateResultsView: View {
    let groups: [DuplicateGroup]
    let preview: (DuplicateFile) -> Void
    let reveal: (DuplicateFile) -> Void
    let requestMoveToTrash: (DuplicateFile) -> Void

    private var potentialSpace: Int64 {
        groups.reduce(0) { $0 + $1.potentialSpace }
    }

    var body: some View {
        if groups.isEmpty {
            ContentUnavailableView {
                Label("No duplicate files found", systemImage: "checkmark.circle")
            } description: {
                Text("No files with matching content were found in this scan.")
            }
        } else {
            VStack(spacing: 0) {
                HStack(spacing: 20) {
                    Label("\(groups.count.formatted()) duplicate groups", systemImage: "square.stack.3d.up")
                    Label("Up to \(potentialSpace.formatted(.byteCount(style: .file)))", systemImage: "internaldrive")
                        .help("Potential space if all but one file in each group is removed.")
                    Spacer()
                    Text("Review every copy before removing anything.")
                        .foregroundStyle(.secondary)
                }
                .font(.callout)
                .padding(16)
                Divider()
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(groups) { group in
                            DuplicateGroupView(
                                group: group,
                                preview: preview,
                                reveal: reveal,
                                requestMoveToTrash: requestMoveToTrash
                            )
                        }
                    }
                    .padding(16)
                }
            }
        }
    }
}

private struct DuplicateGroupView: View {
    let group: DuplicateGroup
    let preview: (DuplicateFile) -> Void
    let reveal: (DuplicateFile) -> Void
    let requestMoveToTrash: (DuplicateFile) -> Void

    var body: some View {
        GroupBox {
            VStack(spacing: 0) {
                ForEach(Array(group.files.enumerated()), id: \.element.id) { index, file in
                    if index > 0 { Divider() }
                    DuplicateFileRow(
                        file: file,
                        preview: { preview(file) },
                        reveal: { reveal(file) },
                        requestMoveToTrash: { requestMoveToTrash(file) }
                    )
                }
            }
        } label: {
            HStack {
                Text("\(group.files.count) matching files")
                    .font(.headline)
                Spacer()
                Text("\(group.fileSize.formatted(.byteCount(style: .file))) each")
                Text("•")
                    .accessibilityHidden(true)
                Text("Up to \(group.potentialSpace.formatted(.byteCount(style: .file)))")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct DuplicateFileRow: View {
    let file: DuplicateFile
    let preview: () -> Void
    let reveal: () -> Void
    let requestMoveToTrash: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: file.url.path))
                .resizable()
                .frame(width: 32, height: 32)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(file.name)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .help(file.name)
                Text(file.url.deletingLastPathComponent().path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(file.url.path)
            }
            Spacer()
            if let modificationDate = file.modificationDate {
                Text(modificationDate, format: .dateTime.year().month().day())
                    .foregroundStyle(.secondary)
            }
            Button("Quick Look", systemImage: "eye", action: preview)
                .labelStyle(.iconOnly)
                .help("Quick Look")
            Button("Reveal in Finder", systemImage: "folder", action: reveal)
                .labelStyle(.iconOnly)
                .help("Reveal in Finder")
            Button(role: .destructive, action: requestMoveToTrash) {
                Label("Move to Trash", systemImage: "trash")
            }
            .labelStyle(.iconOnly)
            .help("Move to Trash…")
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 6)
    }
}
