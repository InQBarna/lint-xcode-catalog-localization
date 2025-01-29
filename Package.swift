// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "lint-xcode-catalog-localization",
    products: [
        .executable(name: "LintLocalization", targets: ["LintLocalization"]),
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "LintLocalization",
            dependencies: []
        ),
    ]
)
