import Foundation

protocol ProviderScanner: Sendable {
    var provider: AIProvider { get }
    func scan() -> [SkillFile]
}
