import SwiftUI
import AppKit

/// Header bar shown above the file content when a file is selected.
///
/// Displays the file name, full path, and the "Open in Editor" button (PER-34).
struct FileHeaderBar: View {
    let file: SkillFile

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .font(.headline)
                    .lineLimit(1)
                Text(file.path)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
            OpenInEditorButton(file: file)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        Divider()
    }
}

// MARK: - PER-34: Open in default editor

/// Opens the skill file in the system default handler for `.md` files.
///
/// Uses `NSWorkspace.shared.open(_:)` — no editor detection in v1.
/// Placed in `FileHeaderBar` (top-right of content panel, always visible when a file is selected).
struct OpenInEditorButton: View {
    let file: SkillFile

    var body: some View {
        Button("Open in Editor") {
            NSWorkspace.shared.open(URL(fileURLWithPath: file.path))
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }
}
