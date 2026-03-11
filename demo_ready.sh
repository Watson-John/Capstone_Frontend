#!/usr/bin/env bash
# demo_ready.sh
# Resets the Lifelog app to a clean "fresh install" state on the connected
# Android device/emulator. Equivalent to "Clear Data" in Android Settings.
# Run this before any demo.
#
# Usage:
#   chmod +x demo_ready.sh   (first time only)
#   ./demo_ready.sh
#
# Optional flags:
#   --no-launch    Wipe data but don't relaunch the app
#   --device <id>  Target a specific device (from `adb devices`)

set -euo pipefail

PACKAGE="com.example.lifelog"
LAUNCH=true
DEVICE_ARG=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-launch) LAUNCH=false; shift ;;
    --device)    DEVICE_ARG="-s $2"; shift 2 ;;
    *) echo "Unknown flag: $1"; exit 1 ;;
  esac
done

ADB="adb $DEVICE_ARG"

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

# ── Clear all app data ───────────────────────────────────────────────────────
# `pm clear` is equivalent to Settings → Apps → Lifelog → Clear Data.
# It wipes everything: SQLite databases, SharedPreferences, cache, files.
# Works on non-rooted devices. Also force-stops the app automatically.
echo "[ 1/2 ] Clearing all app data for $PACKAGE..."
$ADB shell pm clear "$PACKAGE"

# ── Launch ───────────────────────────────────────────────────────────────────
if [[ "$LAUNCH" == true ]]; then
  echo "[ 2/2 ] Launching app..."
  $ADB shell monkey -p "$PACKAGE" -c android.intent.category.LAUNCHER 1 &>/dev/null
  echo "        App launched."
else
  echo "[ 2/2 ] Skipping launch (--no-launch)."
fi

echo ""
echo "Done. Lifelog is reset — onboarding, empty DB, no budget."
echo ""
