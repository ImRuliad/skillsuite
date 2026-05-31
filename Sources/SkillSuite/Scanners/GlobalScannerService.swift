import Foundation

/// Owns all global provider scanners and runs them concurrently.
///
/// Results are keyed by `AIProvider` so callers can render per-provider groups.
/// Each scanner runs in its own task — total scan time equals the slowest single scanner,
/// not the sum of all scanners (important for large ~/.claude/ trees).
actor GlobalScannerService {

    // MARK: - Private State

    private let scanners: [any ProviderScanner]

    init() {
        self.scanners = [
            ClaudeScanner(),
            CopilotScanner(),
            CodexScanner(),
            GeminiScanner()
        ]
    }

    init(scanners: [any ProviderScanner]) {
        self.scanners = scanners
    }

    // MARK: - Public Interface

    /// Runs all provider scanners concurrently and returns results keyed by provider.
    ///
    /// Files within each provider are sorted alphabetically by name.
    /// This method never throws — scanners handle their own errors internally.
    func scanAll() async -> [AIProvider: [SkillFile]] {
        await withTaskGroup(of: (AIProvider, [SkillFile]).self) { group in
            for scanner in scanners {
                group.addTask { (scanner.provider, scanner.scan()) }
            }
            var results: [AIProvider: [SkillFile]] = [:]
            for await (provider, files) in group {
                results[provider] = files.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            }
            return results
        }
    }
}
