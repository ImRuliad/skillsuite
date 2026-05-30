import Testing
import Foundation
@testable import SkillSuite

/// Tests for the `mergeCodebaseScanResults` behaviour introduced in OPT-98.
///
/// The root cause of the "No AI files found" bug was that `loadAll()` and
/// `rescanAndPublish()` replaced `self.codebases` wholesale with the results
/// of a background scan that had captured a stale snapshot of the array.
/// Any codebase added while the scan was in flight was silently dropped.
///
/// The fix: results are merged field-by-field — only `.files` is updated for
/// entries present in the scan snapshot; entries absent from it are untouched.
///
/// All tests run on the main actor to match AppModel's isolation.
@Suite("AppModel — merge scan results (OPT-98)")
@MainActor
struct AppModelMergeTests {

    // MARK: - Helpers

    private func tmp(withClaudeMd: Bool = false) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        if withClaudeMd {
            try "# Instructions".write(
                to: url.appendingPathComponent("CLAUDE.md"),
                atomically: true, encoding: .utf8
            )
        }
        return url.standardizedFileURL
    }

    private func freshModel() -> AppModel {
        let model = AppModel()
        model.codebases = []
        return model
    }

    // MARK: - Core merge invariant

    @Test("mergeCodebaseScanResults updates files for entries in the scan snapshot")
    func mergeUpdatesFilesForScannedEntries() async throws {
        let root = try tmp(withClaudeMd: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let model = freshModel()

        // Simulate: codebase exists before loadAll starts, gets scanned
        model.codebases = [Codebase(url: root, files: [])]

        // Simulate the result loadAll would receive after scanning
        let scanner = CodebaseScannerService()
        let scanned = await scanner.scanAll(model.codebases)

        // Invoke the merge (normally called by loadAll / rescanAndPublish)
        model.mergeCodebaseScanResults(scanned)

        #expect(model.codebases.count == 1)
        #expect(!model.codebases[0].files.isEmpty,
                "files must be populated after merging scan results")
    }

    @Test("mergeCodebaseScanResults preserves entries absent from the scan snapshot")
    func mergePreservesEntriesNotInSnapshot() throws {
        let old = try tmp()
        let new = try tmp()
        defer {
            try? FileManager.default.removeItem(at: old)
            try? FileManager.default.removeItem(at: new)
        }
        let model = freshModel()

        // Both codebases are in the array
        model.codebases = [
            Codebase(url: old, files: []),
            Codebase(url: new, files: []),
        ]

        // The scan snapshot only knew about `old` — `new` was added after scan started
        let snapshotResults = [Codebase(url: old, files: [])]
        model.mergeCodebaseScanResults(snapshotResults)

        // `new` must still be in the array
        #expect(model.codebases.count == 2)
        #expect(model.codebases.contains(where: { $0.url == new }),
                "codebase added during scan must survive the merge")
    }

    @Test("mergeCodebaseScanResults with empty snapshot leaves codebases unchanged")
    func mergeWithEmptySnapshotIsNoop() throws {
        let root = try tmp()
        defer { try? FileManager.default.removeItem(at: root) }
        let model = freshModel()
        model.codebases = [Codebase(url: root, files: [])]

        // Simulate loadAll that captured [] before the codebase was added
        model.mergeCodebaseScanResults([])

        #expect(model.codebases.count == 1,
                "codebase must not be dropped when merge receives empty snapshot")
    }

    // MARK: - The exact race condition from the bug report

    @Test("codebase added while loadAll scan is in flight is not dropped")
    func codebaseAddedDuringScanIsNotDropped() async throws {
        let existing = try tmp(withClaudeMd: true)
        let added    = try tmp(withClaudeMd: true)
        defer {
            try? FileManager.default.removeItem(at: existing)
            try? FileManager.default.removeItem(at: added)
        }
        let model = freshModel()

        // State before loadAll starts: one pre-existing codebase
        model.codebases = [Codebase(url: existing, files: [])]

        // loadAll captures snapshot and starts scanning
        let scanner = CodebaseScannerService()
        let snapshotForScan = model.codebases
        let scanTask = Task { await scanner.scanAll(snapshotForScan) }

        // While scan is in flight, user adds a second codebase (the race)
        model.addCodebase(added)
        #expect(model.codebases.count == 2, "addCodebase must succeed immediately")

        // Scan completes and loadAll calls merge (not wholesale replace)
        let scanResults = await scanTask.value
        model.mergeCodebaseScanResults(scanResults)

        // Both codebases must still be present
        #expect(model.codebases.count == 2,
                "the codebase added during the scan must not be dropped")
        #expect(model.codebases.contains(where: { $0.url == existing }))
        #expect(model.codebases.contains(where: { $0.url == added }))

        // The pre-existing one must have its files populated from the scan
        let existingEntry = model.codebases.first(where: { $0.url == existing })
        #expect(existingEntry?.files.isEmpty == false,
                "pre-existing codebase must have files after merge")
    }

    @Test("files for codebase added during scan are populated by addCodebase Task")
    func filesForLateAddedCodebaseArePopulatedByAddTask() async throws {
        let root = try tmp(withClaudeMd: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let model = freshModel()

        // Simulate the race: loadAll was scanning [] when user added codebase
        model.addCodebase(root)

        // Scan Task from addCodebase runs
        await Task.yield()
        await Task.yield()

        // Simulate loadAll completing with empty snapshot, then merging
        model.mergeCodebaseScanResults([])  // snapshot was empty — new entry preserved

        #expect(model.codebases.count == 1)
        // Files must be set by the addCodebase Task (merge didn't touch them)
        #expect(!model.codebases[0].files.isEmpty,
                "files set by addCodebase scan Task must survive an empty-snapshot merge")
    }

    // MARK: - Merge does not duplicate entries

    @Test("mergeCodebaseScanResults does not duplicate codebases")
    func mergeDoesNotDuplicate() async throws {
        let root = try tmp(withClaudeMd: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let model = freshModel()
        model.codebases = [Codebase(url: root, files: [])]

        let scanner = CodebaseScannerService()
        let results = await scanner.scanAll(model.codebases)
        model.mergeCodebaseScanResults(results)

        #expect(model.codebases.count == 1, "merge must not add duplicate entries")
    }

    // MARK: - rescanAndPublish uses the same merge

    @Test("rescanAndPublish does not drop codebase that exists in array")
    func rescanAndPublishDoesNotDropExistingCodebase() async throws {
        let root = try tmp(withClaudeMd: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let model = freshModel()
        model.addCodebase(root)

        await Task.yield()
        await Task.yield()

        // Trigger a rescan — must not drop the codebase
        await model.rescanAndPublish()

        #expect(model.codebases.count == 1,
                "rescanAndPublish must not remove existing codebases")
        #expect(!model.codebases[0].files.isEmpty,
                "rescanAndPublish must populate files")
    }
}

