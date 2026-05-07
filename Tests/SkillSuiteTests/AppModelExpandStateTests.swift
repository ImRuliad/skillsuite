import Testing
import Foundation
@testable import SkillSuite

@Suite("AppModel expand state")
@MainActor
struct AppModelExpandStateTests {

    @Test("providerExpanded is empty on init — all providers collapsed by default")
    func providerExpandedDefaultsEmpty() {
        let model = AppModel()
        #expect(model.providerExpanded.isEmpty)
        #expect(model.providerExpanded[.claude] == nil)
        #expect(model.providerExpanded[.copilot] == nil)
        #expect(model.providerExpanded[.codex] == nil)
        #expect(model.providerExpanded[.gemini] == nil)
    }

    @Test("codebaseExpanded is empty on init — all codebases collapsed by default")
    func codebaseExpandedDefaultsEmpty() {
        let model = AppModel()
        #expect(model.codebaseExpanded.isEmpty)
        #expect(model.codebaseExpanded["/some/path"] == nil)
    }

    @Test("setting providerExpanded persists on the model instance")
    func providerExpandedPersists() {
        let model = AppModel()
        model.providerExpanded[.claude] = true
        #expect(model.providerExpanded[.claude] == true)
        model.providerExpanded[.claude] = false
        #expect(model.providerExpanded[.claude] == false)
    }

    @Test("setting codebaseExpanded persists on the model instance")
    func codebaseExpandedPersists() {
        let model = AppModel()
        let path = "/Users/me/projects/myapp"
        model.codebaseExpanded[path] = true
        #expect(model.codebaseExpanded[path] == true)
        model.codebaseExpanded[path] = false
        #expect(model.codebaseExpanded[path] == false)
    }

    @Test("each provider has independent expand state")
    func providerExpandedIsIndependent() {
        let model = AppModel()
        model.providerExpanded[.claude] = true
        #expect(model.providerExpanded[.claude] == true)
        #expect(model.providerExpanded[.copilot] == nil)
        #expect(model.providerExpanded[.gemini] == nil)
    }

    @Test("each codebase has independent expand state")
    func codebaseExpandedIsIndependent() {
        let model = AppModel()
        let pathA = "/projects/a"
        let pathB = "/projects/b"
        model.codebaseExpanded[pathA] = true
        #expect(model.codebaseExpanded[pathA] == true)
        #expect(model.codebaseExpanded[pathB] == nil)
    }
}
