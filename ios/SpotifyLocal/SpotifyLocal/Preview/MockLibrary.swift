import Foundation
#if canImport(SpotifyLocalCore)
import SpotifyLocalCore
#endif

enum MockLibrary {
    static let nightsID = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!
    static let ferrariID = UUID(uuidString: "22222222-2222-4222-8222-222222222222")!
    static let selfControlID = UUID(uuidString: "33333333-3333-4333-8333-333333333333")!
    static let demoID = UUID(uuidString: "44444444-4444-4444-8444-444444444444")!

    static func library(for scenario: MockScenario) -> MusicLibrary {
        switch scenario {
        case .empty:
            return MusicLibrary(tracks: [], generatedAt: Date(timeIntervalSince1970: 1_720_000_000))
        case .offline:
            return .empty
        case .missingArtwork:
            return MusicLibrary(tracks: [demo(availability: .mac, artwork: .missing)])
        case .complete:
            return MusicLibrary(tracks: sample(iphoneIDs: [nightsID, ferrariID, selfControlID, demoID]))
        case .downloading:
            return MusicLibrary(tracks: sample(downloading: nightsID))
        case .failed:
            return MusicLibrary(tracks: sample(attention: selfControlID))
        case .large:
            return MusicLibrary(tracks: sample() + extras())
        case .connected:
            return MusicLibrary(tracks: sample())
        }
    }

    static func sample(
        iphoneIDs: Set<UUID> = [ferrariID],
        downloading: UUID? = nil,
        attention: UUID? = nil
    ) -> [Track] {
        let blonde = ArtworkReference(systemSymbol: "waveform", backgroundHex: "C4A574", accentHex: "2C1810")
        let nights = Track(
            id: nightsID,
            title: "Nights",
            artist: "Frank Ocean",
            album: "Blonde",
            artwork: blonde,
            duration: 307,
            size: 9_841_220,
            format: "mp3",
            filename: "Nights.mp3",
            addedAt: Date(timeIntervalSince1970: 1_720_080_000),
            availability: availability(for: nightsID, iphoneIDs: iphoneIDs, downloading: downloading, attention: attention)
        )
        let ferrari = Track(
            id: ferrariID,
            title: "White Ferrari",
            artist: "Frank Ocean",
            album: "Blonde",
            artwork: blonde,
            duration: 248,
            size: 7_102_441,
            format: "m4a",
            filename: "White Ferrari.m4a",
            addedAt: Date(timeIntervalSince1970: 1_720_070_000),
            availability: availability(for: ferrariID, iphoneIDs: iphoneIDs, downloading: downloading, attention: attention)
        )
        let selfControl = Track(
            id: selfControlID,
            title: "Self Control",
            artist: "Frank Ocean",
            album: "Blonde",
            artwork: blonde,
            duration: 249,
            size: 8_221_004,
            format: "mp3",
            filename: "Self Control.mp3",
            addedAt: Date(timeIntervalSince1970: 1_720_060_000),
            availability: availability(for: selfControlID, iphoneIDs: iphoneIDs, downloading: downloading, attention: attention)
        )
        let demoTrack = demo(
            availability: availability(for: demoID, iphoneIDs: iphoneIDs, downloading: downloading, attention: attention)
        )
        return [nights, ferrari, selfControl, demoTrack]
    }

    static func demo(availability: TrackAvailability, artwork: ArtworkReference? = nil) -> Track {
        Track(
            id: demoID,
            title: "Demo",
            artist: nil,
            album: nil,
            artwork: artwork,
            duration: 94,
            size: 1_540_220,
            format: "mp3",
            filename: "Demo.mp3",
            addedAt: Date(timeIntervalSince1970: 1_720_050_000),
            availability: availability
        )
    }

    private static func extras() -> [Track] {
        let titles = [
            "Pink + White", "Ivy", "Solo", "Skyline To", "Good Guy",
            "Seigfried", "Godspeed", "Futura Free", "Nikes", "Pretty Sweet",
        ]
        return titles.enumerated().map { index, title in
            Track(
                id: UUID(uuidString: String(format: "55555555-5555-4555-8555-%012d", index + 1))!,
                title: title,
                artist: "Frank Ocean",
                album: "Blonde",
                artwork: ArtworkReference(systemSymbol: "waveform", backgroundHex: "8AA39B", accentHex: "14201C"),
                duration: 200 + Double(index * 12),
                size: 4_000_000 + Int64(index * 10_000),
                format: "mp3",
                filename: "\(title).mp3",
                addedAt: Date(timeIntervalSince1970: 1_720_000_000 - Double(index * 800)),
                availability: index.isMultiple(of: 3) ? .iphone : .mac
            )
        }
    }

    private static func availability(
        for id: UUID,
        iphoneIDs: Set<UUID>,
        downloading: UUID?,
        attention: UUID?
    ) -> TrackAvailability {
        if id == attention { return .attention }
        if id == downloading { return .downloading(progress: 0.42) }
        if iphoneIDs.contains(id) { return .iphone }
        return .mac
    }
}
