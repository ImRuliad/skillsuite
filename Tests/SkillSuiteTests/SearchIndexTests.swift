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
        #expect(result == Set(["/tmp/alpha.md", "/tmp/beta.md"]))
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

        #expect(index.search(query: "claude").contains("/tmp/rules.md"))
    }

    @Test("Matches by file contents substring")
    func matchesByContents() {
        var index = SearchIndex()
        let file = makeFile(name: "notes.md", contents: "Always use SOLID principles", path: "/tmp/notes.md")
        index.build(from: [file])

        #expect(index.search(query: "solid").contains("/tmp/notes.md"))
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
        #expect(result.contains("/tmp/one.md"))
        #expect(result.contains("/tmp/swift.md"))
        #expect(!result.contains("/tmp/other.md"))
    }

    @Test("File ID used in results equals SkillFile path")
    func resultIDEqualsPath() {
        var index = SearchIndex()
        let path = "/Users/test/.claude/rules.md"
        let file = makeFile(name: "rules.md", contents: "match me", path: path)
        index.build(from: [file])

        let result = index.search(query: "match me")
        #expect(result.contains(path))
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
