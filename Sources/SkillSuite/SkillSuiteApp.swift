import SwiftUI

@main
struct SkillSuiteApp: App {
    @State private var appModel = AppModel()

    var body: some Scene {
        MenuBarExtra("SkillSuite", systemImage: "doc.text.magnifyingglass") {
            PopoverRootView()
                .environment(appModel)
        }
        .menuBarExtraStyle(.window)
    }
}
