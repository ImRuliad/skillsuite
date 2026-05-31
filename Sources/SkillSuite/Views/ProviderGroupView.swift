import SwiftUI

/// Collapsible group showing all `.md` files for one global AI provider.
///
/// When a search is active and no files match, shows a muted "0 results" row
/// rather than hiding the group header entirely.
struct ProviderGroupView: View {
    let provider: AIProvider
    let files: [SkillFile]
    @Environment(AppModel.self) private var appModel

    private var isExpandedBinding: Binding<Bool> {
        appModel.providerBinding(for: provider, hasMatch: !files.isEmpty)
    }

    var body: some View {
        DisclosureGroup(isExpanded: isExpandedBinding) {
            if files.isEmpty && appModel.searchQuery.isEmpty {
                noFilesRow
            } else if files.isEmpty && !appModel.searchQuery.isEmpty {
                zeroResultsRow
            } else {
                let rootFiles = files.filter { $0.subdirectory.isEmpty }
                let allGroups = SubdirectoryGroup.groups(from: files)

                ForEach(rootFiles) { file in
                    FileRowView(file: file)
                }
                ForEach(allGroups) { group in
                    SubdirectoryGroupView(group: group)
                }
            }
        } label: {
            providerLabel
        }
        .disclosureGroupStyle(SidebarDisclosureGroupStyle())
    }

    private var providerLabel: some View {
        HStack(spacing: 4) {
            Image(systemName: providerIcon)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(provider.rawValue.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.vertical, 2)
    }

    private var noFilesRow: some View {
        Text("No files found")
            .font(.caption)
            .foregroundStyle(.tertiary)
            .padding(.leading, 16)
            .padding(.vertical, 2)
    }

    private var zeroResultsRow: some View {
        Text("0 results")
            .font(.caption)
            .foregroundStyle(.tertiary)
            .padding(.leading, 16)
            .padding(.vertical, 2)
    }

    private var providerIcon: String {
        switch provider {
        case .claude:  return "sparkles"
        case .copilot: return "airplane"
        case .codex:   return "chevron.left.forwardslash.chevron.right"
        case .gemini:  return "diamond"
        }
    }
}
