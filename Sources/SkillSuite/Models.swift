import Foundation

// MARK: - AIProvider

enum AIProvider: String, CaseIterable, Identifiable, Sendable {
    case claude  = "Claude"
    case copilot = "Copilot"
    case codex   = "Codex"
    case gemini  = "Gemini"

    var id: String { rawValue }
}

// MARK: - SkillFile

/// Represents a single AI skill/instruction markdown file discovered on disk.
///
/// Identity is path-based, not UUID-based. This is critical:
/// every scan creates new objects — if id were a random UUID,
/// FSEvents highlight detection and search index matching would break
/// on every rescan because all IDs would change.
struct SkillFile: Identifiable, Hashable, Sendable {
    var id: String { path }

    let provider: AIProvider
    let name: String      // filename with extension, e.g. "CLAUDE.md"
    let path: String      // full absolute path
    let contents: String  // raw UTF-8 string
    let isGlobal: Bool    // true = global provider folder; false = user-added codebase

    func hash(into hasher: inout Hasher) {
        hasher.combine(path)
    }

    static func == (lhs: SkillFile, rhs: SkillFile) -> Bool {
        lhs.path == rhs.path
    }
}

// MARK: - Codebase

/// Represents a user-registered local project folder.
///
/// Identity is also path-based (url.path) for the same reason as SkillFile.
struct Codebase: Identifiable, Hashable, Sendable {
    var id: String { url.path }

    let url: URL
    var files: [SkillFile]
    var displayName: String { url.lastPathComponent }

    func hash(into hasher: inout Hasher) {
        hasher.combine(url.path)
    }

    static func == (lhs: Codebase, rhs: Codebase) -> Bool {
        lhs.url.path == rhs.url.path
    }
}
