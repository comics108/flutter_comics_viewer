// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "flutter_comics_viewer",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(
            name: "flutter-comics-viewer",
            targets: ["flutter_comics_viewer"]
        )
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "flutter_comics_viewer",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
