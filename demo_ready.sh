#!/usr/bin/env bash
# demo_ready.sh
# Resets the Lifelog Flutter app to a clean "fresh install" state on the
# connected Android device/emulator. Equivalent to "Clear Data" in Settings.
# Run this before any demo.
#
# What `pm clear` removes on the device:
#   - SQLite database (lifelog.db): expenses, budgets, todos, notifications,
#     moodLog, receipt_line_items, user_aliases, store_aliases, gratitudeEntries
#   - SharedPreferences: userName, device_id, app_instance_id,
#     app_instance_token, notifications_enabled, auto_in_progress_enabled,
#     swipe_ltr_action, swipe_rtl_action, donate_aliases_pref
#   - FCM token (app must re-register on next launch)
#   - Cached images from image_picker
#   - All files in the app's internal/external storage
#
# NOTE: `pm clear` only wipes local (on-device) data. The backend retains
#   the old AppInstance, UserPreference, and AliasDonation records as
#   orphans. The app registers a new AppInstance on next launch.
#   To clean up backend-side data, add a /api/aliases/instances/deactivate/
#   endpoint and call it before `pm clear` (see the commented-out section
#   near the end of this script).
#
# Usage:
#   chmod +x demo_ready.sh   (first time only)
#   ./demo_ready.sh
#
# Optional flags:
#   --no-launch              Wipe data but don't relaunch the app
#   --device <id>            Target a specific device (from `adb devices`)
#   --full                   Also run `flutter clean` in lifelog/ (clears build artifacts)
#   --backend-url <url>      Override backend URL (default: reads from lifelog/.env)
#   --push-test-receipt      Push test_assets/"restaurant test.jpg" to the device gallery
#                            so it can be picked from the gallery during the demo scan.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLUTTER_DIR="$SCRIPT_DIR/lifelog"

PACKAGE="com.example.lifelog"
LAUNCH=true
DEVICE_ARG=""
FULL_CLEAN=false
BACKEND_URL=""
PUSH_TEST_RECEIPT=false

# Local copy of the test receipt used for the expense-scan demo step.
# Place the file at:  Capstone_Frontend/test_assets/restaurant test.jpg
LOCAL_TEST_RECEIPT="$SCRIPT_DIR/test_assets/restaurant test.jpg"
DEVICE_TEST_RECEIPT="/sdcard/Pictures/restaurant test.jpg"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-launch)           LAUNCH=false; shift ;;
    --device)              DEVICE_ARG="-s $2"; shift 2 ;;
    --full)                FULL_CLEAN=true; shift ;;
    --backend-url)         BACKEND_URL="$2"; shift 2 ;;
    --push-test-receipt)   PUSH_TEST_RECEIPT=true; shift ;;
    *) echo "Unknown flag: $1"; exit 1 ;;
  esac
done

ADB="adb $DEVICE_ARG"

# Resolve BACKEND_URL from .env if not provided via flag
if [[ -z "$BACKEND_URL" ]]; then
  ENV_FILE="$FLUTTER_DIR/.env"
  if [[ -f "$ENV_FILE" ]]; then
    BACKEND_URL=$(grep -E '^BACKEND_URL=' "$ENV_FILE" | cut -d'=' -f2- || true)
  fi
fi
BACKEND_URL="${BACKEND_URL:-http://10.0.2.2:8001}"

# Compute total steps
STEPS=2
if [[ "$FULL_CLEAN" == true ]]; then ((STEPS++)); fi
if [[ "$PUSH_TEST_RECEIPT" == true ]]; then ((STEPS++)); fi
STEP=0
next_step() { ((STEP++)); printf "[ %d/%d ]" "$STEP" "$STEPS"; }

# ── Preflight check ──────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════╗"
echo "║       Lifelog  •  Demo Reset         ║"
echo "╚══════════════════════════════════════╝"
echo ""

if ! command -v adb &>/dev/null; then
  echo "ERROR: adb not found. Add Android SDK platform-tools to your PATH."
  exit 1
fi

DEVICE_COUNT=$($ADB devices 2>/dev/null | grep -c "device$" || true)
if [[ "$DEVICE_COUNT" -eq 0 ]]; then
  echo "ERROR: No Android device/emulator connected."
  echo "  • Start an emulator, or"
  echo "  • Connect a device with USB debugging enabled."
  exit 1
