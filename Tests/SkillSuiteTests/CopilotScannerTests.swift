import Testing
import Foundation
@testable import SkillSuite

@Suite("CopilotScanner")
struct CopilotScannerTests {

    private func tmp() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test("collectFile returns file when it exists")
    func collectsPrimaryFile() throws {
        let root = try tmp()
        defer { try? FileManager.default.removeItem(at: root) }
        try "# Instructions".write(to: root.appendingPathComponent("copilot-instructions.md"), atomically: true, encoding: .utf8)
        let files = MarkdownCollector.collectFile(at: root.appendingPathComponent("copilot-instructions.md"), provider: .copilot, isGlobal: true)
        #expect(files.count == 1)
        #expect(files[0].name == "copilot-instructions.md")
        #expect(files[0].provider == .copilot)
    }

    @Test("collectFile returns empty for missing file")
    func missingFile() {
        let url = URL(fileURLWithPath: "/tmp/no-\(UUID().uuidString).md")
        #expect(MarkdownCollector.collectFile(at: url, provider: .copilot, isGlobal: true).isEmpty)
    }

    @Test("collectDirectory matches .instructions.md suffix, skips others")
    func suffixFilter() throws {
        let root = try tmp()
        defer { try? FileManager.default.removeItem(at: root) }
        try "# A".write(to: root.appendingPathComponent("a.instructions.md"), atomically: true, encoding: .utf8)
        try "# B".write(to: root.appendingPathComponent("b.instructions.md"), atomically: true, encoding: .utf8)
        try "# Skip".write(to: root.appendingPathComponent("skip.md"), atomically: true, encoding: .utf8)

        let files = MarkdownCollector.collectDirectory(root, root: root, matchingSuffix: ".instructions.md", provider: .copilot, isGlobal: true)
        #expect(files.count == 2)
        #expect(!files.contains(where: { $0.name == "skip.md" }))
    }

    @Test("collectDirectory returns empty for missing directory")
    func missingDirectory() {
        let missing = URL(fileURLWithPath: "/tmp/no-such-dir-\(UUID().uuidString)")
        #expect(MarkdownCollector.collectDirectory(missing, root: missing, matchingSuffix: ".instructions.md", provider: .copilot, isGlobal: true).isEmpty)
    }
}
