import SwiftUI

struct SubdirectoryGroupView: View {
    let group: SubdirectoryGroup
    @Environment(AppModel.self) private var appModel

    private var isExpandedBinding: Binding<Bool> {
        appModel.subdirectoryBinding(
            for: group.absoluteParentPath,
            hasMatch: group.files.contains { appModel.matchingFileIDs.contains($0.id) }
        )
    }

    var body: some View {
        DisclosureGroup(isExpanded: isExpandedBinding) {
            ForEach(group.files) { file in
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
