import Testing
import Foundation
@testable import SkillSuite

@Suite("AppModel expand state")
@MainActor
struct AppModelExpandStateTests {

    @Test("providerExpanded is empty on init — all providers collapsed by default")
    func providerExpandedDefaultsEmpty() {
        let model = AppModel()
        #expect(model.expandState.providerExpanded.isEmpty)
        #expect(model.expandState.providerExpanded[.claude] == nil)
        #expect(model.expandState.providerExpanded[.copilot] == nil)
        #expect(model.expandState.providerExpanded[.codex] == nil)
        #expect(model.expandState.providerExpanded[.gemini] == nil)
    }

    @Test("codebaseExpanded is empty on init — all codebases collapsed by default")
    func codebaseExpandedDefaultsEmpty() {
        let model = AppModel()
        #expect(model.expandState.codebaseExpanded.isEmpty)
        #expect(model.expandState.codebaseExpanded["/some/path"] == nil)
    }

    @Test("setting providerExpanded persists on the model instance")
    func providerExpandedPersists() {
        let model = AppModel()
        model.expandState.providerExpanded[.claude] = true
        #expect(model.expandState.providerExpanded[.claude] == true)
        model.expandState.providerExpanded[.claude] = false
        #expect(model.expandState.providerExpanded[.claude] == false)
    }

    @Test("setting codebaseExpanded persists on the model instance")
    func codebaseExpandedPersists() {
        let model = AppModel()
        let path = "/Users/me/projects/myapp"
        model.expandState.codebaseExpanded[path] = true
        #expect(model.expandState.codebaseExpanded[path] == true)
        model.expandState.codebaseExpanded[path] = false
        #expect(model.expandState.codebaseExpanded[path] == false)
    }

    @Test("each provider has independent expand state")
    func providerExpandedIsIndependent() {
        let model = AppModel()
        model.expandState.providerExpanded[.claude] = true
        #expect(model.expandState.providerExpanded[.claude] == true)
        #expect(model.expandState.providerExpanded[.copilot] == nil)
        #expect(model.expandState.providerExpanded[.gemini] == nil)
    }

    @Test("each codebase has independent expand state")
    func codebaseExpandedIsIndependent() {
        let model = AppModel()
        let pathA = "/projects/a"
        let pathB = "/projects/b"
        model.expandState.codebaseExpanded[pathA] = true
        #expect(model.expandState.codebaseExpanded[pathA] == true)
        #expect(model.expandState.codebaseExpanded[pathB] == nil)
    }
}
