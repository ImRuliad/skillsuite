import SwiftUI

/// Right panel of the popover. Shows the selected file's contents.
///
/// States:
/// - Loading: `ProgressView` while initial scan runs
/// - No selection: placeholder prompt
/// - File selected: `FileHeaderBar` + scrollable monospaced content
struct ContentPaneView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        Group {
            if appModel.isLoading {
                loadingView
            } else if let file = appModel.selectedFile {
                fileView(file)
            } else {
                placeholderView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - States

    private var loadingView: some View {
        VStack(spacing: 8) {
            ProgressView()
            Text("Scanning files…")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var placeholderView: some View {
        VStack(spacing: 6) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text("Select a file to view its contents")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private func fileView(_ file: SkillFile) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            FileHeaderBar(file: file)
            ScrollView {
                Text(file.contents.isEmpty ? "(empty file)" : file.contents)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(file.contents.isEmpty ? .tertiary : .primary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
            }
        }
    }
}
