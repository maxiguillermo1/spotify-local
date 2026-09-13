import SwiftUI
#if canImport(SpotifyLocalCore)
import SpotifyLocalCore
#endif

struct TrackRow: View {
    let track: Track
    var showsAlbum: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            ArtworkView(artwork: track.artwork, size: 52)

            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(track.artistDisplay)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if showsAlbum {
                    if let album = track.album?.trimmingCharacters(in: .whitespacesAndNewlines), !album.isEmpty {
                        Text(album)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                } else {
                    Text(track.availability.label)
                        .font(.footnote)
                        .foregroundStyle(statusColor)
                }
            }

            Spacer(minLength: 8)

            statusGlyph
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(track.title), \(track.artistDisplay), \(track.availability.label)")
    }

    private var statusColor: Color {
        switch track.availability {
        case .iphone:
            StatusGreen.ready
        case .downloading:
            .secondary
        case .attention:
            .orange
        case .mac:
            .secondary
        }
    }

    @ViewBuilder
    private var statusGlyph: some View {
        switch track.availability {
        case .mac:
            Image(systemName: "arrow.down")
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
        case .downloading(let progress):
            ProgressView(value: progress)
                .controlSize(.small)
                .frame(width: 22, height: 22)
        case .iphone:
            Image(systemName: "checkmark")
                .font(.body.weight(.semibold))
                .foregroundStyle(StatusGreen.ready)
        case .attention:
            Image(systemName: "exclamationmark")
                .font(.body.weight(.bold))
                .foregroundStyle(.orange)
        }
    }
}

#if os(iOS)
#Preview {
    List {
        TrackRow(track: MockLibrary.sample()[0])
        TrackRow(track: MockLibrary.sample()[1])
        TrackRow(track: MockLibrary.sample(downloading: MockLibrary.nightsID)[0])
        TrackRow(track: MockLibrary.sample(attention: MockLibrary.selfControlID)[2])
    }
    .listStyle(.plain)
}
#endif
