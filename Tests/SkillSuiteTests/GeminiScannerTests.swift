import Testing
import Foundation
@testable import SkillSuite

@Suite("GeminiScanner")
struct GeminiScannerTests {

    @Test("collects files at root and in agents/ subdirectory")
    func collectsNested() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let agents = root.appendingPathComponent("agents")
        try FileManager.default.createDirectory(at: agents, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try "# Root".write(to: root.appendingPathComponent("settings.md"), atomically: true, encoding: .utf8)
        try "# Agent".write(to: agents.appendingPathComponent("my-agent.md"), atomically: true, encoding: .utf8)

        let files = MarkdownCollector.collect(under: root, provider: .gemini, isGlobal: true)
        #expect(files.count == 2)
        #expect(files.allSatisfy { $0.provider == .gemini })
    }

    @Test("returns empty for non-existent directory")
    func missingDirectory() {
        let missing = URL(fileURLWithPath: "/tmp/no-such-\(UUID().uuidString)")
        #expect(MarkdownCollector.collect(under: missing, provider: .gemini, isGlobal: true).isEmpty)
    }
}
