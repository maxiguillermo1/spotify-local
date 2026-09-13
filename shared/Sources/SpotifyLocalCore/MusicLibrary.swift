import Foundation

public struct MusicLibrary: Codable, Equatable, Sendable {
    public var tracks: [Track]
    public var generatedAt: Date

    public init(tracks: [Track] = [], generatedAt: Date = Date()) {
        self.tracks = tracks
        self.generatedAt = generatedAt
    }

    public static let empty = MusicLibrary(tracks: [], generatedAt: Date(timeIntervalSince1970: 0))

    public var songCount: Int { tracks.count }

    public var recentlyAdded: [Track] {
        tracks.sorted { $0.addedAt > $1.addedAt }
    }

    public func filtered(search: String) -> [Track] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return recentlyAdded }
        return tracks.filter { $0.matches(search: query) }
            .sorted { $0.addedAt > $1.addedAt }
    }
}

public extension Track {
    func matches(search: String) -> Bool {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return true }
        let fields = [title, artist ?? "", album ?? "", filename]
        return fields.contains { $0.lowercased().contains(query) }
    }
}
