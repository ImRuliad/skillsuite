import Foundation
struct CodebaseScannerService {
    func scan(codebase _: URL) -> [SkillFile] { [] }
    func scanAll(_ codebases: [Codebase]) async -> [Codebase] { codebases }
}
