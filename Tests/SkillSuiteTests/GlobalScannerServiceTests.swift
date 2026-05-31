import Testing
@testable import SkillSuite

@Suite("GlobalScannerService")
struct GlobalScannerServiceTests {

    private struct MockProviderScanner: ProviderScanner {
        let provider: AIProvider
        let files: [SkillFile]

        func scan() -> [SkillFile] {
            files
        }
    }

    private func file(_ name: String, provider: AIProvider) -> SkillFile {
        SkillFile(
            provider: provider,
            name: name,
            path: "/tmp/\(provider.rawValue)/\(name)",
            contents: "# \(name)",
            isGlobal: true
        )
    }

    @Test("four scanners merge all returned files")
    func fourScannersMergeAllFiles() async {
        let service = GlobalScannerService(scanners: [
            MockProviderScanner(provider: .claude, files: [file("claude-a.md", provider: .claude), file("claude-b.md", provider: .claude)]),
            MockProviderScanner(provider: .copilot, files: [file("copilot.md", provider: .copilot)]),
            MockProviderScanner(provider: .codex, files: [file("codex-a.md", provider: .codex), file("codex-b.md", provider: .codex), file("codex-c.md", provider: .codex)]),
            MockProviderScanner(provider: .gemini, files: [file("gemini.md", provider: .gemini)])
        ])

        let results = await service.scanAll()
        let mergedCount = results.values.reduce(0) { $0 + $1.count }

        #expect(mergedCount == 7)
    }

    @Test("one empty scanner preserves other provider results")
    func emptyScannerPreservesOtherProviders() async {
        let service = GlobalScannerService(scanners: [
            MockProviderScanner(provider: .claude, files: [file("claude.md", provider: .claude)]),
            MockProviderScanner(provider: .copilot, files: []),
            MockProviderScanner(provider: .codex, files: [file("codex.md", provider: .codex)]),
            MockProviderScanner(provider: .gemini, files: [file("gemini.md", provider: .gemini)])
        ])

        let results = await service.scanAll()

        #expect(results[.claude]?.count == 1)
        #expect(results[.copilot]?.isEmpty == true)
        #expect(results[.codex]?.count == 1)
        #expect(results[.gemini]?.count == 1)
    }

    @Test("results are keyed by scanner provider")
    func resultsKeyedByProvider() async {
        let service = GlobalScannerService(scanners: [
            MockProviderScanner(provider: .claude, files: [file("claude.md", provider: .claude)]),
            MockProviderScanner(provider: .copilot, files: [file("copilot.md", provider: .copilot)])
        ])

        let results = await service.scanAll()

        #expect(results[.claude]?.first?.provider == .claude)
        #expect(results[.copilot]?.first?.provider == .copilot)
        #expect(results[.codex] == nil)
    }

    @Test("files are sorted alphabetically within provider")
    func filesSortedWithinProvider() async {
        let service = GlobalScannerService(scanners: [
            MockProviderScanner(provider: .claude, files: [
                file("zeta.md", provider: .claude),
                file("alpha.md", provider: .claude),
                file("Beta.md", provider: .claude)
            ])
        ])

        let results = await service.scanAll()
        let names = results[.claude]?.map(\.name)

        #expect(names == ["alpha.md", "Beta.md", "zeta.md"])
    }

    @Test("repeated scanAll calls are consistent")
    func repeatedScansAreConsistent() async {
        let service = GlobalScannerService(scanners: [
            MockProviderScanner(provider: .claude, files: [file("claude.md", provider: .claude)]),
            MockProviderScanner(provider: .gemini, files: [file("gemini.md", provider: .gemini)])
        ])

        let first = await service.scanAll()
        let second = await service.scanAll()

        #expect(first == second)
    }
}
