// integration_test/todo_list_test.dart
//
// End-to-end tests for the to-do list feature.
//
// Run:
//   flutter test integration_test/todo_list_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lifelog/core/routes/app_routes.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(() async {
    await initTestBinding();
  });

  // ── 1. Add a basic task and verify it appears ─────────────────────────────
  testWidgets(
    'todo: add a basic task and verify it appears',
    (tester) async {
      await pumpApp(tester, AppRoutes.todoList);

      // Wait for the To-Do List page to load.
      await waitFor(tester, find.text('To-Do List'),
          timeoutSecs: 10,
          reason: 'To-Do List page did not load');

      // Tap the FAB to open AddTodoPage.
      await tapAndSettle(tester, find.byTooltip('Add'));

      // Verify AddTodoPage appeared.
      await waitFor(tester, find.text('Add Your Task'),
          timeoutSecs: 5,
          reason: 'AddTodoPage did not appear');

      // Enter a task title.
      final titleField = find.widgetWithText(TextField, 'Title');
      await tester.enterText(titleField, 'Buy groceries');
      await tester.pump();

      // Tap "Add Task" to save.
      await tapAndSettle(tester, find.text('Add Task'));

      // Wait for SnackBar confirmation.
      await waitFor(tester, find.text('Task added!'),
          timeoutSecs: 5,
          reason: 'Task added snackbar not shown');

      // Should return to the todo list.
      await waitFor(tester, find.text('To-Do List'),
          timeoutSecs: 5,
          reason: 'Did not return to todo list page');

      // Verify the task appears in the list.
      await waitFor(tester, find.text('Buy groceries'),
          timeoutSecs: 5,
          reason: 'Created task "Buy groceries" not found in the list');
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );

  // ── 2. Add all-day task with details ──────────────────────────────────────
  testWidgets(
    'todo: add all-day task with details',
    (tester) async {
      await pumpApp(tester, AppRoutes.todoList);

      await waitFor(tester, find.text('To-Do List'), timeoutSecs: 10);

      // Open AddTodoPage.
      await tapAndSettle(tester, find.byTooltip('Add'));
      await waitFor(tester, find.text('Add Your Task'), timeoutSecs: 5);

      // Toggle All Day switch on.
      final allDaySwitch = find.byType(Switch).first;
      await tapAndSettle(tester, allDaySwitch);

      // Enter title.
      await tester.enterText(
          find.widgetWithText(TextField, 'Title'), 'Team meeting');
      await tester.pump();

      // Enter details.
      await tester.enterText(
          find.widgetWithText(TextField, 'Details'), 'Weekly standup call');
      await tester.pump();

      // Save.
      await tapAndSettle(tester, find.text('Add Task'));

      // Wait for confirmation.
      await waitFor(tester, find.text('Task added!'),
          timeoutSecs: 5,
          reason: 'Task added snackbar not shown');

      // Verify the task appears.
      await waitFor(tester, find.text('Team meeting'),
          timeoutSecs: 5,
          reason: 'Created task "Team meeting" not found in the list');
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );

  // ── 3. Empty title prevents save ──────────────────────────────────────────
  testWidgets(
    'todo: empty title prevents save',
    (tester) async {
      await pumpApp(tester, AppRoutes.todoList);

      await waitFor(tester, find.text('To-Do List'), timeoutSecs: 10);

      // Open AddTodoPage.
      await tapAndSettle(tester, find.byTooltip('Add'));
      await waitFor(tester, find.text('Add Your Task'), timeoutSecs: 5);

      // Tap "Add Task" without entering a title.
      await tapAndSettle(tester, find.text('Add Task'));

      // Should still be on the AddTodoPage (no navigation, no snackbar).
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Add Your Task'), findsOneWidget,
          reason: 'Page should remain on AddTodoPage when title is empty');

      // The "Task added!" snackbar should NOT appear.
      expect(find.text('Task added!'), findsNothing,
          reason: 'Task should not be saved with empty title');
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );

  // ── 4. Add recurring task ─────────────────────────────────────────────────
  testWidgets(
    'todo: add recurring daily task',
    (tester) async {
      await pumpApp(tester, AppRoutes.todoList);

      await waitFor(tester, find.text('To-Do List'), timeoutSecs: 10);

      // Open AddTodoPage.
      await tapAndSettle(tester, find.byTooltip('Add'));
      await waitFor(tester, find.text('Add Your Task'), timeoutSecs: 5);

      // Enter title.
      await tester.enterText(
          find.widgetWithText(TextField, 'Title'), 'Morning workout');
      await tester.pump();

      // Toggle Recurring on — find the second Switch (first is All Day).
      final switches = find.byType(Switch);
      // The recurring switch is the one near the "RECURRING" label.
      // Scroll down first to make it visible.
      await tester.drag(
          find.byType(SingleChildScrollView), const Offset(0, -200));
      await tester.pump();

      await waitFor(tester, find.text('RECURRING'),
          timeoutSecs: 3,
          reason: 'RECURRING label not visible');

      // Tap the recurring switch (last Switch on the page).
      await tapAndSettle(tester, switches.last);

      // "Daily" chip should appear and be selected by default.
      await waitFor(tester, find.text('Daily'),
          timeoutSecs: 3,
          reason: 'Recurrence type chips not shown');

      // Save.
      // Scroll down to see the save button.
      await tester.drag(
          find.byType(SingleChildScrollView), const Offset(0, -100));
      await tester.pump();

      await tapAndSettle(tester, find.text('Add Task'));

      await waitFor(tester, find.text('Task added!'),
          timeoutSecs: 5,
          reason: 'Task added snackbar not shown for recurring task');

      // Verify task appears.
      await waitFor(tester, find.text('Morning workout'),
          timeoutSecs: 5,
          reason: 'Recurring task "Morning workout" not found in the list');
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );
}
