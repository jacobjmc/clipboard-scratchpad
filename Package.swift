// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ClipboardScratchpad",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "ClipboardScratchpad", targets: ["ClipboardScratchpadApp"])
    ],
    targets: [
        .target(name: "ClipboardScratchpadLib"),
        .executableTarget(
            name: "ClipboardScratchpadApp",
            dependencies: ["ClipboardScratchpadLib"],
            exclude: ["Resources"]
        ),
        .testTarget(
            name: "ClipboardScratchpadLibTests",
            dependencies: ["ClipboardScratchpadLib"]
        )
    ]
)
