import Foundation
import Observation
import AppKit

/// Central state container for the SkillSuite app.
///
/// Owned by `SkillSuiteApp` and injected into the view hierarchy via `.environment()`.
/// All mutations happen on `MainActor` — async background work publishes results here.
@Observable
@MainActor
final class AppModel {

    // MARK: - Scan Results

    /// Global provider files keyed by provider. Empty until `loadAll()` completes.
    var globalFiles: [AIProvider: [SkillFile]] = [:]

    /// User-registered codebase folders with their scanned files.
    var codebases: [Codebase] = []

    // MARK: - UI State

    var selectedFile: SkillFile? = nil
    var isLoading = true

    /// Set by AppDelegate so SwiftUI views can request the folder picker
    /// without needing a direct reference to AppDelegate.
    var presentFolderPicker: (() -> Void)?

    /// Session-scoped expand state for provider groups. Absent key = collapsed.
    /// Not persisted — resets to all-collapsed on every app launch.
    var providerExpanded: [AIProvider: Bool] = [:]

    /// Session-scoped expand state for codebase groups, keyed by `url.path`. Absent key = collapsed.
    /// Not persisted — resets to all-collapsed on every app launch.
    var codebaseExpanded: [String: Bool] = [:]

    /// Session-scoped expand state for subdirectory groups, keyed by absolute parent path.
    /// Not persisted — resets to all-collapsed on every app launch.
    var subdirectoryExpanded: [String: Bool] = [:]

    // MARK: - File Watching

    /// Paths of files added since the last rescan — drives the new-file highlight animation.
    var recentlyAddedFilePaths: Set<String> = []

    // MARK: - Search

    var searchQuery: String = ""
    var matchingFileIDs: Set<String> = []

    // MARK: - Services (private)

    private let globalScanner = GlobalScannerService()
    private let codebaseScanner = CodebaseScannerService()
    private var index = SearchIndex()
    private let watcher = FileWatcher()

    // MARK: - UserDefaults

    private let kCodebasePaths = "registeredCodebasePaths"

    // MARK: - Init

    init() {
        loadPersistedCodebases()
    }

    // MARK: - Scanning

    /// Performs the initial scan on app launch. Starts file watching after completion.
    func loadAll() async {
        isLoading = true
        async let global = globalScanner.scanAll()
        async let codebaseResults = codebaseScanner.scanAll(codebases)
        let (newGlobal, newCodebases) = await (global, codebaseResults)
        globalFiles = newGlobal
        mergeCodebaseScanResults(newCodebases)
        rebuildIndex()
        isLoading = false
        startWatching()
    }

    /// Re-scans all paths when `FileWatcher` fires. Detects new files for highlight animation.
    func rescanAndPublish() async {
        let existingPaths = allFilePaths()
        async let newGlobal = globalScanner.scanAll()
        async let newCodebases = codebaseScanner.scanAll(codebases)
        let (updatedGlobal, updatedCodebases) = await (newGlobal, newCodebases)

        let newPaths = Set(
            updatedGlobal.values.flatMap { $0 }.map { $0.path } +
            updatedCodebases.flatMap { $0.files }.map { $0.path }
        )
        let added = newPaths.subtracting(existingPaths)

        globalFiles = updatedGlobal
        mergeCodebaseScanResults(updatedCodebases)

        // Clear selection if selected file was deleted from disk
        if let selected = selectedFile, !newPaths.contains(selected.path) {
            selectedFile = nil
        }

        recentlyAddedFilePaths = added
        rebuildIndex()

        // Clear highlight after 3 seconds
        let pathsToClear = added
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            recentlyAddedFilePaths.subtract(pathsToClear)
        }
    }

    // MARK: - Codebase Management

    func addCodebase(_ url: URL) {
        let canonical = url.standardizedFileURL
        guard !codebases.contains(where: { $0.url == canonical }) else { return }
        codebases.append(Codebase(url: canonical, files: []))
        persistCodebases()
        restartWatching()
        Task { @MainActor in
            let scanned = self.codebaseScanner.scan(codebase: canonical)
            if let idx = self.codebases.firstIndex(where: { $0.url == canonical }) {
                self.codebases[idx].files = scanned
                if !scanned.isEmpty {
                    self.codebaseExpanded[canonical.path] = true
                }
                self.rebuildIndex()
            }
        }
    }

    /// Merges scan results from a background scan into `codebases` without
    /// discarding entries that were added while the scan was in flight.
    ///
    /// A background scan captures a snapshot of `codebases` at start time.
    /// By the time results arrive, `addCodebase()` may have appended new entries.
    /// Replacing `codebases` wholesale would delete those entries. This method
    /// only updates the `.files` of entries that appear in `scanned`; any entry
    /// in `codebases` that is absent from `scanned` is left untouched.
    func mergeCodebaseScanResults(_ scanned: [Codebase]) {
        for updated in scanned {
            if let idx = codebases.firstIndex(where: { $0.url == updated.url }) {
                codebases[idx].files = updated.files
            }
        }
    }

    func removeCodebase(_ codebase: Codebase) {
        codebases.removeAll { $0.url == codebase.url }
        persistCodebases()
        restartWatching()
        rebuildIndex()
    }

    // MARK: - Search

    func rebuildIndex() {
        let all = globalFiles.values.flatMap { $0 } + codebases.flatMap { $0.files }
        index.build(from: all)
        updateMatches()
    }

    func updateMatches() {
        matchingFileIDs = index.search(query: searchQuery)
    }

    // MARK: - File Watching

    private func startWatching() {
        watcher.onChange = { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                await self.rescanAndPublish()
            }
        }
        watcher.start(paths: watchedPaths())
    }

    private func restartWatching() {
        watcher.start(paths: watchedPaths()) // FileWatcher.start() calls stop() internally
    }

    func watchedPaths() -> [String] {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let globalPaths = [".claude", ".copilot", ".codex", ".gemini"].map { "\(home)/\($0)" }
        return globalPaths + codebases.map { $0.url.path }
    }

    // MARK: - Persistence

    private func persistCodebases() {
        UserDefaults.standard.set(codebases.map { $0.url.path }, forKey: kCodebasePaths)
    }

    private func loadPersistedCodebases() {
        let saved = UserDefaults.standard.stringArray(forKey: kCodebasePaths) ?? []
        codebases = saved
            .compactMap { URL(fileURLWithPath: $0).standardizedFileURL }
            .filter { FileManager.default.fileExists(atPath: $0.path) }
            .map { Codebase(url: $0, files: []) }
    }

    // MARK: - Helpers

    private func allFilePaths() -> Set<String> {
        Set(
            globalFiles.values.flatMap { $0 }.map { $0.path } +
            codebases.flatMap { $0.files }.map { $0.path }
        )
    }
}
