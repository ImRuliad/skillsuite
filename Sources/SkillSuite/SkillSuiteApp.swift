import SwiftUI

@main
struct SkillSuiteApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Minimal scene required by SwiftUI App protocol.
        // All UI is managed by AppDelegate via NSStatusItem + NSPopover.
        Settings { EmptyView() }
    }
}
