import AppKit
import QuickLook
import SwiftUI

struct ResultsView: View {
    @Bindable var model: AppModel

    var body: some View {
        HSplitView {
            VStack(alignment: .leading, spacing: 0) {
                navigationBar
                Divider()
                summary
                Divider()
                treemap
                Divider()
                ResultsTable(model: model)
            }
            .frame(
                minWidth: 540,
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .topLeading
            )

            InspectorView(
                item: model.selectedItem,
                canPreview: model.previewableSelectedItem != nil,
                canMoveToTrash: model.canMoveSelectedItemToTrash,
                preview: model.previewSelectedItem,
                reveal: model.revealSelectedItem,
                requestMoveToTrash: model.requestMoveSelectedItemToTrash
            )
                .frame(
                    minWidth: 280,
                    idealWidth: 340,
                    maxWidth: 440,
                    maxHeight: .infinity,
                    alignment: .topLeading
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .navigationTitle(model.rootURL?.lastPathComponent ?? "Scan Results")
        .searchable(text: $model.searchText, prompt: "Search this folder")
        .quickLookPreview($model.previewURL)
    }

    private var navigationBar: some View {
        HStack(spacing: 8) {
            Button("Back", systemImage: "chevron.backward", action: model.goBack)
                .labelStyle(.iconOnly)
                .disabled(!model.canGoBack)
                .keyboardShortcut("[", modifiers: .command)
                .help("Back")
            Button("Up", systemImage: "arrow.up", action: model.goUp)
                .labelStyle(.iconOnly)
                .disabled(!model.canGoUp)
                .keyboardShortcut(.upArrow, modifiers: .command)
                .help("Go to enclosing folder")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(model.breadcrumbs, id: \.self) { url in
                        if url != model.breadcrumbs.first {
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .accessibilityHidden(true)
                        }
                        Button(url.lastPathComponent) {
                            model.navigate(to: url)
                        }
                        .buttonStyle(.plain)
                        .disabled(url == model.rootURL)
                    }
                }
            }
            .frame(minWidth: 80, maxWidth: .infinity)
            .layoutPriority(1)

            Picker("Show", selection: $model.itemFilter) {
                ForEach(AppModel.ItemFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .labelsHidden()
            .frame(width: 110)
            Picker("Minimum size", selection: $model.minimumSizeFilter) {
                ForEach(AppModel.MinimumSizeFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .labelsHidden()
            .frame(width: 105)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var treemap: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Storage map")
                    .font(.headline)
                Spacer()
                Text("Larger blocks use more space")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            TreemapView(
                items: model.displayedItems,
                selection: $model.selection,
                open: model.openFolder
            )
        }
        .padding(12)
        .frame(height: 250)
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
        .onTapGesture(count: 2, perform: model.openSelectedFolder)
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
    let canPreview: Bool
    let canMoveToTrash: Bool
    let preview: () -> Void
    let reveal: () -> Void
    let requestMoveToTrash: () -> Void

    var body: some View {
        if let item {
            let classification = ItemClassification.classify(item)
            let safetyAssessment = SafetyAssessment.assess(item, classification: classification)
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
                    LabeledContent("Category", value: classification.category.rawValue)
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

                Section("Deletion guidance") {
                    Label(safetyAssessment.level.rawValue, systemImage: safetyAssessment.systemImage)
                        .font(.headline)
                    Text(safetyAssessment.reason)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("This is guidance, not a guarantee. SpaceLens never removes files automatically.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Section {
                    Button("Quick Look", systemImage: "eye", action: preview)
                        .disabled(!canPreview)
                        .keyboardShortcut(.space, modifiers: [])
                    Button("Reveal in Finder", action: reveal)
                        .keyboardShortcut(.return, modifiers: [.command])
                    Button(role: .destructive, action: requestMoveToTrash) {
                        Label("Move to Trash", systemImage: "trash")
                    }
                    .disabled(!canMoveToTrash)
                    .keyboardShortcut(.delete, modifiers: [.command])
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

private extension SafetyAssessment {
    var systemImage: String {
        switch level {
        case .knownReproducible: "arrow.trianglehead.2.clockwise.rotate.90"
        case .reviewCarefully: "exclamationmark.triangle"
        case .protectedOrUnknown: "lock.shield"
        }
    }
}
