import SwiftUI

@main
struct SpotifyLocalApp: App {
    @State private var appState = AppState.live

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(appState)
                .task {
                    await appState.start()
                }
        }
    }
}
