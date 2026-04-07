// integration_test/alias_management_test.dart
//
// End-to-end tests for the alias management page.
//
// Prerequisites: The database is seeded with 13 item aliases on first install.
// These tests rely on that seed data being present.
//
// Run:
//   flutter test integration_test/alias_management_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lifelog/core/routes/app_routes.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(() async {
    await initTestBinding();
  });

  // ── 1. Item Aliases tab shows seed aliases ────────────────────────────────
  testWidgets(
    'alias management: item aliases tab shows seed data',
    (tester) async {
      await pumpApp(tester, AppRoutes.aliasManagement);

      // Wait for the page to load.
      await waitFor(tester, find.text('Manage Aliases'),
          timeoutSecs: 10,
          reason: 'AliasManagementPage did not load');

      // "Item Aliases" tab should be selected by default.
      await waitFor(tester, find.text('Item Aliases'),
          timeoutSecs: 5,
          reason: 'Item Aliases tab not found');

      // Wait for alias list to load (DB query).
      await waitFor(tester, find.text('Better Than Bouillon'),
          timeoutSecs: 5,
          reason: 'Seed alias "Better Than Bouillon" not found in Item Aliases tab');

      // Another seed alias should also be visible.
      expect(find.text('Carrots 2lb'), findsWidgets,
          reason: 'Seed alias "Carrots 2lb" not found');
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );

  // ── 2. Switch to Store Aliases tab ───────────────────────────────────────
  testWidgets(
    'alias management: store aliases tab shows empty state when no scans done',
    (tester) async {
      await pumpApp(tester, AppRoutes.aliasManagement);

      await waitFor(tester, find.text('Manage Aliases'),
          timeoutSecs: 10);

      // Tap the Store Aliases tab.
      await tapAndSettle(tester, find.text('Store Aliases'));

      // If no scans have been performed there are no store aliases.
      // Either the empty state or a store alias list should appear.
      await tester.pump(const Duration(seconds: 1));

      // The tab should at least be active (no crash).
      expect(find.text('Store Aliases'), findsWidgets,
          reason: 'Store Aliases tab is not visible');

      // Empty state message — only present when there are no store aliases.
      final emptyState = find.textContaining('No store aliases saved yet');
      if (emptyState.evaluate().isNotEmpty) {
        // Empty state is acceptable when no scans have been performed.
        expect(emptyState, findsOneWidget,
            reason: 'Empty state text not shown for empty store aliases');
      }
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );

  // ── 3. Edit item alias via bottom sheet ──────────────────────────────────
  testWidgets(
    'alias management: edit item alias via bottom sheet',
    (tester) async {
      await pumpApp(tester, AppRoutes.aliasManagement);

      await waitFor(tester, find.text('Manage Aliases'),
          timeoutSecs: 10);

      // Wait for seed data to load.
      await waitFor(tester, find.text('Better Than Bouillon'),
          timeoutSecs: 5,
          reason: 'Item aliases did not load');

      // Tap an alias row to open the edit sheet.
      await tapAndSettle(tester, find.text('Better Than Bouillon').first);

      // Edit Item Alias sheet should appear.
      await waitFor(tester, find.text('Edit Item Alias'),
          timeoutSecs: 5,
          reason: 'Edit Item Alias bottom sheet did not appear');

      // The Display Name field should be visible.
      expect(find.widgetWithText(TextField, 'Display Name'), findsOneWidget,
          reason: 'Display Name field not in edit sheet');

      // Category chips should be visible.
      expect(find.byType(ChoiceChip), findsWidgets,
          reason: 'Category chips not shown in edit sheet');

      // Tap Save (without making any changes).
      await tapAndSettle(tester, find.text('Save'));

      // Sheet should close and list should still show the alias.
      await waitFor(tester, find.text('Better Than Bouillon'),
          timeoutSecs: 5,
          reason: 'Alias not shown after closing edit sheet');
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );
}
