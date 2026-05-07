import Testing
import Foundation
@testable import SkillSuite

/// Extended coverage for CodebaseScannerService (PER-54).
///
/// Covers nested directory structures, multi-provider codebases, edge cases,
/// provider-specific filtering, and scanAll concurrency.
/// Every test uses an isolated temp directory and cleans up with defer.
@Suite("CodebaseScannerService — extended coverage")
struct CodebaseScannerExtendedTests {

    private let scanner = CodebaseScannerService()

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

    // MARK: - Nested directory structures

    @Test("scanFindsSkillMdThreeLevelsDeepInsideClaude")
    func scanFindsSkillMdThreeLevelsDeepInsideClaude() throws {
        let root = try tmp()
        defer { try? FileManager.default.removeItem(at: root) }
        let skill = root.appendingPathComponent(".claude/skills/productivity/pm-planner")
        try mkdir(skill)
        try write("# PM Planner", to: skill.appendingPathComponent("SKILL.md"))

        let files = scanner.scan(codebase: root)
        #expect(files.count == 1)
        #expect(files[0].name == "SKILL.md")
        #expect(files[0].provider == .claude)
        #expect(files[0].path.hasSuffix(".claude/skills/productivity/pm-planner/SKILL.md"))
    }

    @Test("scanFindsAllSkillsAcrossMultipleCategories")
    func scanFindsAllSkillsAcrossMultipleCategories() throws {
        let root = try tmp()
        defer { try? FileManager.default.removeItem(at: root) }
        let prod = root.appendingPathComponent(".claude/skills/productivity/pm-planner")
        let eng  = root.appendingPathComponent(".claude/skills/engineering/diagnose")
        let misc = root.appendingPathComponent(".claude/skills/misc/git-guardrails")
        try [prod, eng, misc].forEach { try mkdir($0) }
        try write("# PM",       to: prod.appendingPathComponent("SKILL.md"))
        try write("# Diagnose", to: eng.appendingPathComponent("SKILL.md"))
        try write("# Git",      to: misc.appendingPathComponent("SKILL.md"))

        let files = scanner.scan(codebase: root)
        #expect(files.count == 3)
        #expect(files.allSatisfy { $0.provider == .claude })
        #expect(files.allSatisfy { $0.name == "SKILL.md" })
        let paths = Set(files.map { $0.path })
        #expect(paths.count == 3) // all three are distinct paths
    }

    @Test("scanFindsFilesInCopilotInstructionsSubdir")
    func scanFindsFilesInCopilotInstructionsSubdir() throws {
        let root = try tmp()
        defer { try? FileManager.default.removeItem(at: root) }
        let subdir = root.appendingPathComponent(".copilot/instructions")
        try mkdir(subdir)
        try write("# Custom", to: subdir.appendingPathComponent("custom.md"))
        // also add the canonical copilot file
        let github = root.appendingPathComponent(".github")
        try mkdir(github)
        try write("# Copilot", to: github.appendingPathComponent("copilot-instructions.md"))

        let files = scanner.scan(codebase: root)
        let copilotFiles = files.filter { $0.provider == .copilot }
        #expect(copilotFiles.count == 2)
        let names = Set(copilotFiles.map { $0.name })
        #expect(names.contains("custom.md"))
        #expect(names.contains("copilot-instructions.md"))
    }

    // MARK: - Multi-provider codebases

    @Test("scanAttributesClaudeFilesToClaudeProvider")
    func scanAttributesClaudeFilesToClaudeProvider() throws {
        let root = try tmp()
        defer { try? FileManager.default.removeItem(at: root) }
        let claude = root.appendingPathComponent(".claude")
        try mkdir(claude)
        try write("# Instructions", to: root.appendingPathComponent("CLAUDE.md"))
        try write("# Settings",     to: claude.appendingPathComponent("settings.md"))

        let files = scanner.scan(codebase: root)
        #expect(files.allSatisfy { $0.provider == .claude })
        #expect(files.count == 2)
    }

