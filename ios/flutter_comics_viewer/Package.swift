// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    // Must match the pubspec.yaml package name ("flutter_comics_viewer") —
    // Flutter's generated FlutterGeneratedPluginSwiftPackage looks up this
    // plugin by that name and expects a product named "<name>_<target>".
    name: "flutter_comics_viewer",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "flutter-comics-viewer", targets: ["flutter_comics_viewer"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        // A local path dependency doesn't work here: Flutter stages this
        // package's directory into example/ios/Flutter/ephemeral/ before
        // resolving it, and a relative path pointing outside the plugin's
        // own folder doesn't survive that staging step. A remote reference
        // is what Flutter's local-SwiftPM plugin support actually expects
        // for dependencies that live outside the plugin.
        .package(url: "https://github.com/comics108/comics-viewer-ios.git", branch: "main")
    ],
    targets: [
        .target(
            name: "flutter_comics_viewer",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "ComicsViewer", package: "comics-viewer-ios")
            ],
            resources: [
                // If your plugin requires a privacy manifest, for example if it uses any required
                // reason APIs, update the PrivacyInfo.xcprivacy file to describe your plugin's
                // privacy impact, and then uncomment these lines. For more information, see
                // https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
                // .process("PrivacyInfo.xcprivacy"),

                // If you have other resources that need to be bundled with your plugin, refer to
                // the following instructions to add them:
                // https://developer.apple.com/documentation/xcode/bundling-resources-with-a-swift-package
            ]
        )
    ]
)
