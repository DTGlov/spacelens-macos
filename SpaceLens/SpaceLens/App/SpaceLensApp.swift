import SwiftUI

@main
struct SpaceLensApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
                .frame(
                    minWidth: 880,
                    maxWidth: .infinity,
                    minHeight: 560,
                    maxHeight: .infinity
                )
        }
        .defaultSize(width: 1_100, height: 720)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Choose Folder…") {
                    model.chooseFolder()
                }
                .keyboardShortcut("o")
            }
        }
    }
}
