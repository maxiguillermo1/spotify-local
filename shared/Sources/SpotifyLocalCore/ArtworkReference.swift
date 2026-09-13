import Foundation

public struct ArtworkReference: Codable, Equatable, Hashable, Sendable {
    public var systemSymbol: String?
    public var backgroundHex: String?
    public var accentHex: String?

    public var imageData: Data?

    public init(
        systemSymbol: String? = "music.note",
        backgroundHex: String? = nil,
        accentHex: String? = nil,
        imageData: Data? = nil
    ) {
        self.systemSymbol = systemSymbol
        self.backgroundHex = backgroundHex
        self.accentHex = accentHex
        self.imageData = imageData
    }

    public static let missing = ArtworkReference(
        systemSymbol: "music.note",
        backgroundHex: "3A3A3C",
        accentHex: "EBEBF5"
    )
}
