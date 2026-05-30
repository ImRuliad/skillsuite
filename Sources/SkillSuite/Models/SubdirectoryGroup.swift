import Foundation

/// Represents a folder group of `.md` files that share the same subdirectory.
struct SubdirectoryGroup: Identifiable {
    var id: String { absoluteParentPath }

    /// Last path component of `subdirectory`, e.g. "pm-planner".
    let displayName: String

    /// Full relative path from provider root, e.g. "skills/productivity/pm-planner".
    let subdirectory: String

    /// Absolute path of the parent directory on disk.
    let absoluteParentPath: String

    /// Files in this folder, sorted alphabetically by name.
    let files: [SkillFile]
}

extension SubdirectoryGroup {
    /// Groups nested files by subdirectory and returns groups sorted by subdirectory path.
    static func groups(from files: [SkillFile]) -> [SubdirectoryGroup] {
        let nestedFiles = files.filter { !$0.subdirectory.isEmpty }
        let filesBySubdirectory = Dictionary(grouping: nestedFiles) { $0.subdirectory }

        return filesBySubdirectory.map { subdirectory, groupedFiles in
            let parentPath = URL(fileURLWithPath: groupedFiles[0].path)
                .deletingLastPathComponent()
                .path
            let sortedFiles = groupedFiles.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }

            return SubdirectoryGroup(
                displayName: URL(fileURLWithPath: subdirectory).lastPathComponent,
                subdirectory: subdirectory,
                absoluteParentPath: parentPath,
                files: sortedFiles
            )
        }
        .sorted { $0.subdirectory < $1.subdirectory }
    }
}
