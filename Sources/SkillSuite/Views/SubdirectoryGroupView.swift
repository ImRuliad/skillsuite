import SwiftUI

struct SubdirectoryGroupView: View {
    let group: SubdirectoryGroup
    @Environment(AppModel.self) private var appModel

    private var isExpandedBinding: Binding<Bool> {
        Binding(
            get: {
                if !appModel.searchQuery.isEmpty {
                    return group.files.contains { appModel.matchingFileIDs.contains($0.id) }
                }
                return appModel.subdirectoryExpanded[group.absoluteParentPath] ?? false
            },
            set: { isExpanded in
                guard appModel.searchQuery.isEmpty else { return }
                appModel.subdirectoryExpanded[group.absoluteParentPath] = isExpanded
            }
        )
    }

    private var visibleFiles: [SkillFile] {
        guard !appModel.searchQuery.isEmpty else { return group.files }
        return group.files.filter { appModel.matchingFileIDs.contains($0.id) }
    }

    var body: some View {
        DisclosureGroup(isExpanded: isExpandedBinding) {
            ForEach(visibleFiles) { file in
                FileRowView(file: file)
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "folder")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(group.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
            }
            .padding(.vertical, 2)
        }
        .disclosureGroupStyle(SidebarDisclosureGroupStyle())
    }
}
