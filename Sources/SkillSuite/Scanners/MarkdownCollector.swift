import Foundation

/// Shared utility for collecting `.md` files from the filesystem.
///
/// All provider scanners delegate file-discovery here, satisfying DRY.
/// Each method is pure — no side effects, no global state.
enum MarkdownCollector {

    // MARK: - Public Interface

    /// Recursively collects all `.md` files under `directory`.
    ///
    /// Gracefully returns `[]` when:
    /// - `directory` does not exist
    /// - `directory` is not accessible
    /// - individual files cannot be decoded as UTF-8 (those files are skipped)
    static func collect(
        under directory: URL,
        provider: AIProvider,
        isGlobal: Bool
    ) -> [SkillFile] {
        guard FileManager.default.fileExists(atPath: directory.path) else { return [] }
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var files: [SkillFile] = []
        for case let url as URL in enumerator {
            guard isMarkdownFile(url),
                  let contents = try? String(contentsOf: url, encoding: .utf8)
            else { continue }
            files.append(makeSkillFile(url: url, contents: contents, provider: provider, isGlobal: isGlobal))
        }
        return files
    }

    /// Collects a single `.md` file at `url`.
    ///
    /// Returns `[]` if the file does not exist, is not `.md`, or cannot be decoded as UTF-8.
    static func collectFile(
        at url: URL,
        provider: AIProvider,
        isGlobal: Bool
    ) -> [SkillFile] {
        guard isMarkdownFile(url),
              FileManager.default.fileExists(atPath: url.path),
              let contents = try? String(contentsOf: url, encoding: .utf8)
        else { return [] }
        return [makeSkillFile(url: url, contents: contents, provider: provider, isGlobal: isGlobal)]
    }

    /// Collects `.md` files from `directory` (non-recursive) whose filename ends with `suffix`.
    ///
    /// Returns `[]` if the directory does not exist or is not accessible.
    static func collectDirectory(
        _ directory: URL,
        matchingSuffix suffix: String,
        provider: AIProvider,
        isGlobal: Bool
    ) -> [SkillFile] {
        guard FileManager.default.fileExists(atPath: directory.path),
              let entries = try? FileManager.default.contentsOfDirectory(
                  at: directory,
                  includingPropertiesForKeys: [.isRegularFileKey]
              )
        else { return [] }

        return entries
            .filter { $0.lastPathComponent.hasSuffix(suffix) }
            .compactMap { url -> SkillFile? in
                guard let contents = try? String(contentsOf: url, encoding: .utf8) else { return nil }
                return makeSkillFile(url: url, contents: contents, provider: provider, isGlobal: isGlobal)
            }
    }

    // MARK: - Private Helpers

    private static func isMarkdownFile(_ url: URL) -> Bool {
        url.pathExtension.lowercased() == "md"
    }

    private static func makeSkillFile(url: URL, contents: String, provider: AIProvider, isGlobal: Bool) -> SkillFile {
        SkillFile(
            provider: provider,
            name: url.lastPathComponent,
            path: url.path,
            contents: contents,
            isGlobal: isGlobal
        )
    }
}
