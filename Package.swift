// swift-tools-version: 6.2
import PackageDescription
let package = Package(name: "AthiDuo", defaultLocalization: "en", platforms: [.macOS(.v26)], products: [
    .executable(name: "AthiDuo", targets: ["AthiDuo"])
], targets: [
    .target(name: "FoldCore"),
    .executableTarget(name: "AthiDuo", dependencies: ["FoldCore"], path: "Sources/MacDuo", resources: [.process("Resources")], swiftSettings: [.swiftLanguageMode(.v5)])
])
