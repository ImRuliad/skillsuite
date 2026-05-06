import Testing
import Foundation
@testable import SkillSuite

@Suite("CodexScanner")
struct CodexScannerTests {

    @Test("ignores config.toml and non-.md files, collects .md files")
    func ignoresNonMarkdown() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try "key = value".write(to: root.appendingPathComponent("config.toml"), atomically: true, encoding: .utf8)
        try "# skill".write(to: root.appendingPathComponent("notes.md"), atomically: true, encoding: .utf8)

        let files = MarkdownCollector.collect(under: root, provider: .codex, isGlobal: true)
        #expect(files.count == 1)
        #expect(files[0].name == "notes.md")
        #expect(!files.contains(where: { $0.name == "config.toml" }))
    }

    @Test("returns empty when directory exists but has only toml files")
    func onlyTomlReturnsEmpty() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try "key = value".write(to: root.appendingPathComponent("config.toml"), atomically: true, encoding: .utf8)

        let files = MarkdownCollector.collect(under: root, provider: .codex, isGlobal: true)
        #expect(files.isEmpty)
    }
}
