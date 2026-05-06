import Foundation
struct CopilotScanner: ProviderScanner {
    let provider: AIProvider = .copilot
    func scan() -> [SkillFile] { [] }
}
