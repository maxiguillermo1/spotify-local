import Foundation
import SpotifyLocalCore

@main
enum SpotifyLocalCompanion {
    static func main() {
        let environment = ProcessInfo.processInfo.environment
        let runDir = URL(
            fileURLWithPath: environment["SPOTIFY_LOCAL_RUN_DIR"] ?? FileManager.default.temporaryDirectory.path,
            isDirectory: true
        )
        let musicDir = URL(
            fileURLWithPath: environment["SPOTIFY_LOCAL_MUSIC_DIR"]
                ?? FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Desktop/Spotify Local", isDirectory: true).path,
            isDirectory: true
        )

        do {
            try FileManager.default.createDirectory(at: runDir, withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: musicDir, withIntermediateDirectories: true)
        } catch {
            FileHandle.standardError.write(Data("Spotify Local companion failed to create folders: \(error)\n".utf8))
            exit(1)
        }

        let pidURL = runDir.appendingPathComponent("companion.pid")
        if let existing = existingLivePID(at: pidURL) {
            FileHandle.standardOutput.write(Data("Spotify Local companion already running (\(existing))\n".utf8))
            exit(0)
        }

        let pid = ProcessInfo.processInfo.processIdentifier
        do {
            try String(pid).write(to: pidURL, atomically: true, encoding: .utf8)
        } catch {
            FileHandle.standardError.write(Data("Spotify Local companion failed to write pid: \(error)\n".utf8))
            exit(1)
        }

        signal(SIGTERM, SIG_IGN)
        signal(SIGINT, SIG_IGN)
        let source = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
        source.setEventHandler {
            try? FileManager.default.removeItem(at: pidURL)
            exit(0)
        }
        source.resume()
        let interrupt = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
        interrupt.setEventHandler {
            try? FileManager.default.removeItem(at: pidURL)
            exit(0)
        }
        interrupt.resume()

        let tracks = indexedTrackCount(in: musicDir)
        FileHandle.standardOutput.write(
            Data("Spotify Local companion running\nMusic folder: \(musicDir.path)\nTracks: \(tracks)\n".utf8)
        )

        RunLoop.main.run()
    }

    private static func existingLivePID(at url: URL) -> Int32? {
        guard let raw = try? String(contentsOf: url, encoding: .utf8),
              let value = Int32(raw.trimmingCharacters(in: .whitespacesAndNewlines)),
              value > 0
        else { return nil }
        if kill(value, 0) == 0 {
            return value
        }
        try? FileManager.default.removeItem(at: url)
        return nil
    }

    private static func indexedTrackCount(in folder: URL) -> Int {
        let allowed: Set<String> = ["mp3", "m4a", "aac", "wav", "aiff", "aif", "flac", "alac"]
        guard let enumerator = FileManager.default.enumerator(
            at: folder,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }

        var count = 0
        for case let file as URL in enumerator {
            let ext = file.pathExtension.lowercased()
            guard allowed.contains(ext) else { continue }
            do {
                _ = try PathSecurity.resolveFile(requested: file.path, libraryRoot: folder)
                count += 1
            } catch {
                continue
            }
        }
        return count
    }
}
