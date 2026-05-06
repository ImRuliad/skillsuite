import Foundation
struct ClaudeScanner: ProviderScanner {
    let provider: AIProvider = .claude
    func scan() -> [SkillFile] { [] }
}
