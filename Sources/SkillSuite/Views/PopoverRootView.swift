import SwiftUI

/// Root view of the menubar popover. Two-panel layout: sidebar + content pane.
///
/// Styled with Liquid Glass: `.ultraThinMaterial` background, `glassEffect()` on the sidebar.
struct PopoverRootView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        HStack(spacing: 0) {
            SidebarView()
                .glassEffect()
            Divider()
                .opacity(0.3)
            ContentPaneView()
        }
        .frame(width: 700, height: 500)
        .background(.ultraThinMaterial)
        .task {
            await appModel.loadAll()
        }
    }
}
