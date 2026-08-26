// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Chessblazer",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(name: "Chessblazer", targets: ["Chessblazer"]),
        .executable(name: "ChessblazerUCI", targets: ["ChessblazerUCI"]),
    ],
    targets: [
        .target(
            name: "Chessblazer",
            path: "Chessblazer",
            exclude: ["todo.md"]
        ),
        .executableTarget(
            name: "ChessblazerUCI",
            dependencies: ["Chessblazer"],
            path: "ChessblazerUCI"
        ),
        .testTarget(
            name: "ChessblazerEngineTests",
            dependencies: ["Chessblazer"],
            path: "ChessblazerEngineTests"
        ),
    ],
    swiftLanguageModes: [.v5]
)
