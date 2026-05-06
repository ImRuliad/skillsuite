// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SkillSuite",
    platforms: [.macOS("26.0")],
    targets: [
        .executableTarget(
            name: "SkillSuite",
            path: "Sources/SkillSuite",
            exclude: ["Resources/Info.plist"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "SkillSuiteTests",
            dependencies: ["SkillSuite"],
            path: "Tests/SkillSuiteTests"
        )
    ]
)
