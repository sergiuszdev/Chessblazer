// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Chessblazer",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .linux(.v6.1),
    ],
    products: [
        .library(name: "Chessblazer", targets: ["Chessblazer"]),
        .executable(name: "ChessblazerUCI", targets: ["ChessblazerUCI"]),
    ],
    targets: [
        .target(
            name: "Fathom",
            path: "Vendor/Fathom",
            exclude: [
                "tbchess.c",
            ],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include"),
                .define("TB_NO_HELPER_API"),
                .define("TB_NO_THREADS"),
            ]
        ),
        .target(
            name: "Chessblazer",
            dependencies: ["Fathom"],
            path: "Chessblazer",
            exclude: [
                "todo.md",
                "ModuleCache.noindex",
                "SDKStatCaches.noindex",
                "main",
                "ChessEngine/MoveGenerator/bishopShifts",
                "ChessEngine/MoveGenerator/rookShifts",
            ]
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
