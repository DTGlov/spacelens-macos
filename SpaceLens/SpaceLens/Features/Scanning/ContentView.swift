import SwiftUI

struct ContentView: View {
    @Bindable var model: AppModel

    var body: some View {
        Group {
            switch model.phase {
            case .welcome:
                WelcomeView(chooseFolder: model.chooseFolder)
            case .scanning:
                ScanView(model: model)
            case .results:
                ResultsView(model: model)
            case .failed(let message):
                ErrorView(message: message, chooseFolder: model.chooseFolder)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Choose Folder", systemImage: "folder.badge.plus") {
                    model.chooseFolder()
                }
            }
        }
        .alert(item: $model.trashAlert) { alert in
            switch alert.kind {
            case .confirmation(let request):
                Alert(
                    title: Text("Move “\(request.item.name)” to Trash?"),
                    message: Text(request.confirmationMessage),
                    primaryButton: .destructive(Text("Move to Trash")) {
                        model.confirmMoveToTrash(request)
                    },
                    secondaryButton: .cancel()
                )
            case .message(let title, let message):
                Alert(
                    title: Text(title),
                    message: Text(message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .sheet(isPresented: $model.isDuplicateFinderPresented, onDismiss: model.cancelDuplicateScan) {
            DuplicateFinderView(model: model)
        }
        .sheet(item: $model.scanSetup) { _ in
            ScanSetupView(model: model)
        }
    }
}

private extension TrashRequest {
    var confirmationMessage: String {
        "\(item.allocatedSize.formatted(.byteCount(style: .file))) • \(assessment.level.rawValue)\n\n\(item.url.path)\n\nSpace is reclaimed only after Trash is emptied."
    }
}

private struct ErrorView: View {
    let message: String
    let chooseFolder: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Scan couldn’t be completed", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Choose Another Folder…", action: chooseFolder)
        }
    }
}
