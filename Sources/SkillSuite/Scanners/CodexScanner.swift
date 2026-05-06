import Foundation

/// Scans `~/.codex/` recursively for `.md` files.
///
/// Non-markdown files (e.g. `config.toml`) are silently ignored — TOML support
/// is deferred to v2. If `~/.codex/` contains only `config.toml`, this scanner
/// returns `[]` and the UI shows an empty state for Codex — expected in v1.
struct CodexScanner: ProviderScanner {
    let provider: AIProvider = .codex
    private let home = FileManager.default.homeDirectoryForCurrentUser

    func scan() -> [SkillFile] {
        MarkdownCollector.collect(
            under: home.appendingPathComponent(".codex"),
            provider: .codex,
            isGlobal: true
        )
    }
}
