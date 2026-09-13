import SwiftUI
#if canImport(SpotifyLocalCore)
import SpotifyLocalCore
#endif

struct TrackDetailView: View {
    @Environment(AppState.self) private var appState
    let trackID: UUID

    var body: some View {
        Group {
            if let track = appState.track(id: trackID) {
                content(track)
            } else {
                ContentUnavailableView("Song unavailable", systemImage: "music.note")
            }
        }
        .appInlineNavigationTitle()
        .appNavigationBarHidden(false)
    }

    @ViewBuilder
    private func content(_ track: Track) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                ArtworkView(artwork: track.artwork, size: 240)
                    .padding(.top, 24)

                VStack(spacing: 6) {
                    Text(track.title)
                        .font(.title.bold())
                        .multilineTextAlignment(.center)
                    Text(track.artistDisplay)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    if let album = track.album, !album.isEmpty {
                        Text(album)
                            .font(.body)
                            .foregroundStyle(.tertiary)
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 24)

                statusSection(track)
                    .padding(.top, 12)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 40)
        }
        .background(Color.appBackground)
    }

    @ViewBuilder
    private func statusSection(_ track: Track) -> some View {
        switch track.availability {
        case .mac:
            VStack(spacing: 16) {
                Text("Available on Mac")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button {
                    Task { await appState.download(track) }
                } label: {
                    Text("Download to iPhone")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(.primary)
                .foregroundStyle(Color.appBackground)
                .padding(.horizontal, 24)
            }
        case .downloading(let progress):
            VStack(spacing: 12) {
                ProgressView(value: progress)
                    .tint(StatusGreen.ready)
                    .padding(.horizontal, 32)
                Text("\(Int((progress * 100).rounded()))%")
                    .font(.headline.monospacedDigit())
                Text("Downloading from MacBook")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        case .iphone:
            HStack(spacing: 8) {
                Image(systemName: "checkmark")
                    .font(.headline.weight(.bold))
                Text("On iPhone")
                    .font(.headline)
            }
            .foregroundStyle(StatusGreen.ready)
        case .attention:
            VStack(spacing: 16) {
                Text(appState.lastError ?? "Needs attention")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                Button {
                    Task { await appState.download(track) }
                } label: {
                    Text("Try again")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(.primary)
                .foregroundStyle(Color.appBackground)
                .padding(.horizontal, 24)
            }
        }
    }
}

#if os(iOS)
#Preview("On Mac") {
    NavigationStack {
        TrackDetailView(trackID: MockLibrary.nightsID)
    }
    .environment(AppState.preview(.connected))
}

#Preview("Downloading") {
    NavigationStack {
        TrackDetailView(trackID: MockLibrary.nightsID)
    }
    .environment(AppState.preview(.downloading))
}

#Preview("On iPhone") {
    NavigationStack {
        TrackDetailView(trackID: MockLibrary.ferrariID)
    }
    .environment(AppState.preview(.complete))
}
#endif
