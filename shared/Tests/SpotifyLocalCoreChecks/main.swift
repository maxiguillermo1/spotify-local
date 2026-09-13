import Foundation
import SpotifyLocalCore

enum CheckFailure: Error {
    case failed(String)
}

struct Checker {
    var passed = 0

    mutating func expect(_ condition: Bool, _ message: String, file: StaticString = #fileID, line: UInt = #line) throws {
        if !condition {
            throw CheckFailure.failed("\(file):\(line) \(message)")
        }
        passed += 1
    }

    mutating func expectThrows<E: Error>(_ type: E.Type, _ message: String, work: () throws -> Void) throws {
        do {
            _ = try work()
            throw CheckFailure.failed(message + " (no throw)")
        } catch is E {
            passed += 1
        } catch let failure as CheckFailure {
            throw failure
        } catch {
            throw CheckFailure.failed(message + " (wrong error: \(error))")
        }
    }

    mutating func expectEquals<T: Equatable>(_ got: T, _ want: T, _ message: String) throws {
        try expect(got == want, "\(message): got \(got) want \(want)")
    }
}

func libraryRoot() throws -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("spotify-local-security-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    try "ok".write(to: url.appendingPathComponent("Nights.mp3"), atomically: true, encoding: .utf8)
    return url
}

func testPathSecurity(_ checker: inout Checker) throws {
    let root = try libraryRoot()
    let resolved = try PathSecurity.resolveFile(requested: "Nights.mp3", libraryRoot: root)
    try checker.expect(resolved.lastPathComponent == "Nights.mp3", "resolved filename")
    try checker.expect(PathSecurity.isInsideLibrary(resolved.path, rootPath: root.path), "inside library")

    try checker.expectThrows(PathSecurityError.self, "parent traversal") {
        _ = try PathSecurity.resolveFile(requested: "../Documents/secret.mp3", libraryRoot: root)
    }
    try checker.expectThrows(PathSecurityError.self, "nested traversal") {
        _ = try PathSecurity.resolveFile(requested: "album/../../secret.mp3", libraryRoot: root)
    }
    try checker.expectThrows(PathSecurityError.self, "absolute outside") {
        _ = try PathSecurity.resolveFile(requested: "/etc/passwd", libraryRoot: root)
    }
    try checker.expectThrows(PathSecurityError.self, "library root itself") {
        _ = try PathSecurity.resolveFile(requested: root.path, libraryRoot: root)
    }
    try checker.expectThrows(PathSecurityError.self, "empty path") {
        _ = try PathSecurity.resolveFile(requested: "  ", libraryRoot: URL(fileURLWithPath: "/tmp"))
    }
}

func testWireProtocol(_ checker: inout Checker) throws {
    let track = Track(
        id: UUID(uuidString: "A2F1C8B0-1234-4C3A-9B11-7E4E5D6C7B8A")!,
        title: "Nights",
        artist: "Frank Ocean",
        album: "Blonde",
        duration: 307,
        size: 9_412_000,
        format: "mp3",
        filename: "Nights.mp3",
        addedAt: Date(timeIntervalSince1970: 1_700_000_000),
        availability: .mac
    )
    let encodedTrack = try JSONEncoder.spotifyLocal.encode(track)
    let message = WireMessage(type: .librarySnapshot, payload: encodedTrack)
    let data = try WireCodec.encode(message)
    let decoded = try WireCodec.decode(from: data)
    try checker.expect(decoded.type == .librarySnapshot, "snapshot type")
    let restored = try JSONDecoder.spotifyLocal.decode(Track.self, from: decoded.payload)
    try checker.expectEquals(restored, track, "track round trip")

    let original = TrackAvailability.downloading(progress: 0.78)
    let availabilityData = try JSONEncoder.spotifyLocal.encode(original)
    let availability = try JSONDecoder.spotifyLocal.decode(TrackAvailability.self, from: availabilityData)
    try checker.expectEquals(availability, original, "availability round trip")

    let foreign = WireMessage(protocolVersion: 99, type: .hello)
    let foreignData = try JSONEncoder.spotifyLocal.encode(foreign)
    try checker.expectThrows(WireError.self, "foreign protocol") {
        _ = try WireCodec.decode(from: foreignData)
    }
}

