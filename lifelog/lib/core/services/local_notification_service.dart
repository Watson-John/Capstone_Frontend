import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_helper.dart';
import '../../features/todo_list/domain/models/todo_model.dart';
import 'notification_action_handler.dart';

/// Channel keys
const String kTasksChannelKey = 'tasks_channel';
const String kMoodChannelKey = 'mood_channel';
const String kGratitudeChannelKey = 'gratitude_channel';

/// Reserved notification IDs
const int kMoodNotifId = 1000001;
const int kGratitudeNotifId = 1000002;

/// SharedPreferences keys
const String kMoodTimeKey = 'mood_reminder_time';
const String kGratitudeTimeKey = 'gratitude_reminder_time';
const String kGratitudeModeKey = 'gratitude_reminder_mode'; // 'on_release' | 'scheduled'
const String kSnoozeMinutesKey = 'task_snooze_minutes';

/// Per-category enable flags (default true). The master 'notifications_enabled'
/// still short-circuits all categories when off.
const String kTasksEnabledKey = 'notifications_tasks_enabled';
const String kMoodEnabledKey = 'notifications_mood_enabled';
const String kGratitudeEnabledKey = 'notifications_gratitude_enabled';

/// Action button keys
const String kActionSnooze = 'task_snooze';
const String kActionDone = 'task_done';
const String kActionReply = 'gratitude_reply';

/// Stream for foreground route navigation after tap (consumed in app.dart).
final ValueNotifier<String?> pendingRoute = ValueNotifier<String?>(null);

