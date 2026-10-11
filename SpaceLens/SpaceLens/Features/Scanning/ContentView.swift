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
    }
}

private struct WelcomeView: View {
    let chooseFolder: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("See what is using your storage", systemImage: "internaldrive")
        } description: {
            Text("Choose a folder to find its largest files and folders. SpaceLens won’t modify anything.")
        } actions: {
            Button("Choose a Folder…", action: chooseFolder)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
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