func testSearchAndLabels(_ checker: inout Checker) throws {
    try checker.expectEquals(ConnectionStatus.connected.title, "Connected", "connected title")
    try checker.expectEquals(ConnectionStatus.unavailable.title, "Mac unavailable", "unavailable title")
    try checker.expectEquals(TrackAvailability.mac.label, "On Mac", "mac label")
    try checker.expectEquals(TrackAvailability.iphone.label, "On iPhone", "iphone label")

    let track = Track(
        title: "White Ferrari",
        artist: "Frank Ocean",
        album: "Blonde",
        size: 1,
        format: "m4a",
        filename: "White Ferrari.m4a",
        addedAt: Date(),
        availability: .mac
    )
    let library = MusicLibrary(tracks: [track])
    try checker.expect(library.filtered(search: "ferrari").count == 1, "title search")
    try checker.expect(library.filtered(search: "ocean").count == 1, "artist search")
    try checker.expect(library.filtered(search: "blonde").count == 1, "album search")
    try checker.expect(library.filtered(search: "White Ferrari.m4a").count == 1, "filename search")
    try checker.expect(library.filtered(search: "radiohead").isEmpty, "negative search")
}

func testTransferState(_ checker: inout Checker) throws {
    let state = TrackAvailability.downloading(progress: 0.5)
    guard case .downloading(let progress) = state else {
        throw CheckFailure.failed("expected downloading state")
    }
    try checker.expect(progress == 0.5, "download progress")
}

func testLibraryImporter(_ checker: inout Checker) throws {
    let root = try libraryRoot()
    try checker.expectEquals(
        LibraryImporter.sanitizedFileName("../../secret.mp3"),
        "secret.mp3",
        "sanitizes traversal to basename"
    )
    try checker.expectEquals(
        LibraryImporter.sanitizedFileName(".hidden.m4a"),
        "hidden.m4a",
        "strips leading dot"
    )
    try checker.expect(LibraryImporter.isAudioFile(URL(fileURLWithPath: "/tmp/Nights.mp3")), "mp3 allowed")
    try checker.expect(!LibraryImporter.isAudioFile(URL(fileURLWithPath: "/tmp/notes.txt")), "txt rejected")

    let source = root.deletingLastPathComponent().appendingPathComponent("incoming.mp3")
    try "audio".write(to: source, atomically: true, encoding: .utf8)
    let imported = try LibraryImporter.importItem(from: source, into: root)
    try checker.expect(imported == 1, "copied one file")
    let files = try LibraryImporter.enumerateAudioFiles(in: root)
    try checker.expect(files.contains { $0.lastPathComponent == "incoming.mp3" }, "enumerated copied file")
    try checker.expect(
        PathSecurity.isInsideLibrary(files.first { $0.lastPathComponent == "incoming.mp3" }!.path, rootPath: root.path),
        "copy stayed inside library"
    )

    let again = try LibraryImporter.importItem(from: source, into: root)
    try checker.expect(again == 1, "duplicate name still copies uniquely")
    let after = try LibraryImporter.enumerateAudioFiles(in: root)
    try checker.expect(after.contains { $0.lastPathComponent == "incoming 2.mp3" }, "unique destination")

    try checker.expectThrows(LibraryImportError.self, "unsupported format") {
        let txt = root.deletingLastPathComponent().appendingPathComponent("note.txt")
        try "nope".write(to: txt, atomically: true, encoding: .utf8)
        _ = try LibraryImporter.importItem(from: txt, into: root)
    }

    let firstID = LibraryImporter.stableID(relativePath: "Nights.mp3")
    let secondID = LibraryImporter.stableID(relativePath: "Nights.mp3")
    try checker.expect(firstID == secondID, "stable ids")
    try checker.expect(
        LibraryImporter.stableID(relativePath: "Other.mp3") != firstID,
        "different files different ids"
    )
}

@main
enum SpotifyLocalCoreChecks {
    static func main() {
        var checker = Checker()
        do {
            try testPathSecurity(&checker)
            try testWireProtocol(&checker)
            try testSearchAndLabels(&checker)
            try testTransferState(&checker)
            try testLibraryImporter(&checker)
            print("SpotifyLocalCore checks passed (\(checker.passed))")
        } catch {
            FileHandle.standardError.write(Data("FAIL: \(error)\n".utf8))
            exit(1)
        }
    }
}
