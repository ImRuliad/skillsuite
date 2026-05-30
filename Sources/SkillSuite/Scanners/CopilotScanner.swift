import Foundation

/// Scans GitHub Copilot's global settings for `.md` instruction files.
///
/// Covers two distinct locations per Copilot's specification:
/// - `~/.copilot/copilot-instructions.md` (primary global instructions)
/// - `~/.copilot/instructions/*.instructions.md` (additional files, non-recursive)
struct CopilotScanner: ProviderScanner {
    let provider: AIProvider = .copilot
    private let home = FileManager.default.homeDirectoryForCurrentUser

    func scan() -> [SkillFile] {
        let base = home.appendingPathComponent(".copilot")
        guard FileManager.default.fileExists(atPath: base.path) else { return [] }

        let primary = MarkdownCollector.collectFile(
            at: base.appendingPathComponent("copilot-instructions.md"),
            provider: .copilot,
            isGlobal: true
        )
        let additional = MarkdownCollector.collectDirectory(
            base.appendingPathComponent("instructions"),
            root: base,
            matchingSuffix: ".instructions.md",
            provider: .copilot,
            isGlobal: true
        )
        return primary + additional
    }
}
