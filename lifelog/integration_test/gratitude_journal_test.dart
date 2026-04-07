// integration_test/gratitude_journal_test.dart
//
// End-to-end tests for the gratitude journal feature.
//
// Run:
//   flutter test integration_test/gratitude_journal_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lifelog/core/routes/app_routes.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(() async {
    await initTestBinding();
  });

  // ── 1. Journal page loads with prompt card ────────────────────────────────
  testWidgets(
    'gratitude: journal page renders with today\'s prompt card',
    (tester) async {
      await pumpApp(tester, AppRoutes.gratitudeJournal);

      // Wait for the Gratitude Journal page to load.
      await waitFor(tester, find.text('Gratitude Journal'),
          timeoutSecs: 10,
          reason: 'Gratitude Journal page did not load');

      // The prompt card should always show (has a local fallback).
      await waitFor(tester, find.text("Today's Prompt"),
          timeoutSecs: 5,
          reason: 'Today\'s Prompt card not found');
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );

  // ── 2. Add entry with body and tags ──────────────────────────────────────
  testWidgets(
    'gratitude: add entry with body and tags',
    (tester) async {
      await pumpApp(tester, AppRoutes.gratitudeJournal);

      await waitFor(tester, find.text('Gratitude Journal'),
          timeoutSecs: 10);

      // Tap the FAB to open AddGratitudePage.
      await tapAndSettle(tester, find.byTooltip('Add'));

      // Verify AddGratitudePage appeared.
      await waitFor(tester, find.text('What are you grateful for?'),
          timeoutSecs: 5,
          reason: 'AddGratitudePage did not appear');

      // Enter journal body.
      await tester.enterText(
          find.widgetWithText(TextField,
              'Write freely — this is just for you...'),
          'I am grateful for my health and my family.');
      await tester.pump();

      // Tap tags: "family" and "health".
      await tapAndSettle(tester, find.text('family'));
      await tapAndSettle(tester, find.text('health'));

      // Tap "Save Entry".
      await tapAndSettle(tester, find.text('Save Entry'));

      // Should return to the journal page.
      await waitFor(tester, find.text('Gratitude Journal'),
          timeoutSecs: 5,
          reason: 'Did not return to Gratitude Journal page after save');

      // Verify the entry text appears in the list.
      await waitFor(
          tester,
          find.textContaining('I am grateful for my health'),
          timeoutSecs: 5,
          reason: 'Created entry text not found on the journal page');
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );

  // ── 3. Empty body shows validation snackbar ───────────────────────────────
  testWidgets(
    'gratitude: empty body shows validation snackbar',
    (tester) async {
      await pumpApp(tester, AppRoutes.gratitudeJournal);

      await waitFor(tester, find.text('Gratitude Journal'),
          timeoutSecs: 10);

      // Open AddGratitudePage.
      await tapAndSettle(tester, find.byTooltip('Add'));
      await waitFor(tester, find.text('What are you grateful for?'),
          timeoutSecs: 5);

      // Tap "Save Entry" without entering any text.
      await tapAndSettle(tester, find.text('Save Entry'));

      // Expect validation snackbar.
      await waitFor(
          tester, find.text('Please write something before saving.'),
          timeoutSecs: 3,
          reason: 'Empty-body validation snackbar not shown');

      // Should remain on AddGratitudePage.
      expect(find.text('What are you grateful for?'), findsOneWidget,
          reason: 'Page should remain on AddGratitudePage when body is empty');
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );
}
