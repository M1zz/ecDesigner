// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ecDesigner",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "ecDesigner",
            targets: ["ecDesigner"]
        )
    ],
    targets: [
        .executableTarget(
            name: "ecDesigner",
            path: "ecDesigner"
        )
    ]
)
