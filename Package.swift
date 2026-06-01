// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "GlassTodoNote",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "GlassTodoNote", targets: ["GlassTodoNote"]),
        .library(name: "GlassTodoNoteCore", targets: ["GlassTodoNoteCore"])
    ],
    targets: [
        .target(name: "GlassTodoNoteCore"),
        .executableTarget(
            name: "GlassTodoNote",
            dependencies: ["GlassTodoNoteCore"]
        ),
        .testTarget(
            name: "GlassTodoNoteCoreTests",
            dependencies: ["GlassTodoNoteCore"]
        )
    ]
)
