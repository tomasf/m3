// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "tomasf-m3",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/tomasf/Cadova.git", .upToNextMinor(from: "0.9.3")),
        .package(url: "https://github.com/tomasf/Helical.git", .upToNextMinor(from: "1.0.4")),
    ],
    targets: [
        .executableTarget(
            name: "tomasf-m3",
            dependencies: ["Cadova", "Helical"],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        )
    ]
)
