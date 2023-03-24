// swift-tools-version: 5.6
import PackageDescription

let package = Package(
    name: "QliftUIC",
    products: [
        .executable(name: "qlift-uic", targets: ["qlift-uic"]),
        .plugin(name: "QliftUICPlugin", targets: ["QliftUICPlugin"]),
        .plugin(name: "QliftUICL10nPlugin", targets: ["QliftUICL10nPlugin"]),
        .plugin(name: "QliftCmdPlugin", targets: ["QliftUICCommandPlugin"]),
    ],
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
        .plugin(
            name: "QliftUICL10nPlugin",
            capability: .buildTool(),
            dependencies: ["qlift-uic"]
        ),
        .plugin(
            name: "QliftUICCommandPlugin",
            capability: .command(
                intent: .custom(verb: "qlift-uic", description: "Generate files for localization"),
                permissions: [.writeToPackageDirectory(reason: "Add localization strings and code")]
            ),
            dependencies: ["qlift-uic"]
        ),

    ]
)
