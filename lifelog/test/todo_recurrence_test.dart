// test/todo_recurrence_test.dart
//
// Unit tests for Todo.isActiveOn() – verifies that recurring todos appear
// on the correct dates for every supported recurrence permutation.
//
// Run:
//   flutter test test/todo_recurrence_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/todo_list/domain/models/todo_model.dart';

// Builds a minimal Todo for recurrence testing.
Todo _makeTodo({
  required DateTime startDate,
  DateTime? dueDate,
  bool isRecurring = false,
  String? recurrenceType,
  String? recurrenceDays,
}) {
  return Todo(
    task: 'Test task',
    startDate: startDate,
    dueDate: dueDate ?? DateTime(2099, 12, 31),
    status: 'To Do',
    isRecurring: isRecurring,
    recurrenceType: recurrenceType,
    recurrenceDays: recurrenceDays,
  );
}

void main() {
  // Reference week anchored on Monday 2026-04-06.
  // Dart DateTime.weekday: 1=Mon … 7=Sun
  final mon  = DateTime(2026, 4, 6);   // weekday 1
  final tue  = DateTime(2026, 4, 7);   // weekday 2
  final wed  = DateTime(2026, 4, 8);   // weekday 3
  final thu  = DateTime(2026, 4, 9);   // weekday 4
  final fri  = DateTime(2026, 4, 10);  // weekday 5
  final sat  = DateTime(2026, 4, 11);  // weekday 6
  final sun  = DateTime(2026, 4, 12);  // weekday 7
  final nextMon = DateTime(2026, 4, 13);
  final nextTue = DateTime(2026, 4, 14);
  final beforeStart = DateTime(2026, 4, 5); // Sunday before the week

  // ── 1. One-time (non-recurring) ───────────────────────────────────────────
  group('one-time task', () {
    test('appears only on its single date', () {
      final todo = _makeTodo(startDate: wed, dueDate: wed);
      expect(todo.isActiveOn(wed), isTrue);
      expect(todo.isActiveOn(tue), isFalse);
      expect(todo.isActiveOn(thu), isFalse);
    });

    test('appears throughout a multi-day range', () {
      final todo = _makeTodo(startDate: mon, dueDate: fri);
      expect(todo.isActiveOn(mon), isTrue);
      expect(todo.isActiveOn(wed), isTrue);
      expect(todo.isActiveOn(fri), isTrue);
      expect(todo.isActiveOn(beforeStart), isFalse);
      expect(todo.isActiveOn(sat), isFalse);
    });

    test('does not appear before start date', () {
      final todo = _makeTodo(startDate: thu, dueDate: thu);
      expect(todo.isActiveOn(beforeStart), isFalse);
      expect(todo.isActiveOn(wed), isFalse);
    });
  });

  // ── 2. Daily recurring ────────────────────────────────────────────────────
  group('daily recurring task', () {
    test('appears every day within open-ended range', () {
      final todo = _makeTodo(
        startDate: mon,
        isRecurring: true,
        recurrenceType: 'daily',
      );
      for (final day in [mon, tue, wed, thu, fri, sat, sun, nextMon]) {
        expect(todo.isActiveOn(day), isTrue,
            reason: 'daily task should be active on $day');
      }
    });

    test('does not appear before start date', () {
      final todo = _makeTodo(
        startDate: wed,
        isRecurring: true,
        recurrenceType: 'daily',
      );
      expect(todo.isActiveOn(beforeStart), isFalse);
      expect(todo.isActiveOn(tue), isFalse);
    });

    test('does not appear after due date', () {
      final todo = _makeTodo(
        startDate: mon,
        dueDate: wed,
        isRecurring: true,
        recurrenceType: 'daily',
      );
      expect(todo.isActiveOn(wed), isTrue);
      expect(todo.isActiveOn(thu), isFalse);
      expect(todo.isActiveOn(fri), isFalse);
    });
  });

  // ── 3. Weekly – Tuesday & Thursday ───────────────────────────────────────
  group('weekly Tue+Thu', () {
    late Todo todo;
    setUp(() {
      todo = _makeTodo(
        startDate: mon,
        isRecurring: true,
        recurrenceType: 'weekly',
        recurrenceDays: 'Tue,Thu',
      );
    });

    test('active on Tuesday',          () => expect(todo.isActiveOn(tue), isTrue));
    test('active on Thursday',         () => expect(todo.isActiveOn(thu), isTrue));
    test('active on next Tuesday',     () => expect(todo.isActiveOn(nextTue), isTrue));
    test('inactive on Monday',         () => expect(todo.isActiveOn(mon), isFalse));
    test('inactive on Wednesday',      () => expect(todo.isActiveOn(wed), isFalse));
    test('inactive on Friday',         () => expect(todo.isActiveOn(fri), isFalse));
    test('inactive on Saturday',       () => expect(todo.isActiveOn(sat), isFalse));
    test('inactive on Sunday',         () => expect(todo.isActiveOn(sun), isFalse));
  });

  // ── 4. Weekly – Monday, Wednesday, Friday ─────────────────────────────────
  group('weekly Mon+Wed+Fri', () {
    late Todo todo;
    setUp(() {
      todo = _makeTodo(
        startDate: mon,
        isRecurring: true,
        recurrenceType: 'weekly',
        recurrenceDays: 'Mon,Wed,Fri',
      );
    });

    test('active on Monday',           () => expect(todo.isActiveOn(mon), isTrue));
    test('active on Wednesday',        () => expect(todo.isActiveOn(wed), isTrue));
    test('active on Friday',           () => expect(todo.isActiveOn(fri), isTrue));
    test('active on next Monday',      () => expect(todo.isActiveOn(nextMon), isTrue));
    test('inactive on Tuesday',        () => expect(todo.isActiveOn(tue), isFalse));
    test('inactive on Thursday',       () => expect(todo.isActiveOn(thu), isFalse));
    test('inactive on Saturday',       () => expect(todo.isActiveOn(sat), isFalse));
    test('inactive on Sunday',         () => expect(todo.isActiveOn(sun), isFalse));
  });

  // ── 5. Weekly – Saturday & Sunday (weekends only) ─────────────────────────
  group('weekly Sat+Sun (weekends)', () {
    late Todo todo;
    setUp(() {
      todo = _makeTodo(
        startDate: mon,
        isRecurring: true,
        recurrenceType: 'weekly',
        recurrenceDays: 'Sat,Sun',
      );
    });

    test('active on Saturday',         () => expect(todo.isActiveOn(sat), isTrue));
    test('active on Sunday',           () => expect(todo.isActiveOn(sun), isTrue));
    test('inactive on Monday',         () => expect(todo.isActiveOn(mon), isFalse));
    test('inactive on Tuesday',        () => expect(todo.isActiveOn(tue), isFalse));
    test('inactive on Wednesday',      () => expect(todo.isActiveOn(wed), isFalse));
    test('inactive on Thursday',       () => expect(todo.isActiveOn(thu), isFalse));
    test('inactive on Friday',         () => expect(todo.isActiveOn(fri), isFalse));
  });

  // ── 6. Weekly – all 7 days (equivalent to daily) ─────────────────────────
  group('weekly all-days', () {
    test('appears every day of the week', () {
      final todo = _makeTodo(
        startDate: mon,
        isRecurring: true,
        recurrenceType: 'weekly',
        recurrenceDays: 'Mon,Tue,Wed,Thu,Fri,Sat,Sun',
      );
      for (final day in [mon, tue, wed, thu, fri, sat, sun]) {
        expect(todo.isActiveOn(day), isTrue,
            reason: 'all-days weekly should be active on $day');
      }
    });
  });

  // ── 7. Monthly ────────────────────────────────────────────────────────────
  group('monthly recurring task', () {
    // Start on the 15th so we can test same day across months.
    final start = DateTime(2026, 4, 15);

    late Todo todo;
    setUp(() {
      todo = _makeTodo(
        startDate: start,
        isRecurring: true,
        recurrenceType: 'monthly',
      );
    });

    test('active on start date', () => expect(todo.isActiveOn(start), isTrue));

    test('active on same day in subsequent months', () {
      expect(todo.isActiveOn(DateTime(2026, 5, 15)), isTrue);
      expect(todo.isActiveOn(DateTime(2026, 6, 15)), isTrue);
      expect(todo.isActiveOn(DateTime(2026, 12, 15)), isTrue);
    });

    test('inactive on other days of month', () {
      expect(todo.isActiveOn(DateTime(2026, 4, 14)), isFalse);
      expect(todo.isActiveOn(DateTime(2026, 4, 16)), isFalse);
      expect(todo.isActiveOn(DateTime(2026, 5, 14)), isFalse);
      expect(todo.isActiveOn(DateTime(2026, 5, 16)), isFalse);
    });

    test('inactive before start month', () {
      expect(todo.isActiveOn(DateTime(2026, 3, 15)), isFalse);
    });
  });
}
