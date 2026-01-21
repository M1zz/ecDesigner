import SwiftUI

@main
struct ecDesignerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Exploratory Cycle") {
                    // 새 창 열기
                }
                .keyboardShortcut("n", modifiers: .command)
            }

            CommandGroup(after: .newItem) {
                Button("Open...") {
                    // 파일 열기
                }
                .keyboardShortcut("o", modifiers: .command)

                Button("Save") {
                    // 저장
                }
                .keyboardShortcut("s", modifiers: .command)
            }
        }
    }
}
