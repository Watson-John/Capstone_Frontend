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
#   --no-seed                Skip inserting demo data (todos, mood, gratitude)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLUTTER_DIR="$SCRIPT_DIR/lifelog"

PACKAGE="com.example.lifelog"
LAUNCH=true
DEVICE_ARG=""
FULL_CLEAN=false
BACKEND_URL=""
PUSH_TEST_RECEIPT=false
SEED_DATA=true

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
    --no-seed)             SEED_DATA=false; shift ;;
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
if [[ "$SEED_DATA" == true ]]; then ((STEPS++)); fi
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

# ── Seed demo data (skip with --no-seed) ────────────────────────────────────
# Inserts realistic todos, mood entries, and gratitude entries so the app
# looks lived-in during demos. Dates are computed relative to today so the
# data always appears recent regardless of when the script is run.
# Active todos span today so they appear on the default "today" view.
#
# Technique: build the SQLite DB on the *host* (macOS sqlite3), then push the
# binary .db file to the device via `adb push` + `run-as cp`. This avoids
# needing sqlite3 on the device (removed in API 34+) and sidesteps scoped-
# storage restrictions.
if [[ "$SEED_DATA" == true ]]; then
  echo "$(next_step) Seeding demo data (todos, mood, gratitude)..."

  if ! command -v sqlite3 &>/dev/null; then
    echo "        ERROR: sqlite3 not found on host. Install it or use --no-seed."
  else
    # Compute dates relative to today (macOS BSD date -v syntax)
    D_7=$(date -v-7d "+%Y-%m-%dT")
    D_6=$(date -v-6d "+%Y-%m-%dT")
    D_5=$(date -v-5d "+%Y-%m-%dT")
    D_4=$(date -v-4d "+%Y-%m-%dT")
    D_3=$(date -v-3d "+%Y-%m-%dT")
    D_2=$(date -v-2d "+%Y-%m-%dT")
    D_1=$(date -v-1d "+%Y-%m-%dT")
    D0=$(date "+%Y-%m-%dT")
    D3=$(date -v+3d "+%Y-%m-%dT")
    D5=$(date -v+5d "+%Y-%m-%dT")
    D7=$(date -v+7d "+%Y-%m-%dT")
    RANGE_START=$(date -v-7d "+%b %-d")
    RANGE_END=$(date "+%b %-d")

    # Build SQL: full schema (sqflite version 13) + seed data
    SEED_SQL=$(mktemp /tmp/lifelog_seed_XXXXXXXX)
    cat > "$SEED_SQL" << ENDSEED
