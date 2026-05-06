import SwiftUI

@main
struct SkillSuiteApp: App {
    @State private var appModel = AppModel()

    var body: some Scene {
        MenuBarExtra("SkillSuite", systemImage: "doc.text.magnifyingglass") {
            Text("SkillSuite")
                .frame(width: 700, height: 500)
        }
        .menuBarExtraStyle(.window)
    }
}
