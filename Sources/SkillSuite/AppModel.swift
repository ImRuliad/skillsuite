import Foundation
import Observation

@Observable
@MainActor
final class AppModel {
    var globalFiles: [AIProvider: [SkillFile]] = [:]
    var codebases: [Codebase] = []
    var selectedFile: SkillFile? = nil
    var isLoading = true
    var recentlyAddedFilePaths: Set<String> = []
    var searchQuery: String = ""
    var matchingFileIDs: Set<String> = []
}