-- Lifelog DB schema (matches sqflite version 13) + demo seed data
PRAGMA user_version = 13;
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS expenses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  amount REAL NOT NULL,
  date TEXT NOT NULL,
  vendor TEXT NOT NULL,
  category TEXT NOT NULL,
  veryfi_document_id TEXT,
  created_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS budgets (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  limit_amount REAL NOT NULL,
  period TEXT NOT NULL,
  created_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS todos(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  task TEXT NOT NULL,
  details TEXT,
  startDate TEXT NOT NULL,
  dueDate TEXT NOT NULL,
  status TEXT NOT NULL,
  imagePath TEXT,
  priority TEXT NOT NULL DEFAULT 'Medium',
  isAllDay INTEGER NOT NULL DEFAULT 0,
  isRecurring INTEGER NOT NULL DEFAULT 0,
  recurrenceType TEXT,
  recurrenceDays TEXT,
  reminderMinutes INTEGER,
  category TEXT,
  subtasks TEXT
);
CREATE TABLE IF NOT EXISTS notifications(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  timestamp TEXT NOT NULL,
  isRead INTEGER NOT NULL
);
CREATE TABLE IF NOT EXISTS moodLog(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  description TEXT NOT NULL,
  mood TEXT NOT NULL,
  dateTime TEXT NOT NULL,
  emoji TEXT NOT NULL,
  energy TEXT,
  tags TEXT
);
CREATE TABLE IF NOT EXISTS receipt_line_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  expense_id INTEGER NOT NULL,
  receipt_acronym TEXT NOT NULL,
  decoded_name TEXT NOT NULL,
  category TEXT NOT NULL,
  price REAL NOT NULL,
  scan_order INTEGER NOT NULL,
  FOREIGN KEY (expense_id) REFERENCES expenses(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS user_aliases (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  receipt_acronym TEXT NOT NULL UNIQUE,
  decoded_name TEXT NOT NULL,
  category TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS store_aliases (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  vendor_name TEXT NOT NULL UNIQUE,
  category TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS gratitudeEntries (
  id       INTEGER PRIMARY KEY AUTOINCREMENT,
  body     TEXT    NOT NULL,
  prompt   TEXT,
  dateTime TEXT    NOT NULL,
  tags     TEXT
);

-- Demo seed data — dates relative to today (${RANGE_START} – ${RANGE_END})

INSERT INTO todos (task, details, startDate, dueDate, status, priority, isAllDay, isRecurring) VALUES
  ('Pay monthly bills',          NULL,                                    '${D_7}09:00:00.000', '${D_7}18:00:00.000', 'Completed',   'High',   0, 0),
  ('Buy groceries',              NULL,                                    '${D_6}11:00:00.000', '${D_6}20:00:00.000', 'Completed',   'Low',    0, 0),
  ('Review lecture notes',       'Chapters 7-9',                         '${D_5}10:00:00.000', '${D_5}17:00:00.000', 'Completed',   'Medium', 0, 0),
  ('Morning run',                NULL,                                    '${D_4}07:00:00.000', '${D_4}08:00:00.000', 'Completed',   'Medium', 0, 0),
  ('Call mom back',              NULL,                                    '${D_2}09:00:00.000', '${D3}18:00:00.000',  'To Do',       'Medium', 0, 0),
  ('Return library books',       NULL,                                    '${D_1}09:00:00.000', '${D5}17:00:00.000',  'To Do',       'Low',    0, 0),
  ('Schedule dentist appointment',NULL,                                   '${D_1}09:00:00.000', '${D5}17:00:00.000',  'In Progress', 'Medium', 0, 0),
  ('Finish capstone report draft','Introduction and methodology sections','${D_2}09:00:00.000', '${D7}17:00:00.000',  'In Progress', 'High',   0, 0);

INSERT INTO moodLog (description, mood, dateTime, emoji, energy, tags) VALUES
  ('Rough start to the week, feeling behind',  'bad',   '${D_6}08:30:00.000', '☹️',  'low',    'tired,stressed'),
  ('Getting back on track slowly',             'okay',  '${D_5}09:15:00.000', '😐', 'medium', 'calm'),
  ('Productive study session this morning',    'good',  '${D_4}08:45:00.000', '🙂', 'medium', 'focused,hopeful'),
  ('Great progress on the project today',      'great', '${D_3}10:00:00.000', '😄', 'high',   'excited,grateful'),
  ('Bit tired but managing',                   'okay',  '${D_2}09:30:00.000', '😐', 'low',    'tired,calm'),
  ('Nice morning walk, feeling motivated',     'good',  '${D_1}08:00:00.000', '🙂', 'high',   'focused,happy'),
  ('Wrapped up a solid week',                  'great', '${D0}09:00:00.000',  '😄', 'high',   'happy,grateful');

INSERT INTO gratitudeEntries (body, prompt, dateTime, tags) VALUES
  ('Grateful for a sunny morning walk that cleared my head before a long study session.',
   'What small moment made you smile today?',   '${D_4}21:00:00.000', 'nature,joy'),
  ('Thankful for my study group — their energy kept me going when I wanted to quit.',
   'Who supported you today?',                  '${D_3}20:30:00.000', 'friendship,growth'),
  ('Appreciated having a quiet evening to recharge with a good book and tea.',
   'What helped you rest and recover?',         '${D_2}21:15:00.000', 'peace,joy'),
  ('Grateful for real progress on the capstone — hard work is starting to pay off.',
   'What are you proud of this week?',          '${D_1}20:45:00.000', 'work,growth'),
  ('Thankful for family, health, and another week of learning.',
   'What are your three gratitudes today?',     '${D0}21:30:00.000',  'family,health,learning');
ENDSEED

    # Build the DB file locally on the host
    SEED_DB=$(mktemp /tmp/lifelog_db_XXXXXXXX)
    rm -f "$SEED_DB"   # sqlite3 needs to create it fresh
    if sqlite3 "$SEED_DB" < "$SEED_SQL" 2>&1; then
      # Verify locally before pushing
      TODO_COUNT=$(sqlite3 "$SEED_DB" "SELECT count(*) FROM todos;")
      MOOD_COUNT=$(sqlite3 "$SEED_DB" "SELECT count(*) FROM moodLog;")
      GRAT_COUNT=$(sqlite3 "$SEED_DB" "SELECT count(*) FROM gratitudeEntries;")

      # Push DB file to device temp dir, then copy into app data via run-as
      $ADB push "$SEED_DB" /data/local/tmp/lifelog_seed.db &>/dev/null
      $ADB shell "run-as $PACKAGE mkdir -p databases"
      $ADB shell "run-as $PACKAGE sh -c 'cat /data/local/tmp/lifelog_seed.db > databases/lifelog.db'"
      $ADB shell "rm -f /data/local/tmp/lifelog_seed.db"

      echo "        Inserted: $TODO_COUNT todos, $MOOD_COUNT mood entries, $GRAT_COUNT gratitude entries."
    else
      echo "        ERROR: Failed to build seed database on host."
    fi
    rm -f "$SEED_SQL" "$SEED_DB"
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
if [[ "$SEED_DATA" == true ]]; then
  SUMMARY_START=$(date -v-7d "+%b %-d")
  SUMMARY_END=$(date "+%b %-d")
  echo "Done. Lifelog is reset — onboarding flow, seeded with demo data."
  echo "  • To-Do:     8 tasks (4 completed, 2 in progress, 2 to do)"
  echo "  • Mood:      7 entries ($SUMMARY_START – $SUMMARY_END)"
  echo "  • Gratitude: 5 entries (last 4 days + today)"
  echo "  Tip: use --no-seed to skip data injection."
else
  echo "Done. Lifelog is reset — onboarding, empty DB, no budget."
fi
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
