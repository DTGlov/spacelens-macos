import AppKit
import QuickLook
import SwiftUI

struct ResultsView: View {
    @Bindable var model: AppModel

    var body: some View {
        let displayedItems = model.displayedItems
        HSplitView {
            VStack(alignment: .leading, spacing: 0) {
                navigationBar
                Divider()
                summary(displayedItemCount: displayedItems.count)
                insights
                if !model.excludedURLs.isEmpty {
                    exclusions
                }
                Divider()
                if displayedItems.isEmpty {
                    EmptyResultsView(
                        searchText: model.searchText,
                        hasActiveFilters: model.hasActiveFilters,
                        clearFilters: model.clearFilters
                    )
                } else {
                    treemap(items: displayedItems)
                    Divider()
                    ResultsTable(
                        items: displayedItems,
                        selection: $model.selection,
                        sortOrder: $model.sortOrder,
                        openSelectedFolder: model.openSelectedFolder
                    )
                }
            }
            .frame(
                minWidth: 540,
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .topLeading
            )

            InspectorView(
                item: model.selectedItem,
                canOpenFolder: model.selectedItem?.isFolder == true,
                canPreview: model.previewableSelectedItem != nil,
                canMoveToTrash: model.canMoveSelectedItemToTrash,
                openFolder: model.openSelectedFolder,
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

    private func treemap(items: [ScanItem]) -> some View {
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
                items: items,
                selection: $model.selection,
                open: model.openFolder
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .padding(14)
        .frame(height: 270)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func summary(displayedItemCount: Int) -> some View {
        HStack(spacing: 20) {
            Label(model.progress.discoveredSize.formatted(.byteCount(style: .file)), systemImage: "internaldrive")
            Label("\(model.progress.scannedItemCount.formatted()) items", systemImage: "doc.on.doc")
            if model.progress.skippedItemCount > 0 {
                Label("\(model.progress.skippedItemCount.formatted()) skipped", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                    .help("Some items could not be read or were outside the selected filesystem.")
            }
            if model.progress.excludedFolderCount > 0 {
                Label(
                    "\(model.progress.excludedFolderCount.formatted()) excluded",
                    systemImage: "folder.badge.minus"
                )
                .help("Excluded folders were not read or included in results.")
            }
            Spacer()
            Text("Showing \(displayedItemCount.formatted()) of \(model.items.count.formatted())")
                .foregroundStyle(.secondary)
        }
        .font(.callout)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var insights: some View {
        HStack(spacing: 10) {
            Text("Insights")
                .font(.headline)
            ForEach([AppModel.InsightFilter.largeFiles, .notModifiedInYear]) { insight in
                let summary = model.insightSummary(for: insight)
                InsightButton(
                    insight: insight,
                    summary: summary,
                    isSelected: model.insightFilter == insight
                ) {
                    model.insightFilter = model.insightFilter == insight ? .all : insight
                }
            }
            Button("Find duplicates", systemImage: "doc.on.doc", action: model.presentDuplicateFinder)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var exclusions: some View {
        HStack(spacing: 8) {
            Label("Excluded", systemImage: "folder.badge.minus")
                .font(.callout.weight(.semibold))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(model.excludedURLs.sorted(by: { $0.path < $1.path }), id: \.self) { url in
                        Text(url.lastPathComponent)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(Capsule())
                            .help(url.path)
                    }
                }
            }
            Button("Change exclusions…", action: model.editScanSetup)
                .controlSize(.small)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
    }
}

private struct InsightButton: View {
    let insight: AppModel.InsightFilter
    let summary: AppModel.InsightSummary
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: insight.systemImage)
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(insight.title)
                        .font(.callout.weight(.semibold))
                    Text(
                        "\(summary.itemCount.formatted()) files · \(summary.allocatedSize.formatted(.byteCount(style: .file)))"
                    )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(minWidth: 190, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(
                        isSelected
                            ? Color.accentColor.opacity(0.12)
                            : Color(nsColor: .controlBackgroundColor)
                    )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(
                        isSelected ? Color.accentColor : Color(nsColor: .separatorColor),
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            "\(insight.title), \(summary.itemCount) files, \(summary.allocatedSize.formatted(.byteCount(style: .file)))"
        )
        .accessibilityHint(isSelected ? "Shows all items" : "Filters the storage map and file list")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct ResultsTable: View {
    let items: [ScanItem]
    @Binding var selection: ScanItem.ID?
    @Binding var sortOrder: [KeyPathComparator<ScanItem>]
    let openSelectedFolder: () -> Void

    var body: some View {
        Table(items, selection: $selection, sortOrder: $sortOrder) {
            TableColumn("Name", value: \.name) { item in
                let classification = ItemClassification.classify(item)
                Label {
                    Text(item.name)
                } icon: {
                    Image(systemName: classification.category.systemImage)
                        .foregroundStyle(classification.category.color)
                }
                    .lineLimit(1)
                    .help(item.name)
            }
            TableColumn("Category") { item in
                Text(ItemClassification.classify(item).category.rawValue)
                    .foregroundStyle(.secondary)
            }
            .width(min: 90, ideal: 110)
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
        .onTapGesture(count: 2, perform: openSelectedFolder)
    }
}

private struct EmptyResultsView: View {
    let searchText: String
    let hasActiveFilters: Bool
    let clearFilters: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(
                hasActiveFilters ? "No matching items" : "This folder is empty",
                systemImage: hasActiveFilters ? "line.3.horizontal.decrease.circle" : "folder"
            )
        } description: {
            if !hasActiveFilters {
                Text("SpaceLens didn’t find any visible files or folders here.")
            } else if searchText.isEmpty {
                Text("No files or folders match the selected filters.")
            } else {
                Text("No files or folders match “\(searchText)”.")
            }
        } actions: {
            if hasActiveFilters {
                Button("Clear search and filters", action: clearFilters)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    let canOpenFolder: Bool
    let canPreview: Bool
    let canMoveToTrash: Bool
    let openFolder: () -> Void
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
                                .font(.title3.weight(.semibold))
                                .textSelection(.enabled)
                            Label(classification.category.rawValue, systemImage: classification.category.systemImage)
                                .font(.callout)
                                .foregroundStyle(classification.category.color)
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

                Section("Actions") {
                    Button("Open Folder", systemImage: "folder", action: openFolder)
                        .disabled(!canOpenFolder)
                        .keyboardShortcut(.downArrow, modifiers: [.command])
                    Button("Quick Look", systemImage: "eye", action: preview)
                        .disabled(!canPreview)
                        .keyboardShortcut(.space, modifiers: [])
                    Button("Reveal in Finder", action: reveal)
                        .keyboardShortcut(.return, modifiers: [.command])
                }

                Section("Removal") {
                    Button(role: .destructive, action: requestMoveToTrash) {
                        Label("Move to Trash", systemImage: "trash")
                    }
                    .disabled(!canMoveToTrash)
                    .keyboardShortcut(.delete, modifiers: [.command])
                    if !canMoveToTrash {
                        Text("Unavailable for protected or incompletely scanned items.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("You’ll be asked to confirm before anything moves.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
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
