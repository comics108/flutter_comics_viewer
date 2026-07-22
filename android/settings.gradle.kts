rootProject.name = "flutter_comics_viewer"

// Include the comics-viewer-android library
include(":comics-viewer-android")
project(":comics-viewer-android").projectDir = File("../../comics-viewer-android")
