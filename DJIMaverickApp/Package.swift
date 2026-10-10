// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DJIMaverickApp",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DJIMaverickApp",
            targets: ["DJIMaverickApp"]
        ),
    ],
    targets: [
        .target(
            name: "DJIMaverickApp",
            path: "Sources"
        ),
    ]
)
