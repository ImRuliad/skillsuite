import SwiftUI

/// Left panel of the popover. Shows SearchBar, then GLOBAL and CODEBASES sections.
struct SidebarView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SearchBar()
            Divider().padding(.top, 6)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    globalSection
                    Divider().padding(.vertical, 6)
                    codebasesSection
                }
                .padding(.bottom, 8)
            }
        }
        .frame(width: 220)
        .background(.ultraThinMaterial)
    }

    // MARK: - GLOBAL Section

    private var globalSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("GLOBAL")
            if appModel.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(0.6)
                    .padding(.leading, 16)
                    .padding(.vertical, 8)
            } else {
                ForEach(AIProvider.allCases) { provider in
                    ProviderGroupView(
                        provider: provider,
                        files: appModel.globalFiles[provider] ?? []
                    )
                }
            }
        }
    }

    // MARK: - CODEBASES Section

    private var codebasesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("CODEBASES")
            ForEach(appModel.codebases) { codebase in
                CodebaseGroupView(codebase: codebase)
            }
            addCodebaseButton
        }
    }

    private var addCodebaseButton: some View {
        Button {
            appModel.presentFolderPicker?()
        } label: {
            Label("Add Codebase", systemImage: "plus.circle")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 2)
    }
}