fi

echo "Device found. Starting reset..."
echo ""

# ── Flutter clean (optional) ─────────────────────────────────────────────────
if [[ "$FULL_CLEAN" == true ]]; then
  echo "$(next_step) Running flutter clean in lifelog/..."
  if command -v flutter &>/dev/null; then
    (cd "$FLUTTER_DIR" && flutter clean)
    echo "        Build artifacts removed."
  else
    echo "        WARNING: flutter not found in PATH. Skipping flutter clean."
  fi
fi

# ── Clear all app data ───────────────────────────────────────────────────────
# `pm clear` is equivalent to Settings → Apps → Lifelog → Clear Data.
# It wipes everything: SQLite databases, SharedPreferences, cache, files.
# Works on non-rooted devices. Also force-stops the app automatically.
echo "$(next_step) Clearing all app data for $PACKAGE..."
$ADB shell pm clear "$PACKAGE"
echo "        Cleared: SQLite DB (9 tables), SharedPreferences,"
echo "                 FCM token, cached images, app files."

# ── Push test receipt image (optional) ──────────────────────────────────────
# Use --push-test-receipt to ensure the test scan image is on the device.
# The image is pushed to /sdcard/Pictures/ and the media scanner is run so
# it appears immediately in the gallery picker.
if [[ "$PUSH_TEST_RECEIPT" == true ]]; then
  echo "$(next_step) Setting up test receipt image..."
  if [[ -f "$LOCAL_TEST_RECEIPT" ]]; then
    $ADB push "$LOCAL_TEST_RECEIPT" "$DEVICE_TEST_RECEIPT"
    # Trigger media scan so the image appears in the gallery picker immediately.
    $ADB shell am broadcast \
      -a android.intent.action.MEDIA_SCANNER_SCAN_FILE \
      -d "file://$DEVICE_TEST_RECEIPT" &>/dev/null || true
    echo "        Pushed to: $DEVICE_TEST_RECEIPT"
    echo "        Ready to select from gallery in the scan flow."
  else
    # Image not local — check if it's already on the device (e.g. already on the VM).
    FOUND=$($ADB shell find /sdcard -iname "restaurant*test*" 2>/dev/null | head -1 || true)
    if [[ -n "$FOUND" ]]; then
      echo "        Test receipt already on device at: $FOUND"
    else
      echo "        WARNING: Test receipt not found locally at:"
      echo "          $LOCAL_TEST_RECEIPT"
      echo "        and not found on device. Copy the image there and re-run,"
      echo "        or place it at: $DEVICE_TEST_RECEIPT on the device manually."
    fi
  fi
fi

# ── Launch ───────────────────────────────────────────────────────────────────
if [[ "$LAUNCH" == true ]]; then
  echo "$(next_step) Launching app..."
  $ADB shell monkey -p "$PACKAGE" -c android.intent.category.LAUNCHER 1 &>/dev/null
  echo "        App launched."
else
  echo "$(next_step) Skipping launch (--no-launch)."
fi

# ── (Optional) Backend demo reset ────────────────────────────────────────────
# Uncomment when the backend exposes a reset endpoint:
# echo "$(next_step) Resetting backend demo data..."
# curl -sf -X POST "$BACKEND_URL/api/demo/reset/" \
#   && echo "        Backend cleared." \
#   || echo "        WARNING: Backend reset failed (endpoint may not exist)."

echo ""
echo "Done. Lifelog is reset — onboarding, empty DB, no budget."
if [[ "$PUSH_TEST_RECEIPT" == true ]]; then
  echo ""
  echo "Receipt scan test:"
  echo "  1. Complete onboarding"
  echo "  2. Tap Expenses → + → Scan Receipt → Gallery"
  echo "  3. Select 'restaurant test.jpg' from Pictures"
fi
echo ""
echo "Note: Device-side data is cleared. If the backend at"
echo "  $BACKEND_URL has data tied to this device (e.g. FCM tokens),"
echo "  clear it manually or add a /api/demo/reset/ endpoint."
echo ""
