import Foundation

/// Scans user-registered project folders for project-local AI instruction files.
///
/// Each codebase is scanned for known AI provider file patterns.
/// Cursor and Windsurf are excluded from the v1 prototype (global paths unconfirmed).
struct CodebaseScannerService: Sendable {

    // MARK: - Known Patterns

    /// Patterns keyed by provider, listing relative paths to scan within a codebase root.
    /// Each relative path may be a file or a directory — `collectTarget` handles both.
    private static let patterns: [(provider: AIProvider, relativePaths: [String])] = [
        (.claude,  [".claude/commands", ".claude/skills", "CLAUDE.md"]),
        (.copilot, [".github/copilot-instructions.md"]),
        (.codex,   [".codex"]),
        (.gemini,  [".gemini/agents", ".gemini"]),
    ]

    // MARK: - Public Interface

    /// Scans a single codebase folder and returns all discovered `SkillFile`s.
    ///
    /// Files are deduplicated by path — a file matching multiple patterns appears once.
    func scan(codebase url: URL) -> [SkillFile] {
        var seen = Set<String>()
        var files: [SkillFile] = []

        for (provider, paths) in Self.patterns {
            for relativePath in paths {
                let target = url.appendingPathComponent(relativePath)
                let discovered = collectTarget(at: target, provider: provider)
                for file in discovered where seen.insert(file.path).inserted {
                    files.append(file)
                }
            }
        }
        return files.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Scans all registered codebases concurrently and returns updated `Codebase` values.
    func scanAll(_ codebases: [Codebase]) async -> [Codebase] {
        await withTaskGroup(of: (String, [SkillFile]).self) { group in
            for codebase in codebases {
                group.addTask { (codebase.url.path, self.scan(codebase: codebase.url)) }
            }
            var resultsByPath: [String: [SkillFile]] = [:]
            for await (path, files) in group {
                resultsByPath[path] = files
            }
            return codebases.map { codebase in
                var updated = codebase
                updated.files = resultsByPath[codebase.url.path] ?? []
                return updated
            }
        }
    }

    // MARK: - Private Helpers

    private func collectTarget(at url: URL, provider: AIProvider) -> [SkillFile] {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) else { return [] }

        if isDir.boolValue {
            return MarkdownCollector.collect(under: url, provider: provider, isGlobal: false)
        } else {
            return MarkdownCollector.collectFile(at: url, provider: provider, isGlobal: false)
        }
    }
}
