import Foundation

public enum ConnectionStatus: String, Codable, Equatable, Sendable {
    case connected
    case working
    case attention
    case unavailable

    public var title: String {
        switch self {
        case .connected: "Connected"
        case .working: "Working"
        case .attention: "Attention needed"
        case .unavailable: "Mac unavailable"
        }
    }
}
