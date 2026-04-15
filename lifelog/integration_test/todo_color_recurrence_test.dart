// integration_test/todo_color_recurrence_test.dart
//
// Tests for:
//   1. Color label left-bar on task cards
//   2. Calendar dot colors matching category
//   3. Weekly recurring tasks appear only on correct days
//
// Run:
//   flutter test integration_test/todo_color_recurrence_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lifelog/core/routes/app_routes.dart';
import 'package:lifelog/core/database/database_helper.dart';
import 'package:lifelog/features/todo_list/domain/models/todo_model.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(() async {
    await initTestBinding();
  });

  // ── 1. Color label changes the left bar on the task card ─────────────────
  testWidgets(
    'todo: color label foreground appears on card left bar',
    (tester) async {
      // Insert a task with a GROCERY category directly into the DB.
      final db = DatabaseHelper();
      final today = DateTime.now();
      await db.insertTodo(Todo(
        task: 'Grocery run',
        startDate: today,
        dueDate: today.add(const Duration(hours: 2)),
        status: 'To Do',
        category: 'GROCERY', // foreground: Color(0xFF2E7D5A)
      ));

      await pumpApp(tester, AppRoutes.todoList);
      await waitFor(tester, find.text('Grocery run'), timeoutSecs: 10,
          reason: 'Task "Grocery run" not visible in list');

      // The GROCERY foreground color is 0xFF2E7D5A — confirm a Container with
      // that color is present in the tree (the left bar).
      const groceryFg = Color(0xFF2E7D5A);
      final coloredBar = find.byWidgetPredicate((widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).color == groceryFg);
      expect(coloredBar, findsWidgets,
          reason: 'Left bar should use GROCERY foreground color');
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );

  // ── 2. Calendar dots use category color ──────────────────────────────────
  testWidgets(
    'todo: calendar dot uses category color when label is set',
    (tester) async {
      // Task with DINING category was inserted in previous test; add another
      // with a different category to confirm per-task coloring.
      final db = DatabaseHelper();
      final today = DateTime.now();
      await db.insertTodo(Todo(
        task: 'Team dinner',
        startDate: today,
        dueDate: today.add(const Duration(hours: 3)),
        status: 'To Do',
        category: 'DINING', // foreground: Color(0xFFA04A35)
      ));

      await pumpApp(tester, AppRoutes.todoList);
      await waitFor(tester, find.text('To-Do List'), timeoutSecs: 10);

      // Expand calendar by tapping the month pill (e.g. "APRIL 2026").
      await tapAndSettle(tester, find.textContaining('2026').first);
      await tester.pump(const Duration(milliseconds: 400));

      // DINING foreground color should appear as a dot
      const diningFg = Color(0xFFA04A35);
      final diningDot = find.byWidgetPredicate((widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).shape == BoxShape.circle &&
          (widget.decoration as BoxDecoration).color == diningFg);
      expect(diningDot, findsWidgets,
          reason: 'Calendar dot should use DINING foreground color');
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );

  // ── 3. Weekly recurring task: appears only on selected days ──────────────
  testWidgets(
    'todo: weekly recurring task appears only on Mon/Wed/Fri',
    (tester) async {
      final db = DatabaseHelper();

      // Today is Friday Apr 10, 2026.
      // Mon=Apr 6, Tue=Apr 7, Wed=Apr 8, Thu=Apr 9, Fri=Apr 10, Sat=Apr 11, Sun=Apr 12.
      final startDate = DateTime(2026, 4, 6, 9, 0);   // Monday Apr 6
      final endDate   = DateTime(2026, 4, 20, 17, 0);  // Sunday Apr 20

      final taskId = await db.insertTodo(Todo(
        task: 'Weekly Standup',
        startDate: startDate,
        dueDate: endDate,
        status: 'To Do',
        isRecurring: true,
        recurrenceType: 'weekly',
        recurrenceDays: 'Mon,Wed,Fri',
      ));

      final inserted = Todo(
        id: taskId,
        task: 'Weekly Standup',
        startDate: startDate,
        dueDate: endDate,
        status: 'To Do',
        isRecurring: true,
        recurrenceType: 'weekly',
        recurrenceDays: 'Mon,Wed,Fri',
      );

      // Verify appearsOnDate logic directly (Apr 10 = Fri, so Mon=6 Wed=8 Fri=10).
      expect(inserted.appearsOnDate(DateTime(2026, 4, 6)),  isTrue,  reason: 'Mon Apr 6 should appear');
      expect(inserted.appearsOnDate(DateTime(2026, 4, 7)),  isFalse, reason: 'Tue Apr 7 should NOT appear');
      expect(inserted.appearsOnDate(DateTime(2026, 4, 8)),  isTrue,  reason: 'Wed Apr 8 should appear');
      expect(inserted.appearsOnDate(DateTime(2026, 4, 9)),  isFalse, reason: 'Thu Apr 9 should NOT appear');
      expect(inserted.appearsOnDate(DateTime(2026, 4, 10)), isTrue,  reason: 'Fri Apr 10 should appear');
      expect(inserted.appearsOnDate(DateTime(2026, 4, 11)), isFalse, reason: 'Sat Apr 11 should NOT appear');
      expect(inserted.appearsOnDate(DateTime(2026, 4, 12)), isFalse, reason: 'Sun Apr 12 should NOT appear');
      expect(inserted.appearsOnDate(DateTime(2026, 4, 13)), isTrue,  reason: 'Mon Apr 13 should appear');
      expect(inserted.appearsOnDate(DateTime(2026, 4, 14)), isFalse, reason: 'Tue Apr 14 should NOT appear');
      // Outside range
      expect(inserted.appearsOnDate(DateTime(2026, 4, 21)), isFalse, reason: 'After end date should NOT appear');
      expect(inserted.appearsOnDate(DateTime(2026, 4, 5)),  isFalse, reason: 'Before start date should NOT appear');

      // Load the to-do page on Friday Apr 10 (a recurrence day) and confirm task is visible.
      await pumpApp(tester, AppRoutes.todoList);
      // Today is Apr 10 (Fri), which is in the recurrence set.
      await waitFor(tester, find.text('Weekly Standup'), timeoutSecs: 10,
          reason: 'Recurring task should appear on Friday (a scheduled day)');
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );

  // ── 4. Weekly recurring: repeat icon present on card ─────────────────────
  testWidgets(
    'todo: recurring task card shows repeat icon',
    (tester) async {
      await pumpApp(tester, AppRoutes.todoList);
      await waitFor(tester, find.text('Weekly Standup'), timeoutSecs: 10);

      // Icons.repeat should appear for the recurring task card.
      expect(find.byIcon(Icons.repeat), findsWidgets,
          reason: 'Recurring task card should show a repeat icon');
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );
}
