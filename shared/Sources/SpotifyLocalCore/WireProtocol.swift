import Foundation

public let spotifyLocalProtocolVersion = 1
public let spotifyLocalBonjourType = "_spotifylocal._tcp"

public enum WireMessageType: String, Codable, Sendable {
    case hello
    case deviceStatus
    case librarySnapshot
    case trackMetadata
    case transferRequest
    case transferProgress
    case transferComplete
    case error
}

public struct WireMessage: Codable, Equatable, Sendable {
    public var protocolVersion: Int
    public var type: WireMessageType
    public var payload: Data

    public init(protocolVersion: Int = spotifyLocalProtocolVersion, type: WireMessageType, payload: Data = Data()) {
        self.protocolVersion = protocolVersion
        self.type = type
        self.payload = payload
    }
}

public struct DeviceStatusPayload: Codable, Equatable, Sendable {
    public var deviceName: String
    public var trackCount: Int
    public var musicFolder: String

    public init(deviceName: String, trackCount: Int, musicFolder: String) {
        self.deviceName = deviceName
        self.trackCount = trackCount
        self.musicFolder = musicFolder
    }
}

public struct TransferRequestPayload: Codable, Equatable, Sendable {
    public var trackID: UUID
    public var filename: String

    public init(trackID: UUID, filename: String) {
        self.trackID = trackID
        self.filename = filename
    }
}

public struct TransferProgressPayload: Codable, Equatable, Sendable {
    public var trackID: UUID
    public var progress: Double

    public init(trackID: UUID, progress: Double) {
        self.trackID = trackID
        self.progress = progress
    }
}

public struct WireErrorPayload: Codable, Equatable, Sendable {
    public var code: String
    public var message: String

    public init(code: String, message: String) {
        self.code = code
        self.message = message
    }
}

public enum WireError: Error, Equatable {
    case unsupportedVersion(Int)
}

public enum WireCodec {
    public static func encode(_ message: WireMessage) throws -> Data {
        try JSONEncoder.spotifyLocal.encode(message)
    }

    public static func decode(from data: Data) throws -> WireMessage {
        let message = try JSONDecoder.spotifyLocal.decode(WireMessage.self, from: data)
        guard message.protocolVersion == spotifyLocalProtocolVersion else {
            throw WireError.unsupportedVersion(message.protocolVersion)
        }
        return message
    }
}

public extension JSONEncoder {
    static var spotifyLocal: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }
}

public extension JSONDecoder {
    static var spotifyLocal: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
