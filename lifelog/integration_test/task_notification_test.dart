// integration_test/task_notification_test.dart
//
// Verifies that creating a Todo with a reminder schedules a pending
// local notification on the device. Regression coverage for the bug
// where exact-alarm scheduling silently dropped the notification when
// SCHEDULE_EXACT_ALARM permission was not granted.
//
// Run:
//   flutter test integration_test/task_notification_test.dart

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lifelog/core/database/database_helper.dart';
import 'package:lifelog/core/services/local_notification_service.dart';
import 'package:lifelog/features/todo_list/domain/models/todo_model.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(() async {
    await initTestBinding();
    // main.dart normally calls AwesomeNotifications().initialize() before
    // runApp — integration tests don't boot the app, so do it here.
    await AwesomeNotifications().initialize(
      'resource://drawable/ic_stat_notification',
      LocalNotificationService.buildChannels(),
      debug: true,
    );
    await LocalNotificationService.instance.init();
  });

  Future<List<NotificationModel>> pendingForId(int id) async {
    final scheduled = await AwesomeNotifications().listScheduledNotifications();
    return scheduled.where((m) => m.content?.id == id).toList();
  }

  testWidgets(
    'task reminder: scheduling a todo produces a pending notification',
    (tester) async {
      await AwesomeNotifications().cancelAll();

      final start = DateTime.now().add(const Duration(minutes: 5));
      final todo = Todo(
        task: 'Reminder regression test',
        startDate: start,
        dueDate: start.add(const Duration(hours: 1)),
        status: 'To Do',
        reminderMinutes: 1,
      );

      final id = await DatabaseHelper().insertTodo(todo);
      final saved = todo.copyWith(id: id);
      await LocalNotificationService.instance.scheduleTaskReminder(saved);

      final match = await pendingForId(id);
      final allScheduled =
          await AwesomeNotifications().listScheduledNotifications();

      expect(
        match,
        hasLength(1),
        reason:
            'Expected one pending notification for todo id=$id after '
            'scheduleTaskReminder, but found ${allScheduled.length} total '
            '(ids=${allScheduled.map((m) => m.content?.id).toList()}). '
            'This usually means the schedule was rejected — check '
            'SCHEDULE_EXACT_ALARM permission and the fallback path in '
            'LocalNotificationService._scheduleSafely.',
      );

      final content = match.first.content!;
      expect(content.title, equals('Reminder regression test'));
      expect(content.payload?['type'], equals('task'));
      expect(content.payload?['id'], equals(id.toString()));

      await LocalNotificationService.instance.cancelTaskReminder(id);
      await DatabaseHelper().deleteTodo(id);
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );

  testWidgets(
    'task reminder: reminder with fire time already past but start still '
    'in the future still schedules (near-now fallback)',
    (tester) async {
      await AwesomeNotifications().cancelAll();

      // Start in 30 seconds, reminder = 5 min before → fireAt is ~4.5 min
      // in the past. Production code should fall back to firing ~2s from
      // now rather than cancelling.
      final start = DateTime.now().add(const Duration(seconds: 30));
      final todo = Todo(
        task: 'Near-now reminder',
        startDate: start,
        dueDate: start.add(const Duration(hours: 1)),
        status: 'To Do',
        reminderMinutes: 5,
      );

      final id = await DatabaseHelper().insertTodo(todo);
      final saved = todo.copyWith(id: id);
      await LocalNotificationService.instance.scheduleTaskReminder(saved);

      final match = await pendingForId(id);

      expect(
        match,
        hasLength(1),
        reason:
            'Near-now reminder should be scheduled (~2s from now) when the '
            'reminder moment is in the past but the task itself still lies '
            'in the future.',
      );

      await LocalNotificationService.instance.cancelTaskReminder(id);
      await DatabaseHelper().deleteTodo(id);
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );

  testWidgets(
    'task reminder: scheduled notification actually posts to the status bar',
    (tester) async {
      await AwesomeNotifications().cancelAll();

      // Schedule a task whose reminder fires ~3 seconds from now. This is
      // the only reliable way to verify end-to-end delivery — listScheduled
      // just proves it was queued, not that the OS actually posted it.
      final start = DateTime.now().add(const Duration(seconds: 3));
      final todo = Todo(
        task: 'Delivery test',
        startDate: start,
        dueDate: start.add(const Duration(hours: 1)),
        status: 'To Do',
        reminderMinutes: 0,
      );
      final id = await DatabaseHelper().insertTodo(todo);
      final saved = todo.copyWith(id: id);
      await LocalNotificationService.instance.scheduleTaskReminder(saved);

      // Poll the status-bar active list. Up to 30s because emulator Doze can
      // add latency even when awake.
      final deadline = DateTime.now().add(const Duration(seconds: 30));
      List<int> activeIds = [];
      while (DateTime.now().isBefore(deadline)) {
        await Future.delayed(const Duration(seconds: 1));
        await tester.pump(const Duration(milliseconds: 100));
        activeIds = await AwesomeNotifications()
            .getAllActiveNotificationIdsOnStatusBar();
        if (activeIds.contains(id)) break;
      }

      expect(
        activeIds.contains(id),
        isTrue,
        reason:
            'Task notification id=$id was scheduled but never showed up in '
            'the status bar within 30s. Active ids: $activeIds. Most likely '
            'causes: (a) channel importance muted, (b) POST_NOTIFICATIONS '
            'runtime permission denied, (c) precise-alarm fallback did not '
            'fire inside the polling window.',
      );

      await AwesomeNotifications().cancel(id);
      await DatabaseHelper().deleteTodo(id);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets(
    'task reminder: cancelling a task removes the pending notification',
    (tester) async {
      await AwesomeNotifications().cancelAll();

      final start = DateTime.now().add(const Duration(minutes: 10));
      final todo = Todo(
        task: 'To be cancelled',
        startDate: start,
        dueDate: start.add(const Duration(hours: 1)),
        status: 'To Do',
        reminderMinutes: 5,
      );

      final id = await DatabaseHelper().insertTodo(todo);
      final saved = todo.copyWith(id: id);
      await LocalNotificationService.instance.scheduleTaskReminder(saved);

      expect(await pendingForId(id), hasLength(1));

      await LocalNotificationService.instance.cancelTaskReminder(id);

      expect(
        await pendingForId(id),
        isEmpty,
        reason: 'Cancelling a task should remove its pending notification.',
      );

      await DatabaseHelper().deleteTodo(id);
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );
}
