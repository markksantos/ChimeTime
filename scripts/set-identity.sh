#!/usr/bin/env bash
#
# set-identity.sh — Point ChimeTime at your real App Store identity.
#
# The bundle ID, IAP product ID, and Team ID appear in five files. This updates
# all of them together so they can't drift apart, which is the single most
# common cause of "Cannot connect to iTunes Store" and invalid-binary rejections.
#
# Usage:
#   ./scripts/set-identity.sh <bundle-id> [team-id]
#
# Example:
#   ./scripts/set-identity.sh com.markstudios.chimetime AB12CD34EF
#
# The IAP product ID is derived as "<bundle-id>.pro". Create a non-consumable
# with exactly that identifier in App Store Connect.
set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "usage: $0 <bundle-id> [team-id]" >&2
    echo "example: $0 com.markstudios.chimetime AB12CD34EF" >&2
    exit 1
fi

BUNDLE_ID="$1"
TEAM_ID="${2:-}"
PRODUCT_ID="${BUNDLE_ID}.pro"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"

# Read the values currently in use so this script is re-runnable.
OLD_BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' Info.plist)"
OLD_PRODUCT_ID="$(grep -o 'proUnlockProductID = "[^"]*"' Sources/ChimeTime/Purchase/StoreConfiguration.swift | sed 's/.*"\(.*\)"/\1/')"

echo "==> Bundle ID:  $OLD_BUNDLE_ID  ->  $BUNDLE_ID"
echo "==> Product ID: $OLD_PRODUCT_ID  ->  $PRODUCT_ID"

/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" Info.plist

python3 - "$OLD_BUNDLE_ID" "$BUNDLE_ID" "$OLD_PRODUCT_ID" "$PRODUCT_ID" <<'PY'
import sys, pathlib
old_bundle, new_bundle, old_product, new_product = sys.argv[1:5]

def replace(path, pairs):
    p = pathlib.Path(path)
    t = p.read_text()
    for old, new in pairs:
        t = t.replace(old, new)
    p.write_text(t)
    print(f"    updated {path}")

replace("Sources/ChimeTime/Purchase/StoreConfiguration.swift", [(old_product, new_product)])
replace("Products.storekit", [(old_product, new_product)])
replace("project.yml", [(f"PRODUCT_BUNDLE_IDENTIFIER: {old_bundle}", f"PRODUCT_BUNDLE_IDENTIFIER: {new_bundle}")])
PY

if [[ -n "$TEAM_ID" ]]; then
    echo "==> Team ID: $TEAM_ID"
    python3 - "$TEAM_ID" <<'PY'
import sys, re, pathlib
team = sys.argv[1]
p = pathlib.Path("project.yml")
t = p.read_text()
t = re.sub(r'DEVELOPMENT_TEAM: "[^"]*"', f'DEVELOPMENT_TEAM: "{team}"', t)
t = t.replace("    DEVELOPMENT_TEAM: \"\"            # TODO: your Team ID",
              f"    DEVELOPMENT_TEAM: \"{team}\"")
p.write_text(t)
print("    updated project.yml")
PY
fi

echo "==> Regenerating Xcode project…"
if command -v xcodegen >/dev/null 2>&1; then
    xcodegen generate
else
    echo "    xcodegen not found — run: brew install xcodegen && xcodegen generate" >&2
fi

echo
echo "Done. Next:"
echo "  1. Register the App ID '$BUNDLE_ID' in the Apple Developer portal."
echo "  2. Create a NON-CONSUMABLE in App Store Connect with product ID:"
echo "         $PRODUCT_ID"
echo "  3. Price it at Tier 5 (\$4.99) and submit it WITH the app's first build."
