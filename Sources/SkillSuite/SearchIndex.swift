import Foundation

struct SearchResult: Sendable {
    let fileID: String
    let score: Int
}

/// In-memory full-text index over all discovered `SkillFile`s.
///
/// Searches both filename and file contents, case-insensitively.
/// Rebuilt on launch and after every FSEvents rescan.
/// Total corpus for a power user is well under 1MB — in-memory is appropriate.
struct SearchIndex: Sendable {

    // MARK: - Internal State

    private struct Entry: Sendable {
        let fileID: String              // SkillFile.id (== path)
        let nameLowercased: String
        let contentsLowercased: String
    }

    private var entries: [Entry] = []

    // MARK: - Public Interface

    /// Rebuilds the index from the current set of files.
    /// O(n) where n = total character count across all files.
    mutating func build(from files: [SkillFile]) {
        entries = files.map { file in
            Entry(
                fileID: file.id,
                nameLowercased: file.name.lowercased(),
                contentsLowercased: file.contents.lowercased()
            )
        }
    }

    /// Returns scored file IDs (paths) that match `query`.
    ///
    /// An empty query returns all file IDs with score 0 (no filtering).
    /// O(n) scan — acceptable for a sub-1MB corpus.
    func search(query: String) -> [SearchResult] {
        if query.isEmpty {
            return entries.map { SearchResult(fileID: $0.fileID, score: 0) }
        }
        let lowercased = query.lowercased()
        return entries.compactMap { entry in
            let nameMatch = entry.nameLowercased.contains(lowercased) ? 10 : 0
            let contentMatch = entry.contentsLowercased.contains(lowercased) ? 1 : 0
            let score = nameMatch + contentMatch

            guard score > 0 else { return nil }
            return SearchResult(fileID: entry.fileID, score: score)
        }
        .sorted { lhs, rhs in
            if lhs.score == rhs.score {
                return lhs.fileID < rhs.fileID
            }
            return lhs.score > rhs.score
        }
    }
}
