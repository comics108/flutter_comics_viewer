# Flutter Comics Viewer example

This application exercises `flutter_comics_viewer` on Android, iOS, Linux,
macOS, Windows, and Web. It is a build-verification host, not a signed or
store-ready distribution.

## Toolchain

Use Flutter 3.44.6 with its bundled Dart 3.12.x toolchain. Confirm the active
version before building:

```sh
flutter --version
```

All builds require network access for Dart packages. The iOS and macOS builds
also resolve the plugin's `comics-viewer-ios` Swift package from the `main`
branch on GitHub.

Platform prerequisites:

- Android: Android SDK and JDK 17.
- iOS and macOS: macOS with Xcode 16.
- Linux: `clang`, `cmake`, `ninja-build`, `pkg-config`, `libgtk-3-dev`, and
  `liblzma-dev`.
- Windows: Visual Studio with the Desktop development with C++ workload.

## Android checkout layout

The plugin's Gradle settings include `comics-viewer-android` by a relative
source path. Keep both repositories next to each other:

```text
<parent>/
├── flutter_comics_viewer/
└── comics-viewer-android/
```

Clone the dependency when it is missing:

```sh
git clone https://github.com/comics108/comics-viewer-android.git ../comics-viewer-android
```

The build wrappers validate this layout but never clone or move repositories.

## Build wrappers

Run wrappers from the `flutter_comics_viewer` repository root or any other
working directory.

Linux and macOS:

```sh
tool/build-example.sh <android|ios|linux|macos|web|all>
```

Windows PowerShell 7:

```powershell
./tool/build-example.ps1 <android|windows|web|all>
```

`all` builds targets in this order:

| Host | Targets |
|---|---|
| Linux | Android, Linux, Web |
| macOS | Android, iOS, macOS, Web |
| Windows | Android, Windows, Web |

An explicitly requested target that is unsupported by the current host fails
with a diagnostic. Wrappers run `flutter pub get` once and do not run
`flutter clean` or delete existing outputs.

## Direct build commands

Run direct commands from this `example/` directory:

| Target | Command | Output |
|---|---|---|
| Android | `flutter build apk --release` | `build/app/outputs/flutter-apk/app-release.apk` |
| iOS | `flutter build ios --debug --no-codesign --simulator` | `build/ios/iphonesimulator/Runner.app` |
| Linux | `flutter build linux --release` | `build/linux/<arch>/release/bundle/` |
| macOS | `flutter build macos --release` | `build/macos/Build/Products/Release/viewer_example.app` |
| Windows | `flutter build windows --release` | `build/windows/<arch>/runner/Release/` |
| Web | `flutter build web --release` | `build/web/` |

`<arch>` is normally `x64` on GitHub-hosted Linux and Windows runners but may
differ on a local machine.

The iOS command creates an unsigned simulator application. These commands do
not configure production signing, provisioning profiles, notarization, or store
publishing.

## Validation

The example validation gate intentionally covers only its current Dart source
and unit/widget tests:

```sh
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze lib test
flutter test test
```

`integration_test/plugin_integration_test.dart` still references the old
`package:viewer/viewer.dart` API. It is excluded until that test is migrated in
a separate change.

## GitHub Actions

`.github/workflows/example-build.yml` repeats these checks and builds all six
platforms on native-compatible runners. Each successful platform job uploads a
downloadable artifact retained for 14 days. The workflow performs verification
only; package publishing remains in the existing publish workflow.
