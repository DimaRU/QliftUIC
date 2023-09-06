// swift-tools-version: 5.6
import PackageDescription

let package = Package(
    name: "QliftUIC",
    products: [
        .executable(name: "qlift-uic", targets: ["qlift-uic"]),
        .plugin(name: "QliftUICPlugin", targets: ["QliftUICPlugin"]),
        .plugin(name: "QliftUICL10nPlugin", targets: ["QliftUICL10nPlugin"]),
        .plugin(name: "QliftUICCommandPlugin", targets: ["QliftUICCommandPlugin"]),
        .plugin(name: "RccCommandPlugin", targets: ["RccCommandPlugin"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "qlift-uic",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Collections", package: "swift-collections"),
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
                intent: .custom(verb: "uic", description: "Generate files for localization"),
                permissions: [.writeToPackageDirectory(reason: "Add localization strings and accessor code")]
            ),
            dependencies: ["qlift-uic"]
        ),
        .plugin(
            name: "RccCommandPlugin",
            capability: .command(
                intent: .custom(verb: "rcc", description: "Compile QT resource files"),
                permissions: [.writeToPackageDirectory(reason: "Add compiled QT resource files and accessor code")]
            ),
            dependencies: ["qlift-uic"]
        ),
    ]
)
