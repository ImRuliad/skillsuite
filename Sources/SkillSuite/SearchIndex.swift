import Foundation

/// In-memory full-text index over all discovered `SkillFile`s.
///
/// Searches both filename and file contents, case-insensitively.
/// Rebuilt on launch and after every FSEvents rescan.
/// Total corpus for a power user is well under 1MB — in-memory is appropriate.
struct SearchIndex: Sendable {

    // MARK: - Internal State

    private struct Entry: Sendable {
        let fileID: String          // SkillFile.id (== path)
        let searchable: String      // lowercased name + " " + lowercased contents
    }

    private var entries: [Entry] = []

    // MARK: - Public Interface

    /// Rebuilds the index from the current set of files.
    /// O(n) where n = total character count across all files.
    mutating func build(from files: [SkillFile]) {
        entries = files.map { file in
            Entry(
                fileID: file.id,
                searchable: (file.name + " " + file.contents).lowercased()
            )
        }
    }

    /// Returns the set of file IDs (paths) that match `query`.
    ///
    /// An empty query returns all file IDs (no filtering).
    /// O(n) scan — acceptable for a sub-1MB corpus.
    func search(query: String) -> Set<String> {
        if query.isEmpty {
            return Set(entries.map { $0.fileID })
        }
        let lowercased = query.lowercased()
        return Set(entries.filter { $0.searchable.contains(lowercased) }.map { $0.fileID })
    }
}
