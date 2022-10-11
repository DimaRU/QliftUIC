// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "QliftUIC",
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "qlift-uic",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]),
        .plugin(
            name: "QliftUICPlugin",
            capability: .buildTool(),
            dependencies: ["qlift-uic"]
        ),
    ]
)
