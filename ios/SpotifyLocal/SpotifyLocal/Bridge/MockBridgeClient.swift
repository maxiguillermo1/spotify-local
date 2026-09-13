import Foundation
#if canImport(SpotifyLocalCore)
import SpotifyLocalCore
#endif

enum MockScenario: String, CaseIterable, Sendable {
    case connected
    case offline
    case empty
    case downloading
    case complete
    case failed
    case large
    case missingArtwork
}

@MainActor
final class MockBridgeClient: BridgeClient {
    let scenario: MockScenario
    private let continuation: AsyncStream<BridgeEvent>.Continuation
    let events: AsyncStream<BridgeEvent>
    private var connected = false

    private var extraTracks: [Track] = []

    var supportsImport: Bool { scenario != .offline }

    init(scenario: MockScenario = .connected) {
        self.scenario = scenario
        let (stream, continuation) = AsyncStream.makeStream(of: BridgeEvent.self)
        self.events = stream
        self.continuation = continuation
    }

    var previewConnection: ConnectionStatus {
        switch scenario {
        case .offline: .unavailable
        case .failed: .attention
        case .downloading: .working
        default: .connected
        }
    }

    var previewLibrary: MusicLibrary {
        MockLibrary.library(for: scenario)
    }

    func connect() async {
        connected = scenario != .offline
        continuation.yield(.connection(previewConnection))
    }

    func disconnect() {
        connected = false
        continuation.yield(.connection(.unavailable))
    }

    func fetchLibrary() async throws -> MusicLibrary {
        if scenario == .offline {
            throw BridgeFailure.offline
        }
        return MusicLibrary(tracks: MockLibrary.library(for: scenario).tracks + extraTracks)
    }

    func importFiles(_ urls: [URL]) async throws {
        if scenario == .offline {
            throw BridgeFailure.offline
        }
        for url in urls {
            extraTracks.append(
                Track(
                    title: url.deletingPathExtension().lastPathComponent,
                    size: (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init) ?? 0,
                    format: url.pathExtension.lowercased(),
                    filename: url.lastPathComponent,
                    addedAt: Date(),
                    availability: .mac
                )
            )
        }
        continuation.yield(.libraryUpdated)
    }

    func download(_ track: Track) async throws {
        if scenario == .offline {
            throw BridgeFailure.offline
        }
        if scenario == .failed || track.availability == .attention {
            continuation.yield(.transferFailed(trackID: track.id, message: "Couldn’t copy this file."))
            throw BridgeFailure.transferFailed("Couldn’t copy this file.")
        }
        for step in 1 ... 8 {
            try await Task.sleep(for: .milliseconds(90))
            continuation.yield(.transferProgress(trackID: track.id, progress: Double(step) / 8.0))
        }
        continuation.yield(.transferCompleted(trackID: track.id))
    }
}

enum BridgeFailure: Error, LocalizedError {
    case offline
    case notImplemented
    case transferFailed(String)

    var errorDescription: String? {
        switch self {
        case .offline:
            "Mac unavailable"
        case .notImplemented:
            "Local networking is not connected yet."
        case .transferFailed(let message):
            message
        }
    }
}
