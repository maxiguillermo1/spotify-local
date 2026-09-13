import Foundation

public enum PathSecurityError: Error, Equatable, LocalizedError {
    case emptyPath
    case pathTraversal
    case outsideLibrary
    case invalidRequest(String)

    public var errorDescription: String? {
        switch self {
        case .emptyPath:
            "A file path is required."
        case .pathTraversal:
            "That path is not allowed."
        case .outsideLibrary:
            "Only files inside the music folder can be transferred."
        case .invalidRequest(let message):
            message
        }
    }
}

public enum PathSecurity {
    public static func resolveFile(requested: String, libraryRoot: URL) throws -> URL {
        let trimmed = requested.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw PathSecurityError.emptyPath }
        if trimmed.contains("\0") {
            throw PathSecurityError.invalidRequest("invalid path")
        }

        let root = libraryRoot.standardizedFileURL.resolvingSymlinksInPath()
        let candidate: URL
        if trimmed.hasPrefix("/") {
            candidate = URL(fileURLWithPath: trimmed)
        } else {
            candidate = root.appendingPathComponent(trimmed)
        }

        let standardized = candidate.standardizedFileURL
        let resolved = standardized.resolvingSymlinksInPath()
        let rootPath = root.path
        let resolvedPath = resolved.path

        if containsTraversal(trimmed) || containsTraversal(standardized.path) {
            throw PathSecurityError.pathTraversal
        }

        guard isInsideLibrary(resolvedPath, rootPath: rootPath) else {
            throw PathSecurityError.outsideLibrary
        }

        return resolved
    }

    public static func isInsideLibrary(_ path: String, rootPath: String) -> Bool {
        let normalizedPath = (path as NSString).standardizingPath
        let normalizedRoot = (rootPath as NSString).standardizingPath
        if normalizedPath == normalizedRoot { return false }
        return normalizedPath.hasPrefix(normalizedRoot.hasSuffix("/") ? normalizedRoot : normalizedRoot + "/")
    }

    private static func containsTraversal(_ path: String) -> Bool {
        let parts = path.split(separator: "/", omittingEmptySubsequences: true)
        return parts.contains("..")
    }
}
