#!/usr/bin/env bash
# push_test_assets.sh
# Pushes test receipt images to the connected Android emulator/device.
#
# Usage:
#   chmod +x push_test_assets.sh   (first time only)
#   ./push_test_assets.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$SCRIPT_DIR/assets"
DEST="/sdcard/Pictures"

if ! command -v adb &>/dev/null; then
  echo "ERROR: adb not found. Add Android SDK platform-tools to your PATH."
  exit 1
fi

DEVICE_COUNT=$(adb devices 2>/dev/null | grep -c "device$" || true)
if [[ "$DEVICE_COUNT" -eq 0 ]]; then
  echo "ERROR: No Android device/emulator connected."
  exit 1
fi

echo "Pushing test assets to $DEST..."
for f in "$ASSETS_DIR"/*.jpg "$ASSETS_DIR"/*.png; do
  [[ -e "$f" ]] || continue
  adb push "$f" "$DEST/"
  echo "  pushed: $(basename "$f")"
done

echo "Done."
