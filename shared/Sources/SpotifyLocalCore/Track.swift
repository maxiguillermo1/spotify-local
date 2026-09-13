import Foundation

public struct Track: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: UUID
    public var title: String
    public var artist: String?
    public var album: String?
    public var artwork: ArtworkReference?
    public var duration: TimeInterval?
    public var size: Int64
    public var format: String
    public var filename: String
    public var addedAt: Date
    public var availability: TrackAvailability

    public init(
        id: UUID = UUID(),
        title: String,
        artist: String? = nil,
        album: String? = nil,
        artwork: ArtworkReference? = nil,
        duration: TimeInterval? = nil,
        size: Int64,
        format: String,
        filename: String,
        addedAt: Date,
        availability: TrackAvailability
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.artwork = artwork
        self.duration = duration
        self.size = size
        self.format = format
        self.filename = filename
        self.addedAt = addedAt
        self.availability = availability
    }

    public var artistDisplay: String {
        let trimmed = artist?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "Unknown Artist" : trimmed
    }
}
