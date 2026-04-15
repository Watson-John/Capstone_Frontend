import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_helper.dart';
import '../../features/gratitude_journal/domain/models/gratitude_entry.dart';
import 'local_notification_service.dart';

/// Unified action callback invoked by `awesome_notifications`. Handles both
/// foreground and background isolates — callers route through here via
/// `AwesomeNotifications().setListeners(onActionReceivedMethod: ...)`.
///
/// Background isolates don't share state with the UI isolate, but SQLite
/// access (via `sqflite`'s platform channels) and `SharedPreferences` both
/// work from a background isolate, so the `task_done` / `gratitude_reply`
/// mutations are safe from any lifecycle.
@pragma('vm:entry-point')
Future<void> onActionReceivedMethod(ReceivedAction action) async {
  try {
    final type = action.payload?['type'];
    final key = action.buttonKeyPressed;

    if (type == 'task' && key == kActionDone) {
      final id = _parseId(action.payload?['id']);
      if (id == null) return;
      final db = DatabaseHelper();
      final todos = await db.getTodos();
      final match = todos.where((t) => t.id == id).toList();
      if (match.isNotEmpty) {
        await db.updateTodo(match.first.copyWith(status: 'Completed'));
      }
      await AwesomeNotifications().cancel(id);
      return;
    }

    if (type == 'gratitude' && key == kActionReply) {
      final text = action.buttonKeyInput.trim();
      if (text.isEmpty) return;
      await DatabaseHelper().insertGratitudeEntry(GratitudeEntry(
        body: text,
        prompt: action.payload?['prompt'],
        dateTime: DateTime.now().toIso8601String(),
      ));
      await AwesomeNotifications().cancel(kGratitudeNotifId);
      return;
    }

    // Foreground / background (app alive) only. When the app was terminated
    // and relaunched via a tap, routing is handled instead by
    // `getInitialNotificationAction()` in `LocalNotificationService.init()`.
    if (action.actionLifeCycle != NotificationLifeCycle.Terminated) {
      if (type == 'task' && key == kActionSnooze) {
        final id = _parseId(action.payload?['id']);
        if (id == null) return;
        final prefs = await SharedPreferences.getInstance();
        final minutes = prefs.getInt(kSnoozeMinutesKey) ?? 10;
        await LocalNotificationService.instance.snoozeTask(
          id,
          Duration(minutes: minutes),
          title: action.payload?['title'] ?? 'Task reminder',
        );
        return;
      }

      if (key.isEmpty) {
        routePendingFromAction(action);
      }
    }
  } catch (e) {
    debugPrint('onActionReceivedMethod error: $e');
  }
}

/// Sets `pendingRoute` based on the notification's payload type. Used both
/// by the live-app tap handler and by the cold-launch bootstrapper in
/// `LocalNotificationService.init()`.
void routePendingFromAction(ReceivedAction action) {
  final type = action.payload?['type'];
  switch (type) {
    case 'task':
      pendingRoute.value = '/todo-list';
      break;
    case 'mood':
      pendingRoute.value = '/add-mood';
      break;
    case 'gratitude':
      pendingRoute.value = '/add-gratitude';
      break;
  }
}

int? _parseId(String? raw) {
  if (raw == null) return null;
  return int.tryParse(raw);
}
