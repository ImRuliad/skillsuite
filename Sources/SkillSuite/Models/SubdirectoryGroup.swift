import Foundation

struct SubdirectoryGroup: Identifiable {
    var id: String { absoluteParentPath }

    let displayName: String
    let subdirectory: String
    let absoluteParentPath: String
    let files: [SkillFile]
}

extension SubdirectoryGroup {
    static func groups(from files: [SkillFile]) -> [SubdirectoryGroup] {
        let filesBySubdirectory = Dictionary(
            grouping: files.filter { !$0.subdirectory.isEmpty },
            by: \.subdirectory
        )

        return filesBySubdirectory.keys.sorted().compactMap { subdirectory in
            guard let groupFiles = filesBySubdirectory[subdirectory] else {
                return nil
            }

            let sortedFiles = groupFiles.sorted {
                if $0.name == $1.name {
                    return $0.path < $1.path
                }
                return $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }

            guard let firstFile = sortedFiles.first else {
                return nil
            }

            return SubdirectoryGroup(
                displayName: URL(fileURLWithPath: subdirectory).lastPathComponent,
                subdirectory: subdirectory,
                absoluteParentPath: URL(fileURLWithPath: firstFile.path).deletingLastPathComponent().path,
                files: sortedFiles
            )
        }
    }
}
