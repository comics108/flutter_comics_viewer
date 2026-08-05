#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage: tool/build-example.sh <android|ios|linux|macos|web|all>

Builds the Flutter example for one target, or every target supported by the
current host. Run it from any working directory.
EOF
}

if [[ $# -ne 1 ]]; then
  usage
  exit 64
fi

target=$1
case "$target" in
  android | ios | linux | macos | web | all) ;;
  *)
    echo "Unknown target: $target" >&2
    usage
    exit 64
    ;;
esac

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(cd "$script_dir/.." && pwd -P)
example_dir="$repo_root/example"

case "$(uname -s)" in
  Linux)
    host_name=Linux
    supported_targets=(android linux web)
    ;;
  Darwin)
    host_name=macOS
    supported_targets=(android ios macos web)
    ;;
  *)
    echo "Unsupported host for this wrapper. Use tool/build-example.ps1 on Windows." >&2
    exit 69
    ;;
esac

contains_target() {
  local candidate=$1
  shift
  local item
  for item in "$@"; do
    if [[ "$candidate" == "$item" ]]; then
      return 0
    fi
  done
  return 1
}

if [[ "$target" == all ]]; then
  selected_targets=("${supported_targets[@]}")
elif contains_target "$target" "${supported_targets[@]}"; then
  selected_targets=("$target")
else
  echo "Target '$target' is not supported on $host_name." >&2
  echo "Supported targets: ${supported_targets[*]} all" >&2
  exit 69
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter was not found on PATH. Install Flutter 3.44.6 before building." >&2
  exit 69
fi

if contains_target android "${selected_targets[@]}"; then
  android_sibling="$repo_root/../comics-viewer-android"
  if [[ ! -d "$android_sibling" ]]; then
    echo "Android build requires the sibling checkout at: $android_sibling" >&2
    echo "Clone https://github.com/comics108/comics-viewer-android there and retry." >&2
    exit 66
  fi
fi

cd "$example_dir"
flutter pub get

build_target() {
  local build_target=$1
  echo "Building viewer_example for $build_target..."
  case "$build_target" in
    android) flutter build apk --release ;;
    ios) flutter build ios --debug --no-codesign --simulator ;;
    linux) flutter build linux --release ;;
    macos) flutter build macos --release ;;
    web) flutter build web --release ;;
  esac
}

for selected_target in "${selected_targets[@]}"; do
  build_target "$selected_target"
done
