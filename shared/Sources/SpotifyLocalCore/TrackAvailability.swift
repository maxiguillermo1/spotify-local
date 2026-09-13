import Foundation

public enum TrackAvailability: Equatable, Hashable, Sendable {
    case mac
    case downloading(progress: Double)
    case iphone
    case attention

    public var label: String {
        switch self {
        case .mac: "On Mac"
        case .downloading: "Downloading"
        case .iphone: "On iPhone"
        case .attention: "Needs attention"
        }
    }
}

extension TrackAvailability: Codable {
    private enum CodingKeys: String, CodingKey {
        case kind
        case progress
    }

    private enum Kind: String, Codable {
        case mac
        case downloading
        case iphone
        case attention
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        switch kind {
        case .mac:
            self = .mac
        case .downloading:
            let progress = try container.decode(Double.self, forKey: .progress)
            self = .downloading(progress: progress)
        case .iphone:
            self = .iphone
        case .attention:
            self = .attention
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .mac:
            try container.encode(Kind.mac, forKey: .kind)
        case .downloading(let progress):
            try container.encode(Kind.downloading, forKey: .kind)
            try container.encode(progress, forKey: .progress)
        case .iphone:
            try container.encode(Kind.iphone, forKey: .kind)
        case .attention:
            try container.encode(Kind.attention, forKey: .kind)
        }
    }
}
