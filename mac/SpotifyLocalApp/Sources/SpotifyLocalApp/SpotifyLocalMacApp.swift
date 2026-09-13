import AppKit
import SwiftUI

@main
struct SpotifyLocalMacApp: App {
    @State private var appState = AppState.live

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(appState)
                .task {
                    await appState.start()
                }
                .frame(width: 393, height: 852)
                .onAppear {
                    NSApp.activate(ignoringOtherApps: true)
                }
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 393, height: 852)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Add Music…") {
                    appState.presentImporter()
                }
                .keyboardShortcut("o", modifiers: [.command])
            }
        }
    }
}
