import AVFoundation
import Foundation

enum AudioMetadataReader {
    struct Info: Sendable {
        var title: String
        var artist: String?
        var album: String?
        var duration: TimeInterval?
        var artwork: Data?
    }

    static func read(from url: URL, filename: String) async -> Info {
        let fallback = URL(fileURLWithPath: filename).deletingPathExtension().lastPathComponent
        var info = Info(title: fallback.isEmpty ? filename : fallback, artist: nil, album: nil, duration: nil, artwork: nil)
        let asset = AVURLAsset(url: url)
        do {
            let duration = try await asset.load(.duration)
            if duration.isNumeric, !duration.isIndefinite {
                let seconds = duration.seconds
                if seconds.isFinite, seconds > 0 {
                    info.duration = seconds
                }
            }
            let items = try await asset.load(.commonMetadata)
            if let title = await metadataString(items, key: .commonKeyTitle) {
                info.title = title
            }
            info.artist = await metadataString(items, key: .commonKeyArtist)
            info.album = await metadataString(items, key: .commonKeyAlbumName)
            info.artwork = await metadataData(items, key: .commonKeyArtwork)
        } catch {
            return info
        }
        return info
    }

    private static func metadataString(_ items: [AVMetadataItem], key: AVMetadataKey) async -> String? {
        guard let item = items.first(where: { $0.commonKey == key }) else { return nil }
        let value = (try? await item.load(.stringValue)) ?? item.stringValue
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func metadataData(_ items: [AVMetadataItem], key: AVMetadataKey) async -> Data? {
        guard let item = items.first(where: { $0.commonKey == key }) else { return nil }
        return (try? await item.load(.dataValue)) ?? item.dataValue
    }
}
