import Foundation
struct CodexScanner: ProviderScanner {
    let provider: AIProvider = .codex
    func scan() -> [SkillFile] { [] }
}
