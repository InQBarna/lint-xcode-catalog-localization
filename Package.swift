// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "lint-xcode-catalog-localization",
    products: [
        .executable(name: "LintLocalization", targets: ["LintLocalization"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "LintLocalization",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "LintLocalizationTests",
            dependencies: ["LintLocalization"],
            resources: [.copy("mocks")]
        ),
    ]
)
