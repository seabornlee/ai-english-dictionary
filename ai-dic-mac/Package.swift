// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AIDictionary",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "AIDictionary",
            type: .dynamic,
            targets: ["AIDictionary"]
        )
    ],
    targets: [
        .target(
            name: "AIDictionary",
            path: "AIDictionary",
            resources: [
                .process("Assets.xcassets"),
                .process("AIDictionary.entitlements")
            ],
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals")
            ]
        ),
        .testTarget(
            name: "AIDictionaryTests",
            dependencies: ["AIDictionary"],
            path: "AIDictionaryTests"
        )
    ]
)