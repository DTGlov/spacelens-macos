import AppKit
import SwiftUI

struct ResultsView: View {
    @Bindable var model: AppModel

    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 0) {
                summary
                Divider()
                ResultsTable(model: model)
            }
            .navigationSplitViewColumnWidth(min: 500, ideal: 620)
        } detail: {
            InspectorView(item: model.selectedItem, reveal: model.revealSelectedItem)
        }
        .navigationTitle(model.rootURL?.lastPathComponent ?? "Scan Results")
    }

    private var summary: some View {
        HStack(spacing: 20) {
            Label(model.progress.discoveredSize.formatted(.byteCount(style: .file)), systemImage: "internaldrive")
            Label("\(model.progress.scannedItemCount.formatted()) items", systemImage: "doc.on.doc")
            if model.progress.skippedItemCount > 0 {
                Label("\(model.progress.skippedItemCount.formatted()) skipped", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                    .help("Some items could not be read or were outside the selected filesystem.")
            }
            Spacer()
            Text("Largest 100 items")
                .foregroundStyle(.secondary)
        }
        .font(.callout)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct ResultsTable: View {
    @Bindable var model: AppModel

    var body: some View {
        Table(model.displayedItems, selection: $model.selection, sortOrder: $model.sortOrder) {
            TableColumn("Name", value: \.name) { item in
                Label(item.name, systemImage: item.isFolder ? "folder.fill" : "doc.fill")
                    .lineLimit(1)
            }
            TableColumn("Size", value: \.allocatedSize) { item in
                Text(item.allocatedSize, format: .byteCount(style: .file))
                    .monospacedDigit()
            }
            .width(min: 100, ideal: 120)
            TableColumn("Modified") { item in
                ModificationDateText(date: item.modificationDate)
            }
            .width(min: 105, ideal: 125)
        }
    }
}

private struct ModificationDateText: View {
    let date: Date?

    var body: some View {
        if let date {
            Text(date, format: .dateTime.year().month().day())
        } else {
            Text("—")
                .foregroundStyle(.secondary)
        }
    }
}

private struct InspectorView: View {
    let item: ScanItem?
    let reveal: () -> Void

    var body: some View {
        if let item {
            Form {
                Section {
                    HStack(spacing: 14) {
                        Image(nsImage: NSWorkspace.shared.icon(forFile: item.url.path))
                            .resizable()
                            .frame(width: 48, height: 48)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.name)
                                .font(.headline)
                                .textSelection(.enabled)
                            Text(item.kind.rawValue.capitalized)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Details") {
                    LabeledContent("Size", value: item.allocatedSize.formatted(.byteCount(style: .file)))
                    LabeledContent("Logical size", value: item.logicalSize.formatted(.byteCount(style: .file)))
                    if let modificationDate = item.modificationDate {
                        LabeledContent("Modified") {
                            Text(modificationDate, format: .dateTime.year().month().day().hour().minute())
                        }
                    }
                    LabeledContent("Location") {
                        Text(item.url.deletingLastPathComponent().path)
                            .lineLimit(2)
                            .truncationMode(.middle)
                            .textSelection(.enabled)
                    }
                }

                Section {
                    Button("Reveal in Finder", action: reveal)
                        .keyboardShortcut(.return, modifiers: [.command])
                }
            }
            .formStyle(.grouped)
            .padding(.top, 8)
        } else {
            ContentUnavailableView(
                "Select an item",
                systemImage: "sidebar.right",
                description: Text("Choose a file or folder to inspect it.")
            )
        }
    }
}
