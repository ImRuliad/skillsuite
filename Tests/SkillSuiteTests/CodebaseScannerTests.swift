import Testing
import Foundation
@testable import SkillSuite

@Suite("CodebaseScannerService")
struct CodebaseScannerTests {

    private let scanner = CodebaseScannerService()

    private func tmp() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test("returns empty for codebase with no known AI files")
    func emptyCodebase() throws {
        let root = try tmp()
        defer { try? FileManager.default.removeItem(at: root) }
        try "readme".write(to: root.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)
        // README.md is not in a known AI path, so it should not be collected
        let files = scanner.scan(codebase: root)
        #expect(files.isEmpty)
    }

    @Test("collects CLAUDE.md from codebase root")
    func collectsClaudeMd() throws {
        let root = try tmp()
        defer { try? FileManager.default.removeItem(at: root) }
        try "# Instructions".write(to: root.appendingPathComponent("CLAUDE.md"), atomically: true, encoding: .utf8)
        let files = scanner.scan(codebase: root)
        #expect(files.count == 1)
        #expect(files[0].name == "CLAUDE.md")
        #expect(files[0].provider == .claude)
        #expect(files[0].isGlobal == false)
    }

    @Test("collects files from .claude/commands/ directory")
    func collectsClaudeCommands() throws {
        let root = try tmp()
        defer { try? FileManager.default.removeItem(at: root) }
        let commands = root.appendingPathComponent(".claude/commands")
        try FileManager.default.createDirectory(at: commands, withIntermediateDirectories: true)
        try "# cmd".write(to: commands.appendingPathComponent("deploy.md"), atomically: true, encoding: .utf8)
        let files = scanner.scan(codebase: root)
        #expect(files.count == 1)
        #expect(files[0].name == "deploy.md")
        #expect(files[0].isGlobal == false)
    }

    @Test("collects copilot instructions from .github/")
    func collectsCopilotInstructions() throws {
        let root = try tmp()
        defer { try? FileManager.default.removeItem(at: root) }
        let github = root.appendingPathComponent(".github")
        try FileManager.default.createDirectory(at: github, withIntermediateDirectories: true)
        try "# Copilot".write(to: github.appendingPathComponent("copilot-instructions.md"), atomically: true, encoding: .utf8)
        let files = scanner.scan(codebase: root)
        #expect(files.count == 1)
        #expect(files[0].provider == .copilot)
    }

    @Test("deduplicates files matching multiple patterns")
    func deduplication() throws {
        let root = try tmp()
        defer { try? FileManager.default.removeItem(at: root) }
        // .gemini and .gemini/agents both resolve to the same directory tree
        let gemini = root.appendingPathComponent(".gemini")
        let agents = gemini.appendingPathComponent("agents")
        try FileManager.default.createDirectory(at: agents, withIntermediateDirectories: true)
        try "# Agent".write(to: agents.appendingPathComponent("agent.md"), atomically: true, encoding: .utf8)

        let files = scanner.scan(codebase: root)
        // agent.md should appear exactly once despite matching both .gemini and .gemini/agents patterns
        let agentFiles = files.filter { $0.name == "agent.md" }
        #expect(agentFiles.count == 1)
    }

    @Test("scanned files have isGlobal = false")
    func isGlobalFalse() throws {
        let root = try tmp()
        defer { try? FileManager.default.removeItem(at: root) }
        try "# skill".write(to: root.appendingPathComponent("CLAUDE.md"), atomically: true, encoding: .utf8)
        let files = scanner.scan(codebase: root)
        #expect(files.allSatisfy { !$0.isGlobal })
    }

    @Test("Codebase identity is path-based")
    func codebaseIdentity() throws {
        let url = URL(fileURLWithPath: "/some/path")
        let c1 = Codebase(url: url, files: [])
        let c2 = Codebase(url: url, files: [SkillFile(provider: .claude, name: "a.md", path: "/some/path/a.md", contents: "", isGlobal: false)])
        #expect(c1 == c2)
        #expect(c1.id == "/some/path")
        #expect(c1.displayName == "path")
    }

    @Test("scanAll runs scans concurrently and returns updated codebases")
    func scanAllUpdatesFiles() async throws {
        let root1 = try tmp()
        let root2 = try tmp()
        defer {
            try? FileManager.default.removeItem(at: root1)
            try? FileManager.default.removeItem(at: root2)
        }
        try "# a".write(to: root1.appendingPathComponent("CLAUDE.md"), atomically: true, encoding: .utf8)
        try "# b".write(to: root2.appendingPathComponent("CLAUDE.md"), atomically: true, encoding: .utf8)

        let codebases = [Codebase(url: root1, files: []), Codebase(url: root2, files: [])]
        let updated = await scanner.scanAll(codebases)

        #expect(updated.count == 2)
        #expect(updated.allSatisfy { !$0.files.isEmpty })
    }
}
