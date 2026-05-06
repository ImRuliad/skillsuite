import Testing
import Foundation
@testable import SkillSuite

@Suite("MarkdownCollector + ClaudeScanner")
struct ClaudeScannerTests {

    // MARK: - Helpers

    private func tmp() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func rm(_ url: URL) { try? FileManager.default.removeItem(at: url) }

    // MARK: - SkillFile identity

    @Test("SkillFile identity is path-based, not content-based")
    func pathBasedIdentity() {
        let f1 = SkillFile(provider: .claude, name: "CLAUDE.md", path: "/a/CLAUDE.md", contents: "v1", isGlobal: true)
        let f2 = SkillFile(provider: .claude, name: "CLAUDE.md", path: "/a/CLAUDE.md", contents: "v2", isGlobal: true)
        #expect(f1 == f2)
        #expect(f1.id == "/a/CLAUDE.md")
    }

    @Test("SkillFiles with different paths are not equal")
    func differentPathsNotEqual() {
        let f1 = SkillFile(provider: .claude, name: "a.md", path: "/a/a.md", contents: "x", isGlobal: true)
        let f2 = SkillFile(provider: .claude, name: "a.md", path: "/b/a.md", contents: "x", isGlobal: true)
        #expect(f1 != f2)
    }

    // MARK: - collect(under:)

    @Test("returns empty for non-existent directory")
    func missingDirectory() {
        let missing = URL(fileURLWithPath: "/tmp/no-such-\(UUID().uuidString)")
        #expect(MarkdownCollector.collect(under: missing, provider: .claude, isGlobal: true).isEmpty)
    }

    @Test("returns empty for empty directory")
    func emptyDirectory() throws {
        let root = try tmp()
        defer { rm(root) }
        #expect(MarkdownCollector.collect(under: root, provider: .claude, isGlobal: true).isEmpty)
    }

    @Test("collects .md files recursively, skips non-.md files")
    func recursiveCollection() throws {
        let root = try tmp()
        defer { rm(root) }
        let sub = root.appendingPathComponent("commands")
        try FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)

        try "# Root".write(to: root.appendingPathComponent("CLAUDE.md"), atomically: true, encoding: .utf8)
        try "# Cmd".write(to: sub.appendingPathComponent("deploy.md"), atomically: true, encoding: .utf8)
        try "ignored".write(to: root.appendingPathComponent("config.json"), atomically: true, encoding: .utf8)
        try "ignored".write(to: sub.appendingPathComponent("notes.txt"), atomically: true, encoding: .utf8)

        let files = MarkdownCollector.collect(under: root, provider: .claude, isGlobal: true)
        #expect(files.count == 2)
        #expect(files.allSatisfy { $0.provider == .claude })
        #expect(files.allSatisfy { $0.isGlobal })
        #expect(files.allSatisfy { $0.id == $0.path })
        #expect(!files.contains(where: { $0.name == "config.json" }))
    }

    @Test("skips files with invalid UTF-8, continues scanning rest")
    func skipsInvalidUTF8() throws {
        let root = try tmp()
        defer { rm(root) }
        try "# valid".write(to: root.appendingPathComponent("valid.md"), atomically: true, encoding: .utf8)
        try Data([0xFF, 0xFE, 0x00]).write(to: root.appendingPathComponent("bad.md"))

        let files = MarkdownCollector.collect(under: root, provider: .claude, isGlobal: true)
        #expect(files.count == 1)
        #expect(files[0].name == "valid.md")
    }
}
