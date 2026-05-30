import SwiftUI

/// A single row in the sidebar representing one `.md` file.
///
/// Highlights if the file was recently added (via FSEvents).
/// Tapping sets it as the selected file in `AppModel`.
struct FileRowView: View {
    let file: SkillFile
    @Environment(AppModel.self) private var appModel

    private var isSelected: Bool { appModel.selectedFile == file }
    private var isNew: Bool { appModel.recentlyAddedFilePaths.contains(file.path) }

    var body: some View {
        Button {
            appModel.selectedFile = file
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "doc.text")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(file.name)
                    .font(.system(size: 12))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
            }
            .padding(.vertical, 3)
            .padding(.horizontal, 8)
            .background(rowBackground)
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.4), value: isNew)
    }

    private var rowBackground: Color {
        if isSelected { return Color.accentColor.opacity(0.2) }
        if isNew { return Color.accentColor.opacity(0.12) }
        return .clear
    }
}
