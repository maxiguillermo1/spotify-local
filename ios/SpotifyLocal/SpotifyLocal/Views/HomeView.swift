import SwiftUI
#if canImport(SpotifyLocalCore)
import SpotifyLocalCore
#endif

struct HomeView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    librarySummary
                    recentlyAdded
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .background(Color.appBackground)
            .appNavigationBarHidden(true)
            .navigationDestination(for: Track.self) { track in
                TrackDetailView(trackID: track.id)
            }
        }
        .modifier(MusicImportModifier(appState: appState))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spotify Local")
                .font(.largeTitle.bold())
            ConnectionHeader(hostName: appState.hostName, status: appState.connection)
        }
        .padding(.top, 8)
    }

    private var librarySummary: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            NavigationLink {
                LibraryView()
            } label: {
                HStack(alignment: .firstTextBaseline) {
                    Text("Your Music")
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("\(appState.library.songCount)")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            .disabled(appState.connection == .unavailable && appState.library.tracks.isEmpty)
            .buttonStyle(.plain)

            if appState.canImportMusic {
                AddMusicButton(compact: true, isBusy: appState.isImporting) {
                    appState.presentImporter()
                }
            }
        }
    }

    @ViewBuilder
    private var recentlyAdded: some View {
        if appState.connection == .unavailable && appState.library.tracks.isEmpty {
            OfflineStateView()
        } else if appState.library.tracks.isEmpty {
            EmptyLibraryView(isBusy: appState.isImporting) {
                appState.presentImporter()
            }
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("Recently Added")
                    .font(.title3.weight(.semibold))
                    .padding(.top, 4)

                VStack(spacing: 0) {
                    ForEach(Array(appState.recentlyAdded.enumerated()), id: \.element.id) { index, track in
                        NavigationLink(value: track) {
                            TrackRow(track: track)
                        }
                        .buttonStyle(.plain)
                        if index < appState.recentlyAdded.count - 1 {
                            Divider().padding(.leading, 64)
                        }
                    }
                }
            }
        }
    }
}

#if os(iOS)
#Preview("Mac connected") {
    HomeView()
        .environment(AppState.preview(.connected))
}

#Preview("Mac offline") {
    HomeView()
        .environment(AppState.preview(.offline))
}

#Preview("Empty library") {
    HomeView()
        .environment(AppState.preview(.empty))
}

#Preview("Downloading") {
    HomeView()
        .environment(AppState.preview(.downloading))
}

#Preview("Complete") {
    HomeView()
        .environment(AppState.preview(.complete))
}

#Preview("Failed transfer") {
    HomeView()
        .environment(AppState.preview(.failed))
}

#Preview("Large library") {
    HomeView()
        .environment(AppState.preview(.large))
}

#Preview("Missing artwork") {
    HomeView()
        .environment(AppState.preview(.missingArtwork))
}
#endif
