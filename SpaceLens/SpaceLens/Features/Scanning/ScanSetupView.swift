import SwiftUI

struct ScanSetupView: View {
    @Bindable var model: AppModel

    private var setup: AppModel.ScanSetup? { model.scanSetup }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 5) {
                Text(setup?.kind.setupTitle ?? "Set up this scan")
                    .font(.title2.weight(.semibold))
                Text(setupDescription)
                    .foregroundStyle(.secondary)
            }

            if let setup {
                GroupBox("Scan folder") {
                    Label(setup.rootURL.path, systemImage: "folder")
                        .lineLimit(2)
                        .truncationMode(.middle)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Excluded folders")
                                .font(.headline)
                            Text("Excluded folders are not scanned or checked for duplicates.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button(
                            "Add folders…",
                            systemImage: "folder.badge.minus",
                            action: model.chooseExcludedFolders
                        )
                    }

                    if setup.excludedURLs.isEmpty {
                        Text("No folders excluded")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 70)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(setup.excludedURLs.sorted(by: { $0.path < $1.path }), id: \.self) { url in
                                    HStack(spacing: 10) {
                                        Image(systemName: "folder")
                                            .foregroundStyle(.secondary)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(url.lastPathComponent)
                                                .fontWeight(.medium)
                                            Text(url.path)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                                .truncationMode(.middle)
                                        }
                                        Spacer()
                                        Button("Remove \(url.lastPathComponent)", systemImage: "xmark") {
                                            model.removeExcludedFolder(url)
                                        }
                                        .labelStyle(.iconOnly)
                                        .help("Remove exclusion")
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    Divider()
                                }
                            }
                        }
                        .frame(maxHeight: 190)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
            }

            HStack {
                Text("Exclusions apply only to this scan session.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Cancel", action: model.cancelScanSetup)
                    .keyboardShortcut(.cancelAction)
                Button(setup?.kind.startButtonTitle ?? "Scan folder", action: model.startConfiguredScan)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(22)
        .frame(minWidth: 620, idealWidth: 620, minHeight: 430)
        .alert(item: $model.scanSetupAlert) { alert in
            Alert(
                title: Text("Folder couldn’t be excluded"),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var setupDescription: String {
        switch setup?.kind {
        case .deep:
            "SpaceLens will inspect this folder deeply. Exclude anything you want it to leave unread."
        case .folder, nil:
            "Choose any subfolders SpaceLens should leave unread."
        }
    }
}
