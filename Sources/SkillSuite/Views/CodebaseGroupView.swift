import SwiftUI

/// Collapsible group for one user-added codebase in the CODEBASES section.
///
/// Files within the codebase are sub-grouped by their AI provider.
/// Right-clicking the group header reveals a "Remove Codebase" option.
struct CodebaseGroupView: View {
    let codebase: Codebase
    @Environment(AppModel.self) private var appModel
    @State private var isExpanded = true

    private var groupedFiles: [(AIProvider, [SkillFile])] {
        var byProvider: [AIProvider: [SkillFile]] = [:]
        let files: [SkillFile]
        if appModel.searchQuery.isEmpty {
            files = codebase.files
        } else {
            files = codebase.files.filter { appModel.matchingFileIDs.contains($0.id) }
        }
        for file in files { byProvider[file.provider, default: []].append(file) }
        return byProvider.sorted { $0.key.rawValue < $1.key.rawValue }
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            if groupedFiles.isEmpty && !appModel.searchQuery.isEmpty {
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
                ForEach(groupedFiles, id: \.0) { provider, files in
                    providerSubGroup(provider: provider, files: files)
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
        .disclosureGroupStyle(SidebarCodebaseGroupStyle())
        .contextMenu {
            Button(role: .destructive) {
                appModel.removeCodebase(codebase)
            } label: {
                Label("Remove Codebase", systemImage: "trash")
            }
        }
    }

    private func providerSubGroup(provider: AIProvider, files: [SkillFile]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(provider.rawValue.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.tertiary)
                .padding(.leading, 20)
                .padding(.top, 4)
            ForEach(files) { file in
                FileRowView(file: file)
                    .padding(.leading, 8)
            }
        }
    }
}

private struct SidebarCodebaseGroupStyle: DisclosureGroupStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    configuration.isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .rotationEffect(.degrees(configuration.isExpanded ? 90 : 0))
                        .animation(.easeInOut(duration: 0.15), value: configuration.isExpanded)
                        .foregroundStyle(.tertiary)
                    configuration.label
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)

            if configuration.isExpanded {
                configuration.content
                    .padding(.leading, 8)
            }
        }
    }
}
