// integration_test/settings_test.dart
//
// End-to-end tests for the settings page.
//
// Run:
//   flutter test integration_test/settings_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lifelog/core/routes/app_routes.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(() async {
    await initTestBinding();
  });

  // ── Helper: open Settings from dashboard ──────────────────────────────────
  Future<void> openSettings(WidgetTester tester) async {
    await pumpApp(tester, AppRoutes.dashboard);
    await waitFor(tester, find.text('Hello,'), timeoutSecs: 10);
    await tapAndSettle(tester, find.byTooltip('Settings / Menu'));
    await waitFor(tester, find.text('Settings'),
        timeoutSecs: 5, reason: 'Settings page did not appear');
  }

  // ── 1. Toggle push notifications ─────────────────────────────────────────
  testWidgets(
    'settings: toggle push notifications on and off',
    (tester) async {
      await openSettings(tester);

      // Find the notifications switch.
      final notifTile = find.widgetWithText(SwitchListTile, 'Push Notifications');
      await waitFor(tester, notifTile,
          timeoutSecs: 5, reason: 'Push Notifications tile not found');

      final switchFinder = find.descendant(
          of: notifTile, matching: find.byType(Switch));

      // Capture initial state.
      final initialValue =
          (tester.widget(switchFinder) as Switch).value;

      // Toggle off.
      await tapAndSettle(tester, switchFinder);
      expect((tester.widget(switchFinder) as Switch).value, !initialValue,
          reason: 'Switch did not toggle');

      // Toggle back on.
      await tapAndSettle(tester, switchFinder);
      expect((tester.widget(switchFinder) as Switch).value, initialValue,
          reason: 'Switch did not toggle back');
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );

  // ── 2. Toggle auto in-progress ────────────────────────────────────────────
  testWidgets(
    'settings: toggle auto in-progress on and off',
    (tester) async {
      await openSettings(tester);

      final autoTile = find.widgetWithText(SwitchListTile, 'Auto In-Progress');
      await waitFor(tester, autoTile,
          timeoutSecs: 5, reason: 'Auto In-Progress tile not found');

      final switchFinder = find.descendant(
          of: autoTile, matching: find.byType(Switch));

      final initialValue =
          (tester.widget(switchFinder) as Switch).value;

      // Toggle.
      await tapAndSettle(tester, switchFinder);
      expect((tester.widget(switchFinder) as Switch).value, !initialValue,
          reason: 'Auto In-Progress switch did not toggle');

      // Restore.
      await tapAndSettle(tester, switchFinder);
      expect((tester.widget(switchFinder) as Switch).value, initialValue,
          reason: 'Auto In-Progress switch did not restore');
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );

  // ── 3. Change swipe action via bottom sheet ───────────────────────────────
  testWidgets(
    'settings: change swipe left-to-right action to Delete',
    (tester) async {
      await openSettings(tester);

      // Tap the "Swipe Left → Right" list tile.
      await waitFor(tester, find.text('Swipe Left \u2192 Right'),
          timeoutSecs: 5, reason: 'Swipe LTR tile not found');
      await tapAndSettle(tester, find.text('Swipe Left \u2192 Right'));

      // Bottom sheet should appear with action options.
      await waitFor(tester, find.text('Mark Completed'),
          timeoutSecs: 3, reason: 'Swipe action picker did not appear');
      expect(find.text('Mark In Progress'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      // Select "Delete".
      await tapAndSettle(tester, find.text('Delete'));

      // Bottom sheet should close, subtitle should update.
      await waitFor(tester, find.text('Swipe Left \u2192 Right'),
          timeoutSecs: 3);
      expect(
        find.descendant(
          of: find.widgetWithText(ListTile, 'Swipe Left \u2192 Right'),
          matching: find.text('Delete'),
        ),
        findsOneWidget,
        reason: 'Swipe LTR subtitle did not update to Delete',
      );

      // Restore to "Mark Completed" so later tests start clean.
      await tapAndSettle(tester, find.text('Swipe Left \u2192 Right'));
      await waitFor(tester, find.text('Mark Completed'), timeoutSecs: 3);
      await tapAndSettle(tester, find.text('Mark Completed'));
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );

  // ── 4. Navigate to alias management ──────────────────────────────────────
  testWidgets(
    'settings: navigate to alias management page',
    (tester) async {
      await openSettings(tester);

      // Tap Manage Aliases.
      await waitFor(tester, find.text('Manage Aliases'),
          timeoutSecs: 5, reason: 'Manage Aliases tile not found');
      await tapAndSettle(tester, find.text('Manage Aliases'));

      // AliasManagementPage should appear.
      await waitFor(tester, find.text('Item Aliases'),
          timeoutSecs: 5, reason: 'Item Aliases tab not found');
      expect(find.text('Store Aliases'), findsWidgets,
          reason: 'Store Aliases tab not found');

      // Navigate back.
      await tapAndSettle(tester, find.byIcon(Icons.arrow_back));
      await waitFor(tester, find.text('Settings'),
          timeoutSecs: 5, reason: 'Did not return to Settings page');
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );

  // ── 5. Toggle donate aliases ──────────────────────────────────────────────
  testWidgets(
    'settings: toggle donate aliases (backend call fails silently)',
    (tester) async {
      await openSettings(tester);

      // Scroll down to find Donate Aliases (it's near the bottom).
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pump();

      final donateTile =
          find.widgetWithText(SwitchListTile, 'Donate Aliases');
      await waitFor(tester, donateTile,
          timeoutSecs: 5, reason: 'Donate Aliases tile not found');

      final switchFinder = find.descendant(
          of: donateTile, matching: find.byType(Switch));

      final initialValue =
          (tester.widget(switchFinder) as Switch).value;

      // Toggle — backend call will fail silently.
      await tapAndSettle(tester, switchFinder);

      // Value should change locally even without backend.
      expect((tester.widget(switchFinder) as Switch).value, !initialValue,
          reason: 'Donate Aliases switch did not toggle locally');

      // Restore.
      await tapAndSettle(tester, switchFinder);
      expect((tester.widget(switchFinder) as Switch).value, initialValue,
          reason: 'Donate Aliases switch did not restore');
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );
}
