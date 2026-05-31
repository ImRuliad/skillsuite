import Testing
@testable import SkillSuite

@Suite("SearchIndex")
struct SearchIndexTests {

    // MARK: - Helpers

    private func makeFile(
        name: String,
        contents: String,
        path: String? = nil,
        provider: AIProvider = .claude
    ) -> SkillFile {
        SkillFile(
            provider: provider,
            name: name,
            path: path ?? "/tmp/\(name)",
            contents: contents,
            isGlobal: true
        )
    }

    private func resultIDs(_ results: [SearchResult]) -> Set<String> {
        Set(results.map { $0.fileID })
    }

    private func resultScore(for fileID: String, in results: [SearchResult]) -> Int? {
        results.first { $0.fileID == fileID }?.score
    }

    // MARK: - build()

    @Test("Empty build yields empty search results")
    func emptyBuild() {
        var index = SearchIndex()
        index.build(from: [])
        #expect(index.search(query: "anything").isEmpty)
    }

    @Test("Build replaces a previous index")
    func buildReplacesIndex() {
        var index = SearchIndex()
        index.build(from: [makeFile(name: "old.md", contents: "old content")])
        index.build(from: [makeFile(name: "new.md", contents: "new content")])

        #expect(!index.search(query: "new").isEmpty)
        #expect(index.search(query: "old").isEmpty)
    }

    // MARK: - search() — empty query

    @Test("Empty query returns all file IDs")
    func emptyQueryReturnsAll() {
        var index = SearchIndex()
        let files = [
            makeFile(name: "alpha.md", contents: "a", path: "/tmp/alpha.md"),
            makeFile(name: "beta.md",  contents: "b", path: "/tmp/beta.md"),
        ]
        index.build(from: files)

        let result = index.search(query: "")
        #expect(resultIDs(result) == Set(["/tmp/alpha.md", "/tmp/beta.md"]))
        #expect(result.allSatisfy { $0.score == 0 })
    }

    @Test("Empty query on empty index returns empty set")
    func emptyQueryEmptyIndex() {
        var index = SearchIndex()
        index.build(from: [])
        #expect(index.search(query: "").isEmpty)
    }

    // MARK: - search() — matching

    @Test("Matches by filename substring")
    func matchesByFilename() {
        var index = SearchIndex()
        let file = makeFile(name: "my-claude-rules.md", contents: "", path: "/tmp/rules.md")
        index.build(from: [file])

        #expect(resultIDs(index.search(query: "claude")).contains("/tmp/rules.md"))
    }

    @Test("Matches by file contents substring")
    func matchesByContents() {
        var index = SearchIndex()
        let file = makeFile(name: "notes.md", contents: "Always use SOLID principles", path: "/tmp/notes.md")
        index.build(from: [file])

        #expect(resultIDs(index.search(query: "solid")).contains("/tmp/notes.md"))
    }

    @Test("Filename-only match scores 10")
    func filenameOnlyMatchScoresTen() {
        var index = SearchIndex()
        let file = makeFile(name: "claude-rules.md", contents: "unrelated", path: "/tmp/name.md")
        index.build(from: [file])

        let result = index.search(query: "rules")
        #expect(resultScore(for: "/tmp/name.md", in: result) == 10)
    }

    @Test("Content-only match scores 1")
    func contentOnlyMatchScoresOne() {
        var index = SearchIndex()
        let file = makeFile(name: "notes.md", contents: "Always use SOLID principles", path: "/tmp/content.md")
        index.build(from: [file])

        let result = index.search(query: "solid")
        #expect(resultScore(for: "/tmp/content.md", in: result) == 1)
    }

    @Test("Name and content match scores 11 and ranks first")
    func nameAndContentMatchScoresElevenAndRanksFirst() {
        var index = SearchIndex()
        let files = [
            makeFile(name: "swift-rules.md", contents: "swift guidance", path: "/tmp/both.md"),
            makeFile(name: "notes.md", contents: "swift guidance", path: "/tmp/content.md"),
        ]
        index.build(from: files)

        let result = index.search(query: "swift")
        #expect(resultScore(for: "/tmp/both.md", in: result) == 11)
        #expect(resultScore(for: "/tmp/content.md", in: result) == 1)
        #expect(result.first?.fileID == "/tmp/both.md")
    }

    @Test("Search is case-insensitive for query")
    func caseInsensitiveQuery() {
        var index = SearchIndex()
        let file = makeFile(name: "UPPER.md", contents: "MixedCase Content", path: "/tmp/upper.md")
        index.build(from: [file])

        #expect(!index.search(query: "mixedcase").isEmpty)
        #expect(!index.search(query: "MIXEDCASE").isEmpty)
        #expect(!index.search(query: "MixedCase").isEmpty)
    }

    @Test("Search is case-insensitive for indexed name")
    func caseInsensitiveName() {
        var index = SearchIndex()
        let file = makeFile(name: "Claude-Instructions.md", contents: "", path: "/tmp/claude.md")
        index.build(from: [file])

        #expect(!index.search(query: "CLAUDE").isEmpty)
        #expect(!index.search(query: "claude").isEmpty)
    }

    @Test("Non-matching query returns empty set")
    func noMatch() {
        var index = SearchIndex()
        let file = makeFile(name: "alpha.md", contents: "hello world", path: "/tmp/alpha.md")
        index.build(from: [file])

        #expect(index.search(query: "zzznomatch").isEmpty)
    }

    @Test("Returns multiple matching IDs")
    func multipleMatches() {
        var index = SearchIndex()
        let files = [
            makeFile(name: "one.md",   contents: "swift rules", path: "/tmp/one.md"),
            makeFile(name: "swift.md", contents: "other stuff",  path: "/tmp/swift.md"),
            makeFile(name: "other.md", contents: "unrelated",    path: "/tmp/other.md"),
        ]
        index.build(from: files)

        let result = index.search(query: "swift")
        let ids = resultIDs(result)
        #expect(ids.contains("/tmp/one.md"))
        #expect(ids.contains("/tmp/swift.md"))
        #expect(!ids.contains("/tmp/other.md"))
    }

    @Test("File ID used in results equals SkillFile path")
    func resultIDEqualsPath() {
        var index = SearchIndex()
        let path = "/Users/test/.claude/rules.md"
        let file = makeFile(name: "rules.md", contents: "match me", path: path)
        index.build(from: [file])

        let result = index.search(query: "match me")
        #expect(resultIDs(result).contains(path))
    }

    @Test("Files from different providers are all indexed")
    func multipleProviders() {
        var index = SearchIndex()
        let files = [
            makeFile(name: "claude.md",  contents: "claude content",  path: "/tmp/claude.md",  provider: .claude),
            makeFile(name: "copilot.md", contents: "copilot content", path: "/tmp/copilot.md", provider: .copilot),
        ]
        index.build(from: files)

        #expect(index.search(query: "content").count == 2)
    }
}
