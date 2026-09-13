import Foundation
#if canImport(SpotifyLocalCore)
import SpotifyLocalCore
#endif

@MainActor
protocol BridgeClient: AnyObject {
    var supportsImport: Bool { get }
    func connect() async
    func disconnect()
    func fetchLibrary() async throws -> MusicLibrary
    func importFiles(_ urls: [URL]) async throws
    func download(_ track: Track) async throws
    var events: AsyncStream<BridgeEvent> { get }
}
