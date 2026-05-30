import Testing
import Foundation
@testable import SkillSuite

@Suite("SubdirectoryGroup.groups(from:)")
struct SubdirectoryGroupingTests {

    private func file(path: String, subdirectory: String) -> SkillFile {
        SkillFile(provider: .claude, name: URL(fileURLWithPath: path).lastPathComponent,
                  path: path, contents: "", isGlobal: false, subdirectory: subdirectory)
    }

    @Test("empty input returns empty groups")
    func emptyInput() {
        #expect(SubdirectoryGroup.groups(from: []).isEmpty)
    }

    @Test("all root files returns empty groups")
    func allRootFiles() {
        let files = [
            file(path: "/root/a.md", subdirectory: ""),
            file(path: "/root/b.md", subdirectory: "")
        ]
        #expect(SubdirectoryGroup.groups(from: files).isEmpty)
    }

    @Test("all files in one subdir returns one group")
    func oneGroup() {
        let files = [
            file(path: "/root/sub/a.md", subdirectory: "sub"),
            file(path: "/root/sub/b.md", subdirectory: "sub"),
            file(path: "/root/sub/c.md", subdirectory: "sub")
        ]
        let groups = SubdirectoryGroup.groups(from: files)
        #expect(groups.count == 1)
        #expect(groups[0].files.count == 3)
    }

    @Test("files in two subdirs returns two groups sorted by subdirectory")
    func twoGroupsSorted() {
        let files = [
            file(path: "/root/beta/a.md", subdirectory: "beta"),
            file(path: "/root/alpha/b.md", subdirectory: "alpha")
        ]
        let groups = SubdirectoryGroup.groups(from: files)
        #expect(groups.count == 2)
        #expect(groups[0].subdirectory < groups[1].subdirectory)
    }

    @Test("mixed root and subdir: root files excluded from groups")
    func rootFilesExcluded() {
        let files = [
            file(path: "/root/CLAUDE.md", subdirectory: ""),
            file(path: "/root/sub/a.md", subdirectory: "sub")
        ]
        let groups = SubdirectoryGroup.groups(from: files)
        #expect(groups.count == 1)
        #expect(!groups[0].files.contains(where: { $0.subdirectory.isEmpty }))
    }

    @Test("displayName is last path component of subdirectory")
    func displayName() {
        let files = [
            file(path: "/root/skills/productivity/pm-planner/SKILL.md",
                 subdirectory: "skills/productivity/pm-planner")
        ]
        let groups = SubdirectoryGroup.groups(from: files)
        #expect(groups[0].displayName == "pm-planner")
    }

    @Test("absoluteParentPath derived from file path parent directory")
    func absoluteParentPath() {
        let files = [
            file(path: "/root/sub/file.md", subdirectory: "sub")
        ]
        let groups = SubdirectoryGroup.groups(from: files)
        #expect(groups[0].absoluteParentPath == "/root/sub")
    }

    @Test("files within a group sorted alphabetically by name")
    func filesSortedAlphabetically() {
        let files = [
            file(path: "/root/sub/z.md", subdirectory: "sub"),
            file(path: "/root/sub/a.md", subdirectory: "sub"),
            file(path: "/root/sub/m.md", subdirectory: "sub")
        ]
        let groups = SubdirectoryGroup.groups(from: files)
        let names = groups[0].files.map { $0.name }
        #expect(names == names.sorted())
    }
}