    @Test("scanAttributesCopilotFilesToCopilotProvider")
    func scanAttributesCopilotFilesToCopilotProvider() throws {
        let root = try tmp()
        defer { try? FileManager.default.removeItem(at: root) }
        let github = root.appendingPathComponent(".github")
        try mkdir(github)
        try write("# Copilot", to: github.appendingPathComponent("copilot-instructions.md"))

        let files = scanner.scan(codebase: root)
        #expect(files.count == 1)
        #expect(files[0].provider == .copilot)
    }

    @Test("scanHandlesAllFourProvidersSimultaneously")
    func scanHandlesAllFourProvidersSimultaneously() throws {
        let root = try tmp()
        defer { try? FileManager.default.removeItem(at: root) }
        let claude  = root.appendingPathComponent(".claude")
        let copilot = root.appendingPathComponent(".copilot")
        let codex   = root.appendingPathComponent(".codex")
        let gemini  = root.appendingPathComponent(".gemini")
        let github  = root.appendingPathComponent(".github")
        try [claude, copilot, codex, gemini, github].forEach { try mkdir($0) }
        try write("# C",  to: claude.appendingPathComponent("rules.md"))
        try write("# Co", to: copilot.appendingPathComponent("guide.md"))
        try write("# Cx", to: codex.appendingPathComponent("policy.md"))
        try write("# G",  to: gemini.appendingPathComponent("notes.md"))
        try write("# CI", to: github.appendingPathComponent("copilot-instructions.md"))

        let files = scanner.scan(codebase: root)
        #expect(files.filter { $0.provider == .claude  }.count == 1)
        #expect(files.filter { $0.provider == .copilot }.count == 2) // .copilot dir + .github file
        #expect(files.filter { $0.provider == .codex   }.count == 1)
        #expect(files.filter { $0.provider == .gemini  }.count == 1)
    }

    @Test("providerAttributionIsCorrectWhenMultipleProvidersPresent")
    func providerAttributionIsCorrectWhenMultipleProvidersPresent() throws {
        let root = try tmp()
        defer { try? FileManager.default.removeItem(at: root) }
        let claude = root.appendingPathComponent(".claude")
        let gemini = root.appendingPathComponent(".gemini")
        try mkdir(claude)
        try mkdir(gemini)
        try write("# C", to: claude.appendingPathComponent("instructions.md"))
        try write("# G", to: gemini.appendingPathComponent("instructions.md"))

        let files = scanner.scan(codebase: root)
        #expect(files.count == 2)
        let claudeFiles = files.filter { $0.provider == .claude }
        let geminiFiles = files.filter { $0.provider == .gemini }
        #expect(claudeFiles.count == 1)
        #expect(geminiFiles.count == 1)
        // Same filename in different providers — paths must be distinct
        #expect(claudeFiles[0].path != geminiFiles[0].path)
    }

    // MARK: - Edge cases

    @Test("scanReturnsEmptyWhenClaudeDirHasNoMdFiles")
    func scanReturnsEmptyWhenClaudeDirHasNoMdFiles() throws {
        let root = try tmp()
        defer { try? FileManager.default.removeItem(at: root) }
        let claude = root.appendingPathComponent(".claude")
        try mkdir(claude)
        try "{}".write(to: claude.appendingPathComponent("settings.json"), atomically: true, encoding: .utf8)
        try "#!/bin/sh".write(to: claude.appendingPathComponent("hook.sh"), atomically: true, encoding: .utf8)

        let files = scanner.scan(codebase: root)
        #expect(files.isEmpty)
    }

    @Test("scanReturnsEmptyWhenClaudeDirIsEmpty")
    func scanReturnsEmptyWhenClaudeDirIsEmpty() throws {
        let root = try tmp()
        defer { try? FileManager.default.removeItem(at: root) }
        try mkdir(root.appendingPathComponent(".claude"))

        let files = scanner.scan(codebase: root)
        #expect(files.isEmpty)
    }

