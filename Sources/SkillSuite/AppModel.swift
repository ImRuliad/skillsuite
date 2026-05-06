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

    // MARK: - File Watching

    /// Paths of files added since the last rescan — used to drive the new-file highlight animation.
    var recentlyAddedFilePaths: Set<String> = []

    // MARK: - Search

    var searchQuery: String = ""
    var matchingFileIDs: Set<String> = []

    // MARK: - Services

    private let globalScanner = GlobalScannerService()
    private let codebaseScanner = CodebaseScannerService()
    private var index = SearchIndex()

    // MARK: - UserDefaults Persistence

    private let kCodebasePaths = "registeredCodebasePaths"

    // MARK: - Initialisation

    init() {
        loadPersistedCodebases()
    }

    // MARK: - Scanning

    /// Performs the initial scan on launch. Call once from the app entry point.
    func loadAll() async {
        isLoading = true
        async let global = globalScanner.scanAll()
        async let codebaseResults = codebaseScanner.scanAll(codebases)
        let (newGlobal, newCodebases) = await (global, codebaseResults)
        globalFiles = newGlobal
        codebases = newCodebases
        rebuildIndex()
        isLoading = false
    }

    /// Re-scans all paths (triggered by FileWatcher events).
    ///
    /// Detects newly added files for highlight animation.
    /// Clears `selectedFile` if its path no longer exists after the rescan.
    func rescanAndPublish() async {
        let existingPaths = allFilePaths()
        async let newGlobal = globalScanner.scanAll()
        async let newCodebases = codebaseScanner.scanAll(codebases)
        let (updatedGlobal, updatedCodebases) = await (newGlobal, newCodebases)

        let newPaths = Set(updatedGlobal.values.flatMap { $0 }.map { $0.path }
            + updatedCodebases.flatMap { $0.files }.map { $0.path })
        let added = newPaths.subtracting(existingPaths)

        globalFiles = updatedGlobal
        codebases = updatedCodebases

        // Clear selection if selected file was deleted
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

    /// Opens a native folder picker and registers the selected folder.
    func presentFolderPicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Add Codebase"
        panel.message = "Select a project folder to scan for AI instruction files"

        guard panel.runModal() == .OK, let url = panel.url else { return }
        addCodebase(url)
    }

    func addCodebase(_ url: URL) {
        guard !codebases.contains(where: { $0.url == url }) else { return }
        let codebase = Codebase(url: url, files: [])
        codebases.append(codebase)
        persistCodebases()
        Task { @MainActor in
            let scanned = codebaseScanner.scan(codebase: url)
            if let idx = codebases.firstIndex(where: { $0.url == url }) {
                codebases[idx].files = scanned
                rebuildIndex()
            }
        }
    }

    func removeCodebase(_ codebase: Codebase) {
        codebases.removeAll { $0.url == codebase.url }
        persistCodebases()
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

    // MARK: - Persistence

    private func persistCodebases() {
        UserDefaults.standard.set(
            codebases.map { $0.url.path },
            forKey: kCodebasePaths
        )
    }

    private func loadPersistedCodebases() {
        let saved = UserDefaults.standard.stringArray(forKey: kCodebasePaths) ?? []
        codebases = saved
            .compactMap { URL(fileURLWithPath: $0) }
            .filter { FileManager.default.fileExists(atPath: $0.path) }
            .map { Codebase(url: $0, files: []) }
    }

    // MARK: - Helpers

    func watchedPaths() -> [String] {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let globalPaths = [".claude", ".copilot", ".codex", ".gemini"].map { "\(home)/\($0)" }
        let localPaths = codebases.map { $0.url.path }
        return globalPaths + localPaths
    }

    private func allFilePaths() -> Set<String> {
        let globalPaths = globalFiles.values.flatMap { $0 }.map { $0.path }
        let codebasePaths = codebases.flatMap { $0.files }.map { $0.path }
        return Set(globalPaths + codebasePaths)
    }
}
