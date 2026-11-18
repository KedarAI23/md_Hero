// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Pare",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "PareCore", targets: ["PareCore"]),
        .executable(name: "Pare", targets: ["Pare"])
    ],
    targets: [
        .target(name: "PareCore"),
        .executableTarget(
            name: "Pare",
            dependencies: ["PareCore"]
        ),
        .testTarget(
            name: "PareTests",
            dependencies: ["PareCore"],
            resources: [.copy("Fixtures")]
        )
    ]
)
