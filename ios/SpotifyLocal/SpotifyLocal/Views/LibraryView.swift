import SwiftUI
#if canImport(SpotifyLocalCore)
import SpotifyLocalCore
#endif

struct LibraryView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState
        List {
            if appState.visibleTracks.isEmpty {
                if appState.searchText.isEmpty, appState.canImportMusic {
                    EmptyLibraryView(isBusy: appState.isImporting) {
                        appState.presentImporter()
                    }
                    .listRowSeparator(.hidden)
                } else {
                    ContentUnavailableView.search(text: appState.searchText)
                }
            } else {
                ForEach(appState.visibleTracks) { track in
                    NavigationLink(value: track) {
                        TrackRow(track: track, showsAlbum: true)
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Your Music")
        .appLargeNavigationTitle()
        .appNavigationBarHidden(false)
        .appSearchable(text: $appState.searchText)
        .toolbar {
            if appState.canImportMusic {
                ToolbarItem(placement: .primaryAction) {
                    AddMusicButton(compact: true, isBusy: appState.isImporting) {
                        appState.presentImporter()
                    }
                }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            if appState.searchText.isEmpty {
                HStack {
                    Text("\(appState.library.songCount) songs")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
        }
        .navigationDestination(for: Track.self) { track in
            TrackDetailView(trackID: track.id)
        }
    }
}

#if os(iOS)
#Preview {
    NavigationStack {
        LibraryView()
    }
    .environment(AppState.preview(.connected))
}
#endif
