import SwiftUI

/// Search bar pinned above the sidebar.
///
/// Bound directly to `AppModel.searchQuery` — filters update on every keystroke
/// via `onChange`. The × button clears the query instantly.
struct SearchBar: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField("Search files…", text: Bindable(appModel).searchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .onChange(of: appModel.searchQuery) {
                    appModel.updateMatches()
                }
            if !appModel.searchQuery.isEmpty {
                Button {
                    appModel.searchQuery = ""
                    appModel.updateMatches()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
        .padding(.horizontal, 8)
        .padding(.top, 8)
    }
}
