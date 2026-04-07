// integration_test/onboarding_test.dart
//
// End-to-end tests for the onboarding flow.
//
// Run:
//   flutter test integration_test/onboarding_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lifelog/core/routes/app_routes.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(() async {
    await initTestBinding();
  });

  // ── 1. Empty name validation ──────────────────────────────────────────────
  testWidgets(
    'onboarding: empty name shows validation snackbar',
    (tester) async {
      await pumpApp(tester, AppRoutes.onboarding);

      // Verify step 1 renders.
      await waitFor(tester, find.text('What should we call you by?'),
          timeoutSecs: 5,
          reason: 'Onboarding name step did not render');

      // Tap Continue without entering a name.
      await tapAndSettle(tester, find.text('Continue'));

      // Expect validation snackbar.
      await waitFor(tester, find.text('Please enter your name'),
          timeoutSecs: 3,
          reason: 'Empty-name validation snackbar not shown');
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );

  // ── 2. Full flow with budget ──────────────────────────────────────────────
  testWidgets(
    'onboarding: name → budget → dashboard',
    (tester) async {
      await pumpApp(tester, AppRoutes.onboarding);

      await waitFor(tester, find.text('What should we call you by?'),
          timeoutSecs: 5);

      // Enter name.
      await tester.enterText(
          find.widgetWithText(TextField, 'What should we call you by?'),
          'TestUser');
      await tester.pump();

      // Tap Continue to advance to step 2.
      await tapAndSettle(tester, find.text('Continue'));

      // Verify step 2 appears.
      await waitFor(tester, find.text('Set a Spending Limit'),
          timeoutSecs: 5,
          reason: 'Budget step did not appear after entering name');

      // Enter spending limit.
      await tester.enterText(
          find.widgetWithText(TextField, 'Spending Limit'), '500');
      await tester.pump();

      // Monthly should be selected by default — just tap Continue.
      await tapAndSettle(tester, find.text('Continue'));

      // Verify dashboard loaded (MainShell with "Hello," greeting).
      await waitFor(tester, find.text('Hello,'),
          timeoutSecs: 10,
          reason: 'Dashboard did not load after completing onboarding');
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );

  // ── 3. Skip budget ───────────────────────────────────────────────────────
  testWidgets(
    'onboarding: skip budget goes to dashboard',
    (tester) async {
      await pumpApp(tester, AppRoutes.onboarding);

      await waitFor(tester, find.text('What should we call you by?'),
          timeoutSecs: 5);

      // Enter name and continue.
      await tester.enterText(
          find.widgetWithText(TextField, 'What should we call you by?'),
          'SkipUser');
      await tester.pump();
      await tapAndSettle(tester, find.text('Continue'));

      // Wait for step 2.
      await waitFor(tester, find.text('Set a Spending Limit'),
          timeoutSecs: 5);

      // Tap Skip for now.
      await tapAndSettle(tester, find.text('Skip for now'));

      // Dashboard should load.
      await waitFor(tester, find.text('Hello,'),
          timeoutSecs: 10,
          reason: 'Dashboard did not load after skipping budget');
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );

  // ── 4. Bi-weekly budget period selection ──────────────────────────────────
  testWidgets(
    'onboarding: bi-weekly budget period selection',
    (tester) async {
      await pumpApp(tester, AppRoutes.onboarding);

      await waitFor(tester, find.text('What should we call you by?'),
          timeoutSecs: 5);

      // Enter name and continue.
      await tester.enterText(
          find.widgetWithText(TextField, 'What should we call you by?'),
          'BiweeklyUser');
      await tester.pump();
      await tapAndSettle(tester, find.text('Continue'));

      await waitFor(tester, find.text('Set a Spending Limit'),
          timeoutSecs: 5);

      // Enter limit.
      await tester.enterText(
          find.widgetWithText(TextField, 'Spending Limit'), '300');
      await tester.pump();

      // Select Bi-weekly.
      await tapAndSettle(tester, find.text('Bi-weekly'));

      // Tap Continue.
      await tapAndSettle(tester, find.text('Continue'));

      // Dashboard should load.
      await waitFor(tester, find.text('Hello,'),
          timeoutSecs: 10,
          reason: 'Dashboard did not load after bi-weekly budget setup');
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );
}
