#!/bin/bash
#
# Build MACKey.app and a distributable DMG.
#
# Usage:  ./scripts/package.sh
#
# Output: MACKey.app and MACKey-<version>.dmg in the project root.
#
set -euo pipefail

cd "$(dirname "$0")/.."

APP="MACKey.app"
BIN_NAME="MACKey"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' Resources/Info.plist 2>/dev/null || echo 1.0.0)"
DMG="MACKey-${VERSION}.dmg"

echo "==> Building release binary"
swift build -c release

echo "==> Assembling ${APP}"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp ".build/release/${BIN_NAME}" "$APP/Contents/MacOS/${BIN_NAME}"
cp Resources/Info.plist "$APP/Contents/Info.plist"
if [ -f Resources/AppIcon.icns ]; then
    cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
    echo "    icon: bundled"
else
    echo "    icon: none (add Resources/AppIcon.icns to include one)"
fi

echo "==> Ad-hoc signing"
codesign --force --deep -s - "$APP"

echo "==> Creating ${DMG}"
rm -f "$DMG"
hdiutil create -volname "MACKey" -srcfolder "$APP" -ov -format UDZO "$DMG" >/dev/null

echo ""
echo "Done:"
echo "  • ${APP}"
echo "  • ${DMG}  (attach this to the GitHub Release)"
