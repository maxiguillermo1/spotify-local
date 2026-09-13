import Foundation
import Observation
#if canImport(SpotifyLocalCore)
import SpotifyLocalCore
#endif

@MainActor
@Observable
final class AppState {
    var connection: ConnectionStatus
    var library: MusicLibrary
    var searchText: String = ""
    var lastError: String?
    var isFileImporterPresented = false
    var isDropTargeted = false
    var isImporting = false
    var importError: String?

    let hostName: String
    private let client: any BridgeClient
    private var eventTask: Task<Void, Never>?

    var canImportMusic: Bool { client.supportsImport }

    init(
        client: any BridgeClient,
        hostName: String = "MacBook",
        connection: ConnectionStatus = .unavailable,
        library: MusicLibrary = .empty
    ) {
        self.client = client
        self.hostName = hostName
        self.connection = connection
        self.library = library
    }

    static var live: AppState {
        #if os(macOS)
        AppState(client: FolderBridgeClient(root: FolderBridgeClient.defaultMacRoot))
        #else
        AppState(client: FolderBridgeClient(root: FolderBridgeClient.defaultIOSRoot))
        #endif
    }

    var visibleTracks: [Track] {
        library.filtered(search: searchText)
    }

    var recentlyAdded: [Track] {
        Array(library.recentlyAdded.prefix(12))
    }

    func start() async {
        eventTask?.cancel()
        eventTask = Task { [weak self] in
            guard let self else { return }
            for await event in self.client.events {
                self.handle(event)
            }
        }
        await client.connect()
        await refreshLibrary()
    }

    func refreshLibrary() async {
        do {
            library = try await client.fetchLibrary()
            lastError = nil
        } catch {
            lastError = error.localizedDescription
            connection = .attention
        }
    }

    func download(_ track: Track) async {
        lastError = nil
        apply(trackID: track.id) { item in
            item.availability = .downloading(progress: 0)
        }
        do {
            try await client.download(track)
        } catch {
            apply(trackID: track.id) { item in
                item.availability = .attention
            }
            lastError = error.localizedDescription
            connection = .attention
        }
    }

    func presentImporter() {
        isFileImporterPresented = true
    }

    func importURLs(_ urls: [URL]) async {
        guard canImportMusic else { return }
        let resolved = urls.filter { $0.isFileURL }
        guard !resolved.isEmpty else { return }
        isImporting = true
        defer { isImporting = false }
        do {
            try await client.importFiles(resolved)
            await refreshLibrary()
            lastError = nil
        } catch {
            importError = error.localizedDescription
        }
    }

    func track(id: UUID) -> Track? {
        library.tracks.first { $0.id == id }
    }

    private func handle(_ event: BridgeEvent) {
        switch event {
        case .connection(let status):
            connection = status
        case .libraryUpdated:
            Task { await refreshLibrary() }
        case .transferProgress(let trackID, let progress):
            apply(trackID: trackID) { track in
                track.availability = .downloading(progress: progress)
            }
        case .transferCompleted(let trackID):
            apply(trackID: trackID) { track in
                track.availability = .iphone
            }
        case .transferFailed(let trackID, let message):
            apply(trackID: trackID) { track in
                track.availability = .attention
            }
            lastError = message
            connection = .attention
        }
    }

    private func apply(trackID: UUID, update: (inout Track) -> Void) {
        guard let index = library.tracks.firstIndex(where: { $0.id == trackID }) else { return }
        update(&library.tracks[index])
    }
}

extension AppState {
    static func preview(_ scenario: MockScenario) -> AppState {
        let client = MockBridgeClient(scenario: scenario)
        let state = AppState(
            client: client,
            connection: client.previewConnection,
            library: client.previewLibrary
        )
        return state
    }
}
