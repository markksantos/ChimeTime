#!/usr/bin/env bash
#
# build-app.sh — Build ChimeTime.app from the Swift package.
#
# Produces a proper macOS .app bundle (menu bar agent) in the project root.
# Pass --release for an optimized build (default is debug).
#
# Usage:
#   ./scripts/build-app.sh            # debug build
#   ./scripts/build-app.sh --release  # release build
#
set -euo pipefail

CONFIG="debug"
if [[ "${1:-}" == "--release" ]]; then
    CONFIG="release"
fi

# Resolve project root (parent of this script's directory).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"

APP_NAME="ChimeTime"
APP_BUNDLE="$ROOT/$APP_NAME.app"
INFO_PLIST="$ROOT/Info.plist"

echo "==> Building ChimeTime ($CONFIG)…"
swift build -c "$CONFIG"

BIN_PATH="$(swift build -c "$CONFIG" --show-bin-path)/$APP_NAME"
if [[ ! -f "$BIN_PATH" ]]; then
    echo "error: built binary not found at $BIN_PATH" >&2
    exit 1
fi

echo "==> Assembling $APP_NAME.app…"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"

cp "$BIN_PATH" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "$INFO_PLIST" "$APP_BUNDLE/Contents/Info.plist"

# Bundle an app icon if one has been generated (Resources/AppIcon.icns).
if [[ -f "$ROOT/Resources/AppIcon.icns" ]]; then
    mkdir -p "$APP_BUNDLE/Contents/Resources"
    cp "$ROOT/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

# Ad-hoc sign so the app runs locally without "damaged" warnings.
# Real distribution requires a Developer ID identity — see README.
codesign --force --deep --sign - "$APP_BUNDLE" 2>/dev/null || \
    echo "note: ad-hoc codesign skipped (codesign unavailable)"

echo "==> Done: $APP_BUNDLE"
echo "    Launch with: open \"$APP_BUNDLE\""
