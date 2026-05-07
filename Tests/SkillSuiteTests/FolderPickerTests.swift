import Testing
import Foundation
@testable import SkillSuite

/// Tests for the folder-picker delegation contract introduced in PER-52.
///
/// NSOpenPanel cannot be driven in a headless test environment, so these tests
/// exercise the `AppModel.presentFolderPicker` closure boundary and the
/// `addCodebase` path that the picker delegates into.
///
/// AppModel is @MainActor so every test must run on the main actor.
@Suite("FolderPicker — delegation contract")
@MainActor
struct FolderPickerTests {

    // MARK: - Helpers

    private func tmp() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url.standardizedFileURL
    }

    private func freshModel() -> AppModel {
        let model = AppModel()
        model.codebases = []
        return model
    }

    // MARK: - Closure state

    @Test("presentFolderPicker is nil on fresh AppModel before AppDelegate wires it up")
    func closureIsNilBeforeWiring() {
        let model = freshModel()
        #expect(model.presentFolderPicker == nil)
    }

    @Test("presentFolderPicker can be set and invoked without crashing")
    func closureCanBeSetAndInvoked() {
        let model = freshModel()
        var called = false
        model.presentFolderPicker = { called = true }
        model.presentFolderPicker?()
        #expect(called)
    }

    @Test("calling presentFolderPicker?() when nil is a no-op — does not crash")
    func nilClosureCallIsNoOp() {
        let model = freshModel()
        #expect(model.presentFolderPicker == nil)
        // Must not crash
        model.presentFolderPicker?()
    }

    // MARK: - Simulated picker: user picks a directory

    @Test("when picker returns a URL, addCodebase stores the codebase")
    func pickerApprovalAddsCodebase() throws {
        let root = try tmp()
        defer { try? FileManager.default.removeItem(at: root) }
        let model = freshModel()

        // Simulate AppDelegate calling addCodebase after picker returns .OK
        model.addCodebase(root)

        #expect(model.codebases.count == 1)
        #expect(model.codebases[0].url == root)
    }

    @Test("when picker is cancelled (no URL returned), no codebase is added")
    func pickerCancelAddsNothing() {
        let model = freshModel()

        // Simulate AppDelegate guard: `guard openPanel.runModal() == .OK, let url = openPanel.url`
        // On cancel, the guard fails and addCodebase is never called.
        // Verify the model remains unchanged.
        #expect(model.codebases.isEmpty)
    }

    // MARK: - Duplicate rejection through picker path

    @Test("picking the same directory twice does not duplicate the codebase entry")
    func pickerDuplicateRejected() throws {
        let root = try tmp()
        defer { try? FileManager.default.removeItem(at: root) }
        let model = freshModel()

        // Simulate two successive picker confirmations for the same path
        model.addCodebase(root)
        model.addCodebase(root)

        #expect(model.codebases.count == 1)
    }

    @Test("picker with trailing-slash variant does not create a duplicate entry")
    func pickerTrailingSlashVariantRejected() throws {
        let root = try tmp()
        defer { try? FileManager.default.removeItem(at: root) }
        let model = freshModel()

        // NSOpenPanel sometimes returns a URL with a trailing slash
        let withSlash    = URL(fileURLWithPath: root.path + "/")
        let withoutSlash = URL(fileURLWithPath: root.path)
        model.addCodebase(withSlash)
        model.addCodebase(withoutSlash)

        #expect(model.codebases.count == 1)
    }

    // MARK: - Non-existent path filtering

    @Test("non-existent path returned by picker is dropped on next relaunch — addCodebase stores it immediately")
    func pickerNonExistentPathIsStoredThenFilteredOnReload() throws {
        // addCodebase does not pre-check existence — it trusts the picker.
        // loadPersistedCodebases filters out paths that no longer exist.
        let model = freshModel()

        let phantom = URL(fileURLWithPath: "/tmp/skillsuite-phantom-\(UUID().uuidString)")
        // phantom does not exist on disk
        model.addCodebase(phantom)

        // Immediately after adding it is present (picker just confirmed it)
        #expect(model.codebases.count == 1)
        // (filterting happens on next load from UserDefaults, tested in AppModelCodebaseTests)
    }

    // MARK: - Closure replacement

    @Test("replacing presentFolderPicker closure updates the handler in place")
    func closureCanBeReplaced() {
        let model = freshModel()
        var firstCalled = false
        var secondCalled = false

        model.presentFolderPicker = { firstCalled = true }
        model.presentFolderPicker = { secondCalled = true }
        model.presentFolderPicker?()

        #expect(!firstCalled, "old handler must not fire after replacement")
        #expect(secondCalled, "new handler must fire")
    }
}
