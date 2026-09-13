import Darwin
import Foundation
#if canImport(SpotifyLocalCore)
import SpotifyLocalCore
#endif

@MainActor
final class FolderBridgeClient: BridgeClient {
    let root: URL
    var supportsImport: Bool { true }

    private let continuation: AsyncStream<BridgeEvent>.Continuation
    let events: AsyncStream<BridgeEvent>
    private var watchSource: DispatchSourceFileSystemObject?
    private var watchFD: Int32 = -1
    private var downloadedIDs: Set<UUID>
    private let downloadedKey: String

    init(root: URL) {
        self.root = root
        self.downloadedKey = "downloaded-track-ids:\(root.path)"
        if let stored = UserDefaults.standard.array(forKey: downloadedKey) as? [String] {
            downloadedIDs = Set(stored.compactMap(UUID.init(uuidString:)))
        } else {
            downloadedIDs = []
        }
        let (stream, continuation) = AsyncStream.makeStream(of: BridgeEvent.self)
        self.events = stream
        self.continuation = continuation
    }

    static var defaultMacRoot: URL {
        if let override = ProcessInfo.processInfo.environment["SPOTIFY_LOCAL_MUSIC_DIR"], !override.isEmpty {
            return URL(fileURLWithPath: override, isDirectory: true)
        }
        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Desktop/Spotify Local", isDirectory: true)
    }

    static var defaultIOSRoot: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Spotify Local", isDirectory: true)
    }

    func connect() async {
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        startWatching()
        continuation.yield(.connection(.connected))
    }

    func disconnect() {
        stopWatching()
        continuation.yield(.connection(.unavailable))
    }

    func fetchLibrary() async throws -> MusicLibrary {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let files = try LibraryImporter.enumerateAudioFiles(in: root)
        var tracks: [Track] = []
        for file in files {
            tracks.append(await track(from: file))
        }
        return MusicLibrary(tracks: tracks, generatedAt: Date())
    }

    func importFiles(_ urls: [URL]) async throws {
        var imported = 0
        var sawUnsupported = false
        for url in urls {
            let access = url.startAccessingSecurityScopedResource()
            defer {
                if access {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            do {
                imported += try LibraryImporter.importItem(from: url, into: root)
            } catch LibraryImportError.unsupported {
                sawUnsupported = true
            }
        }
        if imported == 0 {
            throw sawUnsupported ? LibraryImportError.unsupported : LibraryImportError.empty
        }
        continuation.yield(.libraryUpdated)
        continuation.yield(.connection(.connected))
    }

    func download(_ track: Track) async throws {
        for step in 1 ... 8 {
            try await Task.sleep(for: .milliseconds(90))
            continuation.yield(.transferProgress(trackID: track.id, progress: Double(step) / 8.0))
        }
        downloadedIDs.insert(track.id)
        persistDownloaded()
        continuation.yield(.transferCompleted(trackID: track.id))
    }

    private func track(from file: URL) async -> Track {
        let relative = LibraryImporter.relativePath(for: file, root: root)
        let values = try? file.resourceValues(forKeys: [.fileSizeKey, .creationDateKey, .contentModificationDateKey])
        let size = Int64(values?.fileSize ?? 0)
        let added = values?.creationDate ?? values?.contentModificationDate ?? Date()
        let meta = await AudioMetadataReader.read(from: file, filename: relative)
        let id = LibraryImporter.stableID(relativePath: relative)
        let artwork: ArtworkReference?
        if let data = meta.artwork, !data.isEmpty {
            artwork = ArtworkReference(systemSymbol: nil, backgroundHex: "2C2C2E", imageData: data)
        } else {
            artwork = .missing
        }
        return Track(
            id: id,
            title: meta.title,
            artist: meta.artist,
            album: meta.album,
            artwork: artwork,
            duration: meta.duration,
            size: size,
            format: file.pathExtension.lowercased(),
            filename: relative,
            addedAt: added,
            availability: downloadedIDs.contains(id) ? .iphone : .mac
        )
    }

    private func persistDownloaded() {
        UserDefaults.standard.set(downloadedIDs.map(\.uuidString), forKey: downloadedKey)
    }

    private func startWatching() {
        stopWatching()
        watchFD = open(root.path, O_EVTONLY)
        guard watchFD >= 0 else { return }
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: watchFD,
            eventMask: [.write, .delete, .rename, .extend, .attrib],
            queue: .main
        )
        source.setEventHandler { [weak self] in
            self?.continuation.yield(.libraryUpdated)
        }
        source.setCancelHandler { [weak self] in
            guard let self else { return }
            if self.watchFD >= 0 {
                close(self.watchFD)
                self.watchFD = -1
            }
        }
        source.resume()
        watchSource = source
    }

    private func stopWatching() {
        watchSource?.cancel()
        watchSource = nil
    }
}
