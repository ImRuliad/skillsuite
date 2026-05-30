import Testing
@testable import SkillSuite

@Suite("SubdirectoryGroup")
struct SubdirectoryGroupingTests {

    private func makeFile(
        name: String,
        path: String,
        subdirectory: String,
        provider: AIProvider = .claude
    ) -> SkillFile {
        SkillFile(
            provider: provider,
            name: name,
            path: path,
            contents: "",
            isGlobal: true,
            subdirectory: subdirectory
        )
    }

    @Test("groupsFrom_emptyFiles_returnsEmptyArray")
    func groupsFromEmptyFilesReturnsEmptyArray() {
        #expect(SubdirectoryGroup.groups(from: []).isEmpty)
    }

    @Test("groupsFrom_rootFilesOnly_returnsEmptyArray")
    func groupsFromRootFilesOnlyReturnsEmptyArray() {
        let files = [
            makeFile(name: "CLAUDE.md", path: "/tmp/CLAUDE.md", subdirectory: ""),
            makeFile(name: "README.md", path: "/tmp/README.md", subdirectory: "")
        ]

        #expect(SubdirectoryGroup.groups(from: files).isEmpty)
    }

    @Test("groupsFrom_nestedFiles_groupsBySubdirectory")
    func groupsFromNestedFilesGroupsBySubdirectory() {
        let files = [
            makeFile(name: "a.md", path: "/tmp/root/skills/a/a.md", subdirectory: "skills/a"),
            makeFile(name: "b.md", path: "/tmp/root/skills/a/b.md", subdirectory: "skills/a"),
            makeFile(name: "c.md", path: "/tmp/root/skills/b/c.md", subdirectory: "skills/b")
        ]

        let groups = SubdirectoryGroup.groups(from: files)

        #expect(groups.count == 2)
        #expect(groups[0].files.map(\.name) == ["a.md", "b.md"])
        #expect(groups[1].files.map(\.name) == ["c.md"])
    }

    @Test("groupsFrom_nestedFiles_usesLastPathComponentAsDisplayName")
    func groupsFromNestedFilesUsesLastPathComponentAsDisplayName() {
        let files = [
            makeFile(
                name: "SKILL.md",
                path: "/tmp/root/skills/productivity/pm-planner/SKILL.md",
                subdirectory: "skills/productivity/pm-planner"
            )
        ]

        let group = SubdirectoryGroup.groups(from: files)[0]

        #expect(group.displayName == "pm-planner")
    }

    @Test("groupsFrom_nestedFiles_preservesFullSubdirectory")
    func groupsFromNestedFilesPreservesFullSubdirectory() {
        let files = [
            makeFile(
                name: "SKILL.md",
                path: "/tmp/root/skills/productivity/pm-planner/SKILL.md",
                subdirectory: "skills/productivity/pm-planner"
            )
        ]

        let group = SubdirectoryGroup.groups(from: files)[0]

        #expect(group.subdirectory == "skills/productivity/pm-planner")
    }

    @Test("groupsFrom_nestedFiles_usesAbsoluteParentPathAsID")
    func groupsFromNestedFilesUsesAbsoluteParentPathAsID() {
        let files = [
            makeFile(
                name: "SKILL.md",
                path: "/tmp/root/skills/productivity/pm-planner/SKILL.md",
                subdirectory: "skills/productivity/pm-planner"
            )
        ]

        let group = SubdirectoryGroup.groups(from: files)[0]

        #expect(group.absoluteParentPath == "/tmp/root/skills/productivity/pm-planner")
        #expect(group.id == group.absoluteParentPath)
    }

    @Test("groupsFrom_nestedFiles_sortsFilesAlphabeticallyByName")
    func groupsFromNestedFilesSortsFilesAlphabeticallyByName() {
        let files = [
            makeFile(name: "zeta.md", path: "/tmp/root/skills/a/zeta.md", subdirectory: "skills/a"),
            makeFile(name: "Alpha.md", path: "/tmp/root/skills/a/Alpha.md", subdirectory: "skills/a"),
            makeFile(name: "beta.md", path: "/tmp/root/skills/a/beta.md", subdirectory: "skills/a")
        ]

        let group = SubdirectoryGroup.groups(from: files)[0]

        #expect(group.files.map(\.name) == ["Alpha.md", "beta.md", "zeta.md"])
    }

    @Test("groupsFrom_nestedFiles_sortsGroupsBySubdirectoryPath")
    func groupsFromNestedFilesSortsGroupsBySubdirectoryPath() {
        let files = [
            makeFile(name: "z.md", path: "/tmp/root/z/z.md", subdirectory: "z"),
            makeFile(name: "a.md", path: "/tmp/root/a/a.md", subdirectory: "a"),
            makeFile(name: "m.md", path: "/tmp/root/m/n/m.md", subdirectory: "m/n")
        ]

        let groups = SubdirectoryGroup.groups(from: files)

        #expect(groups.map(\.subdirectory) == ["a", "m/n", "z"])
    }
}