    @Test("scanSkipsInvalidUtf8FileAndReturnsRest")
    func scanSkipsInvalidUtf8FileAndReturnsRest() throws {
        let root = try tmp()
        defer { try? FileManager.default.removeItem(at: root) }
        let claude = root.appendingPathComponent(".claude")
        try mkdir(claude)
        // Valid file
        try write("# Valid", to: claude.appendingPathComponent("valid.md"))
        // Invalid UTF-8 file (0xFF 0xFE are not valid in a UTF-8 sequence)
        let badBytes = Data([0xFF, 0xFE, 0x00, 0x01])
        try badBytes.write(to: claude.appendingPathComponent("corrupt.md"))

        let files = scanner.scan(codebase: root)
        // corrupt.md must be skipped; valid.md must be returned
        #expect(files.count == 1)
        #expect(files[0].name == "valid.md")
    }

    @Test("scanDeduplicatesClaudeMdInsideClaudeDirVsRootPattern")
    func scanDeduplicatesClaudeMdInsideClaudeDirVsRootPattern() throws {
        let root = try tmp()
        defer { try? FileManager.default.removeItem(at: root) }
        let claude = root.appendingPathComponent(".claude")
        try mkdir(claude)
        // CLAUDE.md inside .claude/ — found by .claude dir scan
        // root CLAUDE.md pattern looks for [root]/CLAUDE.md which does NOT exist here
        try write("# Inner", to: claude.appendingPathComponent("CLAUDE.md"))

        let files = scanner.scan(codebase: root)
        let claudeMdFiles = files.filter { $0.name == "CLAUDE.md" }
        #expect(claudeMdFiles.count == 1)
        #expect(claudeMdFiles[0].path.hasSuffix(".claude/CLAUDE.md"))
    }

    @Test("rootClaudeMdAndClaudeDirMdBothReturned")
    func rootClaudeMdAndClaudeDirMdBothReturned() throws {
        let root = try tmp()
        defer { try? FileManager.default.removeItem(at: root) }
        let claude = root.appendingPathComponent(".claude")
        try mkdir(claude)
        try write("# Root",  to: root.appendingPathComponent("CLAUDE.md"))
        try write("# Inner", to: claude.appendingPathComponent("config.md"))

        let files = scanner.scan(codebase: root)
        #expect(files.count == 2)
        #expect(files.allSatisfy { $0.provider == .claude })
        let names = Set(files.map { $0.name })
        #expect(names == ["CLAUDE.md", "config.md"])
    }

    @Test("scanReturnsEmptyWhenCodebaseRootDoesNotExist")
    func scanReturnsEmptyWhenCodebaseRootDoesNotExist() {
        let nonExistent = URL(fileURLWithPath: "/tmp/skillsuite-nonexistent-\(UUID().uuidString)")
        let files = scanner.scan(codebase: nonExistent)
        #expect(files.isEmpty)
    }

    @Test("scanReturnsEmptyWhenCodebaseRootIsAFile")
    func scanReturnsEmptyWhenCodebaseRootIsAFile() throws {
        let root = try tmp()
        defer { try? FileManager.default.removeItem(at: root) }
        let file = root.appendingPathComponent("some-file.txt")
        try write("contents", to: file)
        // Pass a file path as the codebase root — must not crash, must return empty
        let files = scanner.scan(codebase: file)
        #expect(files.isEmpty)
    }

    @Test("scanFindsMdFileFiveLevelsDeepInsideClaude")
    func scanFindsMdFileFiveLevelsDeepInsideClaude() throws {
        let root = try tmp()
        defer { try? FileManager.default.removeItem(at: root) }
        let deep = root.appendingPathComponent(".claude/a/b/c/d/e")
        try mkdir(deep)
        try write("# Deep", to: deep.appendingPathComponent("deep.md"))

        let files = scanner.scan(codebase: root)
        #expect(files.count == 1)
        #expect(files[0].name == "deep.md")
        #expect(files[0].provider == .claude)
    }

    // MARK: - Provider edge cases

