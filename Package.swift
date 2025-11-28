// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "EspoCRMKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "EspoCRMKit",
            targets: ["EspoCRMKit"]
        ),
    ],
    targets: [
        .target(
            name: "EspoCRMKit"
        ),
        .testTarget(
            name: "EspoCRMKitTests",
            dependencies: ["EspoCRMKit"]
        ),
    ]
)