class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();
  factory LocalNotificationService() => instance;

  bool _initialized = false;
  bool _canScheduleExact = true;
  String _localTimeZone = 'UTC';

  /// Channel definitions, exposed so `main.dart` can pass them to
  /// `AwesomeNotifications().initialize(...)` before `runApp`.
  static List<NotificationChannel> buildChannels() {
    const brandColor = Color(0xFF6750A4);
    return [
      NotificationChannel(
        channelKey: kTasksChannelKey,
        channelName: 'Task Reminders',
        channelDescription: 'Reminders for scheduled tasks',
        importance: NotificationImportance.High,
        defaultColor: brandColor,
        ledColor: brandColor,
        icon: 'resource://drawable/ic_stat_notification',
      ),
      NotificationChannel(
        channelKey: kMoodChannelKey,
        channelName: 'Mood Logger',
        channelDescription: 'Daily mood check-in',
        importance: NotificationImportance.High,
        defaultColor: brandColor,
        ledColor: brandColor,
        icon: 'resource://drawable/ic_stat_notification',
      ),
      NotificationChannel(
        channelKey: kGratitudeChannelKey,
        channelName: 'Gratitude Journal',
        channelDescription: 'Daily gratitude prompt',
        importance: NotificationImportance.High,
        defaultColor: brandColor,
        ledColor: brandColor,
        icon: 'resource://drawable/ic_stat_notification',
      ),
    ];
  }

  Future<void> init() async {
    if (_initialized) return;

    try {
      _localTimeZone = await FlutterTimezone.getLocalTimezone();
    } catch (_) {
      _localTimeZone = 'UTC';
    }

    final allowed = await AwesomeNotifications().isNotificationAllowed();
    if (!allowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }

    // Cache whether precise alarms are currently granted. If not, scheduling
    // falls back to inexact mode rather than throwing.
    try {
      final granted = await AwesomeNotifications().checkPermissionList(
        permissions: const [NotificationPermission.PreciseAlarms],
      );
      _canScheduleExact = granted.contains(NotificationPermission.PreciseAlarms);
      debugPrint('canScheduleExactNotifications=$_canScheduleExact');
    } catch (e) {
      debugPrint('precise alarm check failed: $e');
    }

    await AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
    );

    // Cold-launch tap: if the app was terminated and the user tapped a
    // notification to launch it, the listener isn't fired — fetch the initial
    // action explicitly and route from it.
    try {
      final initialAction = await AwesomeNotifications()
          .getInitialNotificationAction(removeFromActionEvents: true);
      if (initialAction != null) {
        routePendingFromAction(initialAction);
      }
    } catch (e) {
      debugPrint('getInitialNotificationAction failed: $e');
    }

    _initialized = true;
  }

  /// IANA timezone identifier cached at init. Used for NotificationCalendar.
  String get localTimeZone => _localTimeZone;

  /// Wraps `createNotification` with a fallback from precise to inexact mode
  /// when the user has revoked the SCHEDULE_EXACT_ALARM permission.
  Future<void> _scheduleSafely({
    required NotificationContent content,
    required NotificationCalendar Function(bool precise) scheduleBuilder,
    List<NotificationActionButton>? actionButtons,
  }) async {
    try {
      await AwesomeNotifications().createNotification(
        content: content,
        schedule: scheduleBuilder(_canScheduleExact),
        actionButtons: actionButtons,
      );
      debugPrint('Scheduled notification id=${content.id} precise=$_canScheduleExact');
    } catch (e) {
      if (_canScheduleExact) {
        debugPrint('Precise schedule failed; retrying id=${content.id} inexact: $e');
        _canScheduleExact = false;
        await AwesomeNotifications().createNotification(
          content: content,
          schedule: scheduleBuilder(false),
          actionButtons: actionButtons,
        );
      } else {
        debugPrint('Schedule failed id=${content.id}: $e');
        rethrow;
      }
    }
  }

  // ───── Task reminders ─────────────────────────────────────────────

  Future<void> scheduleTaskReminder(Todo todo) async {
    if (todo.id == null) {
      debugPrint('scheduleTaskReminder skipped: null id');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final master = prefs.getBool('notifications_enabled') ?? true;
    final tasksOn = prefs.getBool(kTasksEnabledKey) ?? true;
    if (!master || !tasksOn) {
      debugPrint(
          'scheduleTaskReminder id=${todo.id}: skipped (master=$master tasksOn=$tasksOn)');
      if (todo.id != null) await cancelTaskReminder(todo.id!);
      return;
    }
    if (todo.status == 'Completed') {
      debugPrint('scheduleTaskReminder id=${todo.id}: cancelled (status=Completed)');
      await cancelTaskReminder(todo.id!);
      return;
    }
    final minutesBefore = todo.reminderMinutes;
    if (minutesBefore == null) {
      debugPrint('scheduleTaskReminder id=${todo.id}: cancelled (reminderMinutes=null)');
      await cancelTaskReminder(todo.id!);
      return;
    }

    final fireAt = todo.startDate.subtract(Duration(minutes: minutesBefore));
    final now = DateTime.now();
    // If the user explicitly set a reminder, always honor it. When the
    // computed fire time is in the past (common cases: "At time" reminder
    // where startDate is the current minute, or the user took a few seconds
    // to fill the form after opening the page), fire ~5 seconds from now
    // rather than silently dropping the notification.
    final effectiveFireAt = fireAt.isAfter(now)
        ? fireAt
        : now.add(const Duration(seconds: 5));
    debugPrint(
        'scheduleTaskReminder id=${todo.id} startDate=${todo.startDate.toIso8601String()} '
        'fireAt=${fireAt.toIso8601String()} effective=${effectiveFireAt.toIso8601String()}');

    await _scheduleSafely(
      content: NotificationContent(
        id: todo.id!,
        channelKey: kTasksChannelKey,
        title: todo.task,
        body: _dueBodyText(todo.startDate),
        category: NotificationCategory.Reminder,
        notificationLayout: NotificationLayout.Default,
        payload: {
          'type': 'task',
          'id': todo.id!.toString(),
          'title': todo.task,
        },
      ),
      scheduleBuilder: (precise) => NotificationCalendar.fromDate(
        date: effectiveFireAt,
        allowWhileIdle: true,
        preciseAlarm: precise,
        repeats: false,
      ),
      actionButtons: _taskActionButtons(),
    );
  }

  Future<void> cancelTaskReminder(int id) => AwesomeNotifications().cancel(id);

  /// Cancel every scheduled task reminder without touching mood/gratitude.
  Future<void> cancelAllTaskReminders() =>
      AwesomeNotifications().cancelNotificationsByChannelKey(kTasksChannelKey);

  Future<void> snoozeTask(int id, Duration d, {required String title}) async {
    final fireAt = DateTime.now().add(d);
    await _scheduleSafely(
      content: NotificationContent(
        id: id,
        channelKey: kTasksChannelKey,
        title: title,
        body: 'Snoozed — due soon.',
        category: NotificationCategory.Reminder,
        notificationLayout: NotificationLayout.Default,
        payload: {
          'type': 'task',
          'id': id.toString(),
          'title': title,
        },
      ),
      scheduleBuilder: (precise) => NotificationCalendar.fromDate(
        date: fireAt,
        allowWhileIdle: true,
        preciseAlarm: precise,
        repeats: false,
      ),
      actionButtons: _taskActionButtons(),
    );
  }

  static List<NotificationActionButton> _taskActionButtons() => [
        NotificationActionButton(
          key: kActionSnooze,
          label: 'Snooze',
          actionType: ActionType.SilentBackgroundAction,
          autoDismissible: true,
        ),
        NotificationActionButton(
          key: kActionDone,
          label: 'Mark as done',
          actionType: ActionType.SilentBackgroundAction,
          autoDismissible: true,
        ),
      ];

  static String _dueBodyText(DateTime start) {
    final h = start.hour > 12
        ? start.hour - 12
        : (start.hour == 0 ? 12 : start.hour);
    final m = start.minute.toString().padLeft(2, '0');
    final period = start.hour >= 12 ? 'PM' : 'AM';
    return 'Starts at $h:$m $period';
  }

  /// Re-schedule every incomplete, future task on app startup. Tasks whose
  /// start time has already passed are skipped — we don't want cold-launch
  /// reminders for yesterday's unfinished work. The "fire slightly-past
  /// reminders" grace in `scheduleTaskReminder` is intentional only for the
  /// direct save flow; here we're rebuilding the alarm queue from scratch.
  Future<void> rehydrateTaskReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final master = prefs.getBool('notifications_enabled') ?? true;
      final tasksOn = prefs.getBool(kTasksEnabledKey) ?? true;
      if (!master || !tasksOn) {
        debugPrint('rehydrateTaskReminders skipped: master=$master tasksOn=$tasksOn');
        return;
      }
      final todos = await DatabaseHelper().getTodos();
      final now = DateTime.now();
      for (final t in todos) {
        if (t.id == null) continue;
        if (t.status == 'Completed') continue;
        if (t.reminderMinutes == null) continue;
        if (t.startDate.isBefore(now)) continue;
        await scheduleTaskReminder(t);
      }
    } catch (e) {
      debugPrint('rehydrateTaskReminders: $e');
    }
  }

  // ───── Mood daily ─────────────────────────────────────────────────

  Future<void> scheduleMoodDaily(TimeOfDay time) async {
    await cancelMoodDaily();
    await _scheduleSafely(
      content: NotificationContent(
        id: kMoodNotifId,
        channelKey: kMoodChannelKey,
        title: 'How are you feeling?',
        body: 'Take a moment to log your mood.',
        notificationLayout: NotificationLayout.Default,
        payload: const {'type': 'mood'},
      ),
      scheduleBuilder: (precise) => NotificationCalendar(
        hour: time.hour,
        minute: time.minute,
        second: 0,
        repeats: true,
        allowWhileIdle: true,
        preciseAlarm: precise,
        timeZone: _localTimeZone,
      ),
    );
  }

  Future<void> cancelMoodDaily() => AwesomeNotifications().cancel(kMoodNotifId);

  // ───── Gratitude daily ────────────────────────────────────────────

  Future<void> scheduleGratitudeDaily(TimeOfDay time) async {
    // Only "scheduled" mode reaches this method — "on release" is delivered
    // by the backend via FCM and never schedules a local notification.
    await cancelGratitudeDaily();
    await _scheduleSafely(
      content: NotificationContent(
        id: kGratitudeNotifId,
        channelKey: kGratitudeChannelKey,
        title: 'Gratitude journal',
        body: 'A moment to reflect.',
        notificationLayout: NotificationLayout.BigText,
        payload: const {'type': 'gratitude'},
      ),
      scheduleBuilder: (precise) => NotificationCalendar(
        hour: time.hour,
        minute: time.minute,
        second: 0,
        repeats: true,
        allowWhileIdle: true,
        preciseAlarm: precise,
        timeZone: _localTimeZone,
      ),
      actionButtons: _gratitudeActionButtons(),
    );
  }

  Future<void> cancelGratitudeDaily() =>
      AwesomeNotifications().cancel(kGratitudeNotifId);

  static List<NotificationActionButton> _gratitudeActionButtons() => [
        NotificationActionButton(
          key: kActionReply,
          label: 'Reply',
          actionType: ActionType.SilentBackgroundAction,
          requireInputText: true,
          autoDismissible: true,
        ),
      ];

  // ───── Settings helpers ───────────────────────────────────────────

  static TimeOfDay parseTime(String? raw, {required TimeOfDay fallback}) {
    if (raw == null) return fallback;
    final parts = raw.split(':');
    if (parts.length != 2) return fallback;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return fallback;
    return TimeOfDay(hour: h, minute: m);
  }

  static String formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// Display a heads-up banner for an FCM message. Only the `gratitude` type
  /// is expected from FCM after the local-first refactor.
  Future<void> showFromFcm({
    required String? type,
    String? title,
    String? body,
    Map<String, dynamic>? extra,
  }) async {
    if (type != 'gratitude') {
      debugPrint('showFromFcm: unsupported type "$type", dropping banner');
      return;
    }
    final prompt = extra?['prompt']?.toString();
    final bannerBody = (body != null && body.isNotEmpty)
        ? body
        : (prompt ?? 'A moment to reflect.');
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: kGratitudeNotifId,
        channelKey: kGratitudeChannelKey,
        title: title ?? "Today's gratitude prompt",
        body: bannerBody,
        notificationLayout: NotificationLayout.BigText,
        payload: {
          'type': 'gratitude',
          if (prompt != null) 'prompt': prompt,
        },
      ),
      actionButtons: _gratitudeActionButtons(),
    );
  }

  // ───── Test / preview ─────────────────────────────────────────────

  /// Fires an immediate preview of the notification for [type].
  /// [type] is 'task', 'mood', or 'gratitude'.
  Future<void> showTestNotification(String type, {String? prompt}) async {
    switch (type) {
      case 'task':
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: 9000001,
            channelKey: kTasksChannelKey,
            title: 'Example task',
            body: 'Starts at 5:00 PM',
            category: NotificationCategory.Reminder,
            notificationLayout: NotificationLayout.Default,
            payload: const {
              'type': 'task',
              'id': '9000001',
              'title': 'Example task',
            },
          ),
          actionButtons: _taskActionButtons(),
        );
        break;

      case 'mood':
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: 9000002,
            channelKey: kMoodChannelKey,
            title: 'How are you feeling?',
            body: 'Take a moment to log your mood.',
            notificationLayout: NotificationLayout.Default,
            payload: const {'type': 'mood'},
          ),
        );
        break;

      case 'gratitude':
        final body = prompt?.isNotEmpty == true
            ? prompt!
            : 'A moment to reflect.';
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: 9000003,
            channelKey: kGratitudeChannelKey,
            title: prompt?.isNotEmpty == true
                ? "Today's gratitude prompt"
                : 'Gratitude journal',
            body: body,
            notificationLayout: NotificationLayout.BigText,
            payload: {
              'type': 'gratitude',
              if (prompt != null) 'prompt': prompt,
            },
          ),
          actionButtons: _gratitudeActionButtons(),
        );
        break;
    }
  }

  /// Apply mood + gratitude schedules from SharedPreferences.
  Future<void> applyDailySchedulesFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notifications_enabled') ?? true;
    if (!enabled) {
      await cancelMoodDaily();
      await cancelGratitudeDaily();
      return;
    }

    final moodOn = prefs.getBool(kMoodEnabledKey) ?? true;
    if (moodOn) {
      final moodTime = parseTime(prefs.getString(kMoodTimeKey),
          fallback: const TimeOfDay(hour: 17, minute: 0));
      await scheduleMoodDaily(moodTime);
    } else {
      await cancelMoodDaily();
    }

    final gratOn = prefs.getBool(kGratitudeEnabledKey) ?? true;
    final modeStr = prefs.getString(kGratitudeModeKey) ?? 'on_release';
    if (gratOn && modeStr == 'scheduled') {
      final gratTime = parseTime(prefs.getString(kGratitudeTimeKey),
          fallback: const TimeOfDay(hour: 8, minute: 0));
      await scheduleGratitudeDaily(gratTime);
    } else {
      // Either the category is off, or on-release mode handles delivery via
      // backend FCM. Either way, make sure no local schedule lingers.
      await cancelGratitudeDaily();
    }
  }
}
