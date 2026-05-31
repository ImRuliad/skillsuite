import Testing
@testable import SkillSuite

@Suite("ExpandStateModel")
@MainActor
struct ExpandStateModelTests {

    @Test("init starts with all expand dictionaries empty")
    func initStartsEmpty() {
        let state = ExpandStateModel()

        #expect(state.providerExpanded.isEmpty)
        #expect(state.codebaseExpanded.isEmpty)
        #expect(state.subdirectoryExpanded.isEmpty)
    }

    @Test("provider expand state can be set")
    func setProvider() {
        var state = ExpandStateModel()

        state.providerExpanded[.claude] = true

        #expect(state.providerExpanded[.claude] == true)
    }

    @Test("codebase expand state can be set")
    func setCodebase() {
        var state = ExpandStateModel()
        let path = "/Users/me/project"

        state.codebaseExpanded[path] = true

        #expect(state.codebaseExpanded[path] == true)
    }

    @Test("subdirectory expand state can be set")
    func setSubdirectory() {
        var state = ExpandStateModel()
        let path = "/Users/me/project/.claude/skills"

        state.subdirectoryExpanded[path] = true

        #expect(state.subdirectoryExpanded[path] == true)
    }

    @Test("search override expands provider binding when a match exists")
    func searchOverrideExpandsProviderBinding() {
        let model = AppModel()
        model.searchQuery = "claude"

        let binding = model.providerBinding(for: .claude, hasMatch: true)

        #expect(binding.wrappedValue == true)
    }

    @Test("search override does not persist after search clears")
    func searchOverrideDoesNotPersistAfterClear() {
        let model = AppModel()
        model.expandState.providerExpanded[.claude] = false
        model.searchQuery = "claude"

        #expect(model.providerBinding(for: .claude, hasMatch: true).wrappedValue == true)

        model.searchQuery = ""

        #expect(model.providerBinding(for: .claude, hasMatch: true).wrappedValue == false)
    }

    @Test("binding writes persist when search is empty")
    func bindingWritesPersistWhenSearchIsEmpty() {
        let model = AppModel()
        let path = "/tmp/project/.claude"
        let binding = model.subdirectoryBinding(for: path, hasMatch: false)

        binding.wrappedValue = true

        #expect(model.expandState.subdirectoryExpanded[path] == true)
    }
}
