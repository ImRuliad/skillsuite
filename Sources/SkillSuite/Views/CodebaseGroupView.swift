import SwiftUI

/// Collapsible group for one user-added codebase in the CODEBASES section.
///
/// Files within the codebase are sub-grouped by their AI provider.
/// Right-clicking the group header reveals a "Remove Codebase" option.
struct CodebaseGroupView: View {
    let codebase: Codebase
    @Environment(AppModel.self) private var appModel

    private var isExpandedBinding: Binding<Bool> {
        let hasMatch = !(appModel.visibleCodebaseFiles[codebase.url.path] ?? [:]).isEmpty
        return appModel.codebaseBinding(for: codebase.url.path, hasMatch: hasMatch)
    }

    var body: some View {
        DisclosureGroup(isExpanded: isExpandedBinding) {
            let visibleByProvider = appModel.visibleCodebaseFiles[codebase.url.path] ?? [:]
            if !appModel.searchQuery.isEmpty && visibleByProvider.isEmpty {
                Text("0 results")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 16)
                    .padding(.vertical, 2)
            } else if codebase.files.isEmpty {
                Text("No AI files found")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 16)
                    .padding(.vertical, 2)
            } else {
                ForEach(appModel.providers(in: codebase), id: \.self) { provider in
                    providerSubGroup(provider: provider)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "folder")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(codebase.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                Spacer()
            }
            .padding(.vertical, 2)
        }
        .disclosureGroupStyle(SidebarDisclosureGroupStyle())
        .contextMenu {
            Button(role: .destructive) {
                appModel.removeCodebase(codebase)
            } label: {
                Label("Remove Codebase", systemImage: "trash")
            }
        }
    }

    private func providerSubGroup(provider: AIProvider) -> some View {
        let allProviderFiles = codebase.files.filter { $0.provider == provider }
        let visibleRootFiles = (appModel.visibleCodebaseFiles[codebase.url.path]?[provider] ?? [])
            .filter { $0.subdirectory.isEmpty }
        let allGroups = SubdirectoryGroup.groups(from: allProviderFiles)
        let visibleGroups = appModel.searchQuery.isEmpty
            ? allGroups
            : allGroups.filter { group in
                group.files.contains { appModel.matchingFileIDs.contains($0.id) }
            }

        return VStack(alignment: .leading, spacing: 0) {
            Text(provider.rawValue.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.tertiary)
                .padding(.leading, 20)
                .padding(.top, 4)
            ForEach(visibleRootFiles) { file in
                FileRowView(file: file)
                    .padding(.leading, 8)
            }
            ForEach(visibleGroups) { group in
                SubdirectoryGroupView(group: group)
                    .padding(.leading, 8)
            }
        }
    }
}
