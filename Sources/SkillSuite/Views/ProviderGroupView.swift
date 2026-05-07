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
        Binding(
            get: { appModel.providerExpanded[provider] ?? false },
            set: { appModel.providerExpanded[provider] = $0 }
        )
    }

    private var visibleFiles: [SkillFile] {
        guard !appModel.searchQuery.isEmpty else { return files }
        return files.filter { appModel.matchingFileIDs.contains($0.id) }
    }

    var body: some View {
        DisclosureGroup(isExpanded: isExpandedBinding) {
            if visibleFiles.isEmpty && !appModel.searchQuery.isEmpty {
                zeroResultsRow
            } else if files.isEmpty {
                noFilesRow
            } else {
                ForEach(visibleFiles) { file in
                    FileRowView(file: file)
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

// MARK: - Custom Disclosure Style

private struct SidebarDisclosureGroupStyle: DisclosureGroupStyle {
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