    @Test("scanFindsNestedMdFilesInCopilotDir")
    func scanFindsNestedMdFilesInCopilotDir() throws {
        let root = try tmp()
        defer { try? FileManager.default.removeItem(at: root) }
        let nested = root.appendingPathComponent(".copilot/instructions/team")
        try mkdir(nested)
        try write("# A", to: nested.appendingPathComponent("a.md"))
        try write("# B", to: nested.appendingPathComponent("b.md"))

        let files = scanner.scan(codebase: root)
        let copilotFiles = files.filter { $0.provider == .copilot }
        #expect(copilotFiles.count == 2)
    }

    @Test("scanIgnoresNonMdFilesInCopilotDir")
    func scanIgnoresNonMdFilesInCopilotDir() throws {
        let root = try tmp()
        defer { try? FileManager.default.removeItem(at: root) }
        let copilot = root.appendingPathComponent(".copilot")
        try mkdir(copilot)
        try write("# Guide", to: copilot.appendingPathComponent("guide.md"))
        try "{}".write(to: copilot.appendingPathComponent("config.json"), atomically: true, encoding: .utf8)
        try "#!/bin/sh".write(to: copilot.appendingPathComponent("setup.sh"), atomically: true, encoding: .utf8)

        let files = scanner.scan(codebase: root)
        #expect(files.count == 1)
        #expect(files[0].name == "guide.md")
    }

    @Test("scanIgnoresNonMdFilesInCodexDir")
    func scanIgnoresNonMdFilesInCodexDir() throws {
        let root = try tmp()
        defer { try? FileManager.default.removeItem(at: root) }
        let codex = root.appendingPathComponent(".codex")
        try mkdir(codex)
        try write("# Policy", to: codex.appendingPathComponent("policy.md"))
        try "[config]".write(to: codex.appendingPathComponent("config.toml"), atomically: true, encoding: .utf8)

        let files = scanner.scan(codebase: root)
        #expect(files.count == 1)
        #expect(files[0].name == "policy.md")
        #expect(files[0].provider == .codex)
    }

    @Test("scanIgnoresNonMdFilesInGeminiDir")
    func scanIgnoresNonMdFilesInGeminiDir() throws {
        let root = try tmp()
        defer { try? FileManager.default.removeItem(at: root) }
        let agents = root.appendingPathComponent(".gemini/agents")
        try mkdir(agents)
        try write("# Agent", to: agents.appendingPathComponent("agent.md"))
        try "{}".write(to: agents.appendingPathComponent("agent.json"), atomically: true, encoding: .utf8)

        let files = scanner.scan(codebase: root)
        #expect(files.count == 1)
        #expect(files[0].name == "agent.md")
        #expect(files[0].provider == .gemini)
    }

    // MARK: - scanAll concurrency

    @Test("scanAllReturnsCorrectResultsForTenConcurrentCodebases")
    func scanAllReturnsCorrectResultsForTenConcurrentCodebases() async throws {
        var roots: [URL] = []
        for _ in 0..<10 {
            let root = try tmp()
            try write("# Instructions", to: root.appendingPathComponent("CLAUDE.md"))
            let claude = root.appendingPathComponent(".claude")
            try mkdir(claude)
            try write("# Settings", to: claude.appendingPathComponent("settings.md"))
            roots.append(root)
        }
        defer { roots.forEach { try? FileManager.default.removeItem(at: $0) } }

        let codebases = roots.map { Codebase(url: $0, files: []) }
        let updated = await scanner.scanAll(codebases)

        #expect(updated.count == 10)
        for codebase in updated {
            #expect(codebase.files.count == 2, "each codebase should have CLAUDE.md + settings.md")
            #expect(codebase.files.allSatisfy { $0.provider == .claude })
        }
    }

    @Test("scanAllWithEmptyInputReturnsEmptyArray")
    func scanAllWithEmptyInputReturnsEmptyArray() async {
        let result = await scanner.scanAll([])
        #expect(result.isEmpty)
    }
}
