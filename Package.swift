// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "tomasf-m3",
    platforms: [.macOS(.v14)], // Needed on macOS
    dependencies: [
        .package(url: "https://github.com/tomasf/SwiftSCAD.git", branch: "main"),
        .package(url: "https://github.com/tomasf/Helical.git", branch: "main")
        //.package(name: "SwiftSCAD", path: "~/Documents/Projects/SwiftSCAD"),
        //.package(name: "Helical", path: "~/Documents/Projects/Helical")
    ],
    targets: [
        .executableTarget(name: "tomasf-m3", dependencies: ["SwiftSCAD", "Helical"])
    ]
)
