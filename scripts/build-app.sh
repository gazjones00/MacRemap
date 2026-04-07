#!/bin/zsh

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
APP_NAME="MacRemap"
BUILD_DIR="$ROOT_DIR/.dist"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
INFO_PLIST_SOURCE="$ROOT_DIR/Resources/MacRemap-Info.plist"

cd "$ROOT_DIR"

echo "Building $APP_NAME..."
swift build -c release --product "$APP_NAME"

BIN_PATH="$(swift build -c release --show-bin-path)/$APP_NAME"

if [[ ! -x "$BIN_PATH" ]]; then
    echo "Built binary not found at $BIN_PATH" >&2
    exit 1
fi

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$BIN_PATH" "$MACOS_DIR/$APP_NAME"
cp "$INFO_PLIST_SOURCE" "$CONTENTS_DIR/Info.plist"
chmod +x "$MACOS_DIR/$APP_NAME"

# Inject version from git tag if available
if git describe --tags --exact-match HEAD >/dev/null 2>&1; then
    VERSION=$(git describe --tags --exact-match HEAD | sed 's/^v//')
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$CONTENTS_DIR/Info.plist"
    echo "Set version to $VERSION"
fi

if command -v codesign >/dev/null 2>&1; then
    codesign --force --deep --sign - "$APP_DIR" >/dev/null
fi

echo "Created app bundle at:"
echo "$APP_DIR"
