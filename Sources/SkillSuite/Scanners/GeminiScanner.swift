import Foundation
struct GeminiScanner: ProviderScanner {
    let provider: AIProvider = .gemini
    func scan() -> [SkillFile] { [] }
}
