#!/bin/sh
# Builds SkillSuite.app bundle with Info.plist embedded (required for LSUIElement)
set -e

CONFIG="${1:-release}"
BUILD_DIR=".build/$CONFIG"
APP_NAME="SkillSuite"
APP_BUNDLE="$APP_NAME.app"

echo "Building $CONFIG..."
swift build -c "$CONFIG"

echo "Creating $APP_BUNDLE..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"
cp "Sources/SkillSuite/Resources/Info.plist" "$APP_BUNDLE/Contents/"

echo "Signing ad-hoc..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo "Done: $APP_BUNDLE"
echo "Run with: open $APP_BUNDLE"
