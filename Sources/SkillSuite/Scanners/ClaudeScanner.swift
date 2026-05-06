import Foundation

/// Scans `~/.claude/` recursively for `.md` files.
///
/// Covers all known Claude file locations:
/// - `CLAUDE.md` (top-level instructions)
/// - `commands/*.md` (slash command definitions)
/// - `skills/**/*.md` (nested skill files)
/// - Any future nesting is handled automatically via recursive enumeration.
struct ClaudeScanner: ProviderScanner {
    let provider: AIProvider = .claude
    private let home = FileManager.default.homeDirectoryForCurrentUser

    func scan() -> [SkillFile] {
        MarkdownCollector.collect(
            under: home.appendingPathComponent(".claude"),
            provider: .claude,
            isGlobal: true
        )
    }
}
