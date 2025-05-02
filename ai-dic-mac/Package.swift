// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AIDictionary",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "AIDictionary",
            targets: ["AIDictionary"]
        )
    ],
    targets: [
        .executableTarget(
            name: "AIDictionary",
            path: "AIDictionary",
            resources: [
                .process("Assets.xcassets")
            ]
        )
    ]
) 