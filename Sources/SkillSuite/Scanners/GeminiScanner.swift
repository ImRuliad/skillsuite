import Foundation

/// Scans `~/.gemini/` recursively for `.md` files.
///
/// Covers:
/// - Root-level `.md` files
/// - `agents/*.md` (agent definition files)
/// - Any future subdirectory nesting
struct GeminiScanner: ProviderScanner {
    let provider: AIProvider = .gemini
    private let home = FileManager.default.homeDirectoryForCurrentUser

    func scan() -> [SkillFile] {
        MarkdownCollector.collect(
            under: home.appendingPathComponent(".gemini"),
            provider: .gemini,
            isGlobal: true
        )
    }
}
