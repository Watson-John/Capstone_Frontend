// integration_test/navigation_test.dart
//
// End-to-end tests for bottom navigation and app-bar navigation.
//
// Run:
//   flutter test integration_test/navigation_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lifelog/core/routes/app_routes.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(() async {
    await initTestBinding();
  });

  // ── 1. Bottom nav switches between all 5 tabs ────────────────────────────
  testWidgets(
    'navigation: bottom nav switches between all tabs',
    (tester) async {
      // Launch at Dashboard (tab index 2).
      await pumpApp(tester, AppRoutes.dashboard);

      // Dashboard should show "Hello," greeting.
      await waitFor(tester, find.text('Hello,'),
          timeoutSecs: 10,
          reason: 'Dashboard greeting not found');

      // ── To-Do tab (index 0) ──
      await tapAndSettle(tester, find.text('To-Do'));
      await waitFor(tester, find.text('To-Do List'),
          timeoutSecs: 5,
          reason: 'To-Do List page header not found');

      // ── Expenses tab (index 1) ──
      await tapAndSettle(tester, find.text('Expenses'));
      await waitFor(tester, find.text('Expenses'),
          timeoutSecs: 5,
          reason: 'Expenses page header not found');

      // ── Mood tab (index 3) ──
      await tapAndSettle(tester, find.text('Mood'));
      await waitFor(tester, find.text('Mood Logger'),
          timeoutSecs: 5,
          reason: 'Mood Logger page header not found');

      // ── Gratitude tab (index 4) ──
      await tapAndSettle(tester, find.text('Gratitude'));
      await waitFor(tester, find.text('Gratitude Journal'),
          timeoutSecs: 5,
          reason: 'Gratitude Journal page header not found');

      // ── Back to Dashboard (index 2) ──
      await tapAndSettle(tester, find.text('Dashboard'));
      await waitFor(tester, find.text('Hello,'),
          timeoutSecs: 5,
          reason: 'Dashboard did not reappear when re-selecting tab');
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );

  // ── 2. Settings accessible via gear icon ──────────────────────────────────
  testWidgets(
    'navigation: settings accessible via menu icon',
    (tester) async {
      await pumpApp(tester, AppRoutes.dashboard);

      await waitFor(tester, find.text('Hello,'), timeoutSecs: 10);

      // Tap the settings / menu icon.
      await tapAndSettle(tester, find.byTooltip('Settings / Menu'));

      // Verify Settings page appeared.
      await waitFor(tester, find.text('Settings'),
          timeoutSecs: 5,
          reason: 'Settings page did not appear');

      // Verify a settings-specific item is visible.
      expect(find.text('Push Notifications'), findsWidgets,
          reason: 'Push Notifications toggle not found on Settings page');

      // Navigate back.
      await tapAndSettle(tester, find.byIcon(Icons.arrow_back));

      // Dashboard should be back.
      await waitFor(tester, find.text('Hello,'),
          timeoutSecs: 5,
          reason: 'Dashboard did not reappear after leaving Settings');
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );

  // ── 3. Notifications accessible via bell icon ─────────────────────────────
  testWidgets(
    'navigation: notifications accessible via bell icon',
    (tester) async {
      await pumpApp(tester, AppRoutes.dashboard);

      await waitFor(tester, find.text('Hello,'), timeoutSecs: 10);

      // Tap the notifications icon.
      await tapAndSettle(tester, find.byTooltip('Notifications'));

      // Verify Notifications page appeared.
      await waitFor(tester, find.text('Notifications'),
          timeoutSecs: 5,
          reason: 'Notifications page did not appear');

      // Navigate back.
      await tapAndSettle(tester, find.byIcon(Icons.arrow_back));

      // Dashboard should be back.
      await waitFor(tester, find.text('Hello,'),
          timeoutSecs: 5,
          reason: 'Dashboard did not reappear after leaving Notifications');
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );
}
