import Foundation
#if canImport(SpotifyLocalCore)
import SpotifyLocalCore
#endif

/// Real Bonjour client. Wired in Phase 4; the UI talks to `BridgeClient` only.
@MainActor
final class LocalBridgeClient: BridgeClient {
    private let continuation: AsyncStream<BridgeEvent>.Continuation
    let events: AsyncStream<BridgeEvent>

    var supportsImport: Bool { false }

    init() {
        let (stream, continuation) = AsyncStream.makeStream(of: BridgeEvent.self)
        self.events = stream
        self.continuation = continuation
    }

    func connect() async {
        continuation.yield(.connection(.unavailable))
    }

    func disconnect() {
        continuation.yield(.connection(.unavailable))
    }

    func fetchLibrary() async throws -> MusicLibrary {
        throw BridgeFailure.notImplemented
    }

    func importFiles(_ urls: [URL]) async throws {
        _ = urls
        throw BridgeFailure.notImplemented
    }

    func download(_ track: Track) async throws {
        _ = track
        throw BridgeFailure.notImplemented
    }
}
