import Foundation

public enum BridgeEvent: Equatable, Sendable {
    case connection(ConnectionStatus)
    case libraryUpdated
    case transferProgress(trackID: UUID, progress: Double)
    case transferCompleted(trackID: UUID)
    case transferFailed(trackID: UUID, message: String)
}
