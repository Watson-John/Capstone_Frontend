// integration_test/manual_expense_test.dart
//
// End-to-end tests for manual expense entry (non-scan path).
//
// Run:
//   flutter test integration_test/manual_expense_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lifelog/core/routes/app_routes.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(() async {
    await initTestBinding();
  });

  // ── Helper: open the Add Manually page from expense tracker ──────────────
  Future<void> openAddManually(WidgetTester tester) async {
    await pumpApp(tester, AppRoutes.expenseTracker);

    // Wait for the Expenses page to load (FAB available).
    await waitFor(tester, find.byTooltip('Add expense'),
        timeoutSecs: 10,
        reason: 'Expense tracker FAB not found');

    // Tap FAB to open menu.
    await tapAndSettle(tester, find.byTooltip('Add expense'));

    // Wait for the "Add Manually" option to animate in.
    await waitFor(tester, find.text('Add Manually'),
        timeoutSecs: 3,
        reason: '"Add Manually" option not found in FAB menu');

    // Tap Add Manually.
    await tapAndSettle(tester, find.text('Add Manually'));

    // Wait for AddExpensePage to appear.
    await waitFor(tester, find.text('Add Expense'),
        timeoutSecs: 5,
        reason: 'AddExpensePage did not appear');
  }

  // ── 1. Add expense with required fields ───────────────────────────────────
  testWidgets(
    'manual expense: add expense with required fields',
    (tester) async {
      await openAddManually(tester);

      // Enter amount.
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Amount'), '25.50');
      await tester.pump();

      // Enter vendor.
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Vendor / Store'), 'Coffee Shop');
      await tester.pump();

      // Select category from dropdown.
      await tapAndSettle(tester, find.widgetWithText(DropdownButtonFormField<String>, 'Category'));
      await waitFor(tester, find.text('Dining'),
          timeoutSecs: 3,
          reason: 'Category dropdown items not visible');
      await tapAndSettle(tester, find.text('Dining').last);

      // Tap Save in AppBar.
      await tapAndSettle(tester, find.text('Save'));

      // Should return to expense tracker.
      await waitFor(tester, find.byTooltip('Add expense'),
          timeoutSecs: 5,
          reason: 'Did not return to expense tracker after saving');

      // Verify vendor appears in the transactions list.
      await waitFor(tester, find.text('Coffee Shop'),
          timeoutSecs: 5,
          reason: '"Coffee Shop" not found in expense list');
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );

  // ── 2. Validation errors on empty form ───────────────────────────────────
  testWidgets(
    'manual expense: validation requires amount, vendor, and category',
    (tester) async {
      await openAddManually(tester);

      // Tap Save immediately without filling anything.
      await tapAndSettle(tester, find.text('Save'));

      // Form should still be visible with validation errors.
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Enter an amount'), findsOneWidget,
          reason: 'Amount validation error not shown');
      expect(find.text('Enter a vendor name'), findsOneWidget,
          reason: 'Vendor validation error not shown');
      expect(find.text('Select a category'), findsOneWidget,
          reason: 'Category validation error not shown');

      // Still on AddExpensePage.
      expect(find.text('Add Expense'), findsOneWidget,
          reason: 'Page should remain on AddExpensePage after validation failure');
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );

  // ── 3. Add expense with line items ────────────────────────────────────────
  testWidgets(
    'manual expense: add expense with line items auto-calculates total',
    (tester) async {
      await openAddManually(tester);

      // Expand line items section.
      await tapAndSettle(tester, find.text('Line Items (optional)'));

      // Tap "Add Item".
      await waitFor(tester, find.text('Add Item'),
          timeoutSecs: 3,
          reason: '"Add Item" button not visible');
      await tapAndSettle(tester, find.text('Add Item'));

      // Wait for the line item card to appear.
      await waitFor(tester, find.text('Item name'),
          timeoutSecs: 3,
          reason: 'Line item card did not appear');

      // Enter item name.
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Item name').first, 'Coffee');
      await tester.pump();

      // Enter item price — find the Price field inside the card.
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Price').first, '5.75');
      await tester.pump(const Duration(milliseconds: 300));

      // Total in the Amount field should now be 5.75.
      await waitFor(tester, find.textContaining('5.75'),
          timeoutSecs: 3,
          reason: 'Auto-calculated total not reflected in amount field');

      // Enter vendor.
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Vendor / Store'), 'Test Café');
      await tester.pump();

      // Tap Save.
      await tapAndSettle(tester, find.text('Save'));

      // Should return to expense tracker.
      await waitFor(tester, find.byTooltip('Add expense'),
          timeoutSecs: 5,
          reason: 'Did not return to expense tracker after saving with line items');

      // Verify vendor appears.
      await waitFor(tester, find.text('Test Café'),
          timeoutSecs: 5,
          reason: '"Test Café" not found in expense list');
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );
}
