import Foundation

public enum LibraryImportError: Error, Equatable, LocalizedError {
    case unsupported
    case empty
    case copyFailed

    public var errorDescription: String? {
        switch self {
        case .unsupported:
            "That file isn’t a supported audio format."
        case .empty:
            "No audio files were found."
        case .copyFailed:
            "Couldn’t copy that file into your music folder."
        }
    }
}

public enum LibraryImporter {
    public static let allowedExtensions: Set<String> = [
        "mp3", "m4a", "aac", "wav", "aiff", "aif", "flac", "alac",
    ]

    public static func isAudioFile(_ url: URL) -> Bool {
        allowedExtensions.contains(url.pathExtension.lowercased())
    }

    public static func sanitizedFileName(_ raw: String) -> String {
        var name = (raw as NSString).lastPathComponent
        name = name.replacingOccurrences(of: ":", with: "-")
        name = name.replacingOccurrences(of: "/", with: "-")
        name = name.replacingOccurrences(of: "\0", with: "")
        name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.hasPrefix(".") {
            name = String(name.dropFirst())
        }
        if name.isEmpty || name == "." || name == ".." {
            return "Track"
        }
        let ext = (name as NSString).pathExtension.lowercased()
        let base = (name as NSString).deletingPathExtension
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let safeBase = base.isEmpty ? "Track" : base
        if allowedExtensions.contains(ext) {
            return "\(safeBase).\(ext)"
        }
        if ext.isEmpty {
            return safeBase
        }
        return "\(safeBase).\(ext)"
    }

    public static func uniqueDestination(fileName: String, in root: URL) -> URL {
        let sanitized = sanitizedFileName(fileName)
        let ext = (sanitized as NSString).pathExtension
        let base = (sanitized as NSString).deletingPathExtension
        var n = 1
        while true {
            let candidateName: String
            if n == 1 {
                candidateName = sanitized
            } else if ext.isEmpty {
                candidateName = "\(base) \(n)"
            } else {
                candidateName = "\(base) \(n).\(ext)"
            }
            let candidate = root.appendingPathComponent(candidateName)
            if !FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
            n += 1
        }
    }

    @discardableResult
    public static func importItem(from source: URL, into root: URL) throws -> Int {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: source.path, isDirectory: &isDirectory) else {
            throw LibraryImportError.copyFailed
        }
        if isDirectory.boolValue {
            return try importDirectory(source, into: root)
        }
        return try importFile(source, into: root)
    }

    public static func enumerateAudioFiles(in root: URL) throws -> [URL] {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var files: [URL] = []
        for case let url as URL in enumerator {
            guard isAudioFile(url) else { continue }
            do {
                files.append(try PathSecurity.resolveFile(requested: url.path, libraryRoot: root))
            } catch {
                continue
            }
        }
        return files
    }

    public static func stableID(relativePath: String) -> UUID {
        var bytes = [UInt8](repeating: 0, count: 16)
        let data = Array(relativePath.utf8)
        var mix: UInt8 = 165
        for (index, byte) in data.enumerated() {
            mix = mix &* 31 &+ byte
            bytes[index % 16] ^= byte &+ mix
        }
        bytes[6] = (bytes[6] & 0x0F) | 0x40
        bytes[8] = (bytes[8] & 0x3F) | 0x80
        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }

    public static func relativePath(for file: URL, root: URL) -> String {
        let rootPath = root.standardizedFileURL.path
        let filePath = file.standardizedFileURL.path
        if filePath.hasPrefix(rootPath) {
            let start = filePath.index(filePath.startIndex, offsetBy: rootPath.count)
            return String(filePath[start...]).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        }
        return file.lastPathComponent
    }

    private static func importFile(_ source: URL, into root: URL) throws -> Int {
        guard isAudioFile(source) else { throw LibraryImportError.unsupported }
        let resolvedSource = source.standardizedFileURL.resolvingSymlinksInPath()
        if PathSecurity.isInsideLibrary(resolvedSource.path, rootPath: root.path) {
            return 0
        }
        let destination = uniqueDestination(fileName: source.lastPathComponent, in: root)
        do {
            try FileManager.default.copyItem(at: resolvedSource, to: destination)
        } catch {
            throw LibraryImportError.copyFailed
        }
        _ = try PathSecurity.resolveFile(requested: destination.path, libraryRoot: root)
        return 1
    }

    private static func importDirectory(_ directory: URL, into root: URL) throws -> Int {
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }

        var imported = 0
        var sawAudio = false
        for case let url as URL in enumerator {
            guard isAudioFile(url) else { continue }
            sawAudio = true
            imported += try importFile(url, into: root)
        }
        if imported == 0 && !sawAudio {
            throw LibraryImportError.empty
        }
        return imported
    }
}
