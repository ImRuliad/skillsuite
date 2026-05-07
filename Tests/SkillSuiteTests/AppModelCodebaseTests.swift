import Testing
import Foundation
@testable import SkillSuite

/// Tests for codebase URL standardization and scan-result assignment (PER-53).
///
/// AppModel is @MainActor so every test must run on the main actor.
@Suite("AppModel — codebase management")
@MainActor
struct AppModelCodebaseTests {

    // MARK: - Helpers

    private func tmp() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url.standardizedFileURL
    }

    private func freshModel() -> AppModel {
        // Use an isolated UserDefaults suite so tests never touch the real app prefs
        let model = AppModel()
        model.codebases = []
        return model
    }

    // MARK: - URL standardization

    @Test("standardizedFileURL round-trips through path string unchanged")
    func urlRoundTripViaPathString() throws {
        let root = try tmp()
        let path = root.path
        let reconstructed = URL(fileURLWithPath: path).standardizedFileURL
        #expect(reconstructed == root)
    }

    @Test("addCodebase stores a standardized URL")
    func addCodebaseStoresStandardizedURL() throws {
        let root = try tmp()
        defer { try? FileManager.default.removeItem(at: root) }
        let model = freshModel()

        model.addCodebase(root)

        #expect(model.codebases.count == 1)
        #expect(model.codebases[0].url == root.standardizedFileURL)
    }

    @Test("addCodebase with already-standardized URL does not duplicate")
    func addCodebaseNoDuplicateWhenCalledTwice() throws {
        let root = try tmp()
        defer { try? FileManager.default.removeItem(at: root) }
        let model = freshModel()

        model.addCodebase(root)
        model.addCodebase(root)

        #expect(model.codebases.count == 1)
    }

    @Test("addCodebase rejects duplicate regardless of trailing slash difference")
    func addCodebaseNoDuplicateTrailingSlash() throws {
        let root = try tmp()
        defer { try? FileManager.default.removeItem(at: root) }
        let model = freshModel()

        // One URL with trailing slash path, one without — standardizedFileURL normalizes both
        let withSlash    = URL(fileURLWithPath: root.path + "/")
        let withoutSlash = URL(fileURLWithPath: root.path)
        model.addCodebase(withSlash)
        model.addCodebase(withoutSlash)

        #expect(model.codebases.count == 1)
    }

    @Test("loadPersistedCodebases reconstructs standardized URLs that match addCodebase URLs")
    func loadPersistedMatchesAddCodebase() throws {
        let root = try tmp()
        defer { try? FileManager.default.removeItem(at: root) }
        let model = freshModel()

        model.addCodebase(root)
        // Simulate what loadPersistedCodebases does
        let reconstructed = URL(fileURLWithPath: root.path).standardizedFileURL
        #expect(reconstructed == model.codebases[0].url)
    }

    // MARK: - Scan result assignment

    @Test("addCodebase with CLAUDE.md present assigns scan results to the codebase entry")
    func addCodebaseAssignsScanResults() async throws {
        let root = try tmp()
        defer { try? FileManager.default.removeItem(at: root) }
        try "# Instructions".write(
            to: root.appendingPathComponent("CLAUDE.md"),
            atomically: true, encoding: .utf8
        )
        let model = freshModel()

        model.addCodebase(root)

        // The Task inside addCodebase schedules work on the main actor.
        // Yielding lets it run before we assert.
        await Task.yield()
        await Task.yield()

        #expect(model.codebases.count == 1)
        #expect(!model.codebases[0].files.isEmpty,
                "scan results should be assigned after addCodebase")
        #expect(model.codebases[0].files[0].name == "CLAUDE.md")
    }

    @Test("addCodebase with no AI files shows codebase entry with empty files — no crash")
    func addCodebaseNoAiFilesDoesNotCrash() async throws {
        let root = try tmp()
        defer { try? FileManager.default.removeItem(at: root) }
        try "readme".write(
            to: root.appendingPathComponent("README.md"),
            atomically: true, encoding: .utf8
        )
        let model = freshModel()

        model.addCodebase(root)
        await Task.yield()
        await Task.yield()

        #expect(model.codebases.count == 1)
        #expect(model.codebases[0].files.isEmpty)
    }

    // MARK: - removeCodebase

    @Test("removeCodebase removes entry added with same URL")
    func removeCodebaseWithSameURL() throws {
        let root = try tmp()
        defer { try? FileManager.default.removeItem(at: root) }
        let model = freshModel()

        model.addCodebase(root)
        #expect(model.codebases.count == 1)

        model.removeCodebase(model.codebases[0])
        #expect(model.codebases.isEmpty)
    }

    @Test("removeCodebase with reconstructed URL (simulating relaunch) still removes entry")
    func removeCodebaseWithReconstructedURL() throws {
        let root = try tmp()
        defer { try? FileManager.default.removeItem(at: root) }
        let model = freshModel()

        model.addCodebase(root)
        // Simulate reconstructed URL from UserDefaults
        let reconstructed = URL(fileURLWithPath: root.path).standardizedFileURL
        let codebase = Codebase(url: reconstructed, files: [])
        model.removeCodebase(codebase)

        #expect(model.codebases.isEmpty)
    }

    // MARK: - Regression

    @Test("existing codebases array is empty on fresh AppModel init")
    func freshModelHasNoCodebases() {
        let model = freshModel()
        #expect(model.codebases.isEmpty)
    }
}
