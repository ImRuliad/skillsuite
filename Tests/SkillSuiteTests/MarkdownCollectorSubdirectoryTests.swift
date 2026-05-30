import Testing
import Foundation
@testable import SkillSuite

/// Tests that MarkdownCollector correctly computes the `subdirectory` field (PER-66).
@Suite("MarkdownCollector — subdirectory computation")
struct MarkdownCollectorSubdirectoryTests {

    private func tmp() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func mkdir(_ url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    private func write(_ content: String, to url: URL) throws {
        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    // MARK: - collect(under:)

    @Test("collectUnder_fileDirectlyInRoot_hasEmptySubdirectory")
    func collectUnder_fileDirectlyInRoot_hasEmptySubdirectory() throws {
        let root = try tmp()
        defer { try? FileManager.default.removeItem(at: root) }
        try write("# Instructions", to: root.appendingPathComponent("CLAUDE.md"))

        let files = MarkdownCollector.collect(under: root, provider: .claude, isGlobal: false)
        #expect(files.count == 1)
        #expect(files[0].subdirectory == "")
    }

    @Test("collectUnder_fileOneLevelDeep_hasCorrectSubdirectory")
    func collectUnder_fileOneLevelDeep_hasCorrectSubdirectory() throws {
        let root = try tmp()
        defer { try? FileManager.default.removeItem(at: root) }
        let subdir = root.appendingPathComponent("subdir")
        try mkdir(subdir)
        try write("# File", to: subdir.appendingPathComponent("file.md"))

        let files = MarkdownCollector.collect(under: root, provider: .claude, isGlobal: false)
        #expect(files.count == 1)
        #expect(files[0].subdirectory == "subdir")
    }

    @Test("collectUnder_fileThreeLevelsDeep_hasCorrectSubdirectory")
    func collectUnder_fileThreeLevelsDeep_hasCorrectSubdirectory() throws {
        let root = try tmp()
        defer { try? FileManager.default.removeItem(at: root) }
        let deep = root.appendingPathComponent("a/b/c")
        try mkdir(deep)
        try write("# Deep", to: deep.appendingPathComponent("deep.md"))

        let files = MarkdownCollector.collect(under: root, provider: .claude, isGlobal: false)
        #expect(files.count == 1)
        #expect(files[0].subdirectory == "a/b/c")
    }

    // MARK: - collectFile(at:)

    @Test("collectFile_alwaysHasEmptySubdirectory")
    func collectFile_alwaysHasEmptySubdirectory() throws {
        let root = try tmp()
        defer { try? FileManager.default.removeItem(at: root) }
        let file = root.appendingPathComponent("CLAUDE.md")
        try write("# Root", to: file)

        let files = MarkdownCollector.collectFile(at: file, provider: .claude, isGlobal: false)
        #expect(files.count == 1)
        #expect(files[0].subdirectory == "")
    }

    // MARK: - collectDirectory(_:root:)

    @Test("collectDirectory_withRootParent_hasDirectoryNameAsSubdirectory")
    func collectDirectory_withRootParent_hasDirectoryNameAsSubdirectory() throws {
        let root = try tmp()
        defer { try? FileManager.default.removeItem(at: root) }
        let instructions = root.appendingPathComponent("instructions")
        try mkdir(instructions)
        try write("# Custom", to: instructions.appendingPathComponent("custom.instructions.md"))

        let files = MarkdownCollector.collectDirectory(
            instructions,
            root: root,
            matchingSuffix: ".instructions.md",
            provider: .copilot,
            isGlobal: true
        )
        #expect(files.count == 1)
        #expect(files[0].subdirectory == "instructions")
    }

    // MARK: - Mixed depths

    @Test("collectUnder_twoFilesAtDifferentDepths_eachGetsCorrectSubdirectory")
    func collectUnder_twoFilesAtDifferentDepths_eachGetsCorrectSubdirectory() throws {
        let root = try tmp()
        defer { try? FileManager.default.removeItem(at: root) }
        // File directly at root
        try write("# Root", to: root.appendingPathComponent("root.md"))
        // File one level deep
        let nested = root.appendingPathComponent("nested")
        try mkdir(nested)
        try write("# Nested", to: nested.appendingPathComponent("nested.md"))

        let files = MarkdownCollector.collect(under: root, provider: .claude, isGlobal: false)
        #expect(files.count == 2)

        let rootFile = files.first { $0.name == "root.md" }
        let nestedFile = files.first { $0.name == "nested.md" }
        #expect(rootFile?.subdirectory == "")
        #expect(nestedFile?.subdirectory == "nested")
    }
}
