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
const String kBudgetChannelKey = 'budget_channel';

/// Reserved notification IDs
const int kMoodNotifId = 1000001;
const int kGratitudeNotifId = 1000002;
const int kBudgetNotifId = 1000003;

/// Stride between sub-ids of a single recurring weekly task. Each selected
/// weekday becomes its own NotificationCalendar entry; sub-ids are
/// `todo.id + kRecurringSubIdStride * n`. 10M leaves headroom well within
/// int32 for sqlite-autoincremented todo ids.
const int kRecurringSubIdStride = 10000000;

/// SharedPreferences keys
const String kMoodTimeKey = 'mood_reminder_time';
const String kGratitudeTimeKey = 'gratitude_reminder_time';
const String kGratitudeModeKey = 'gratitude_reminder_mode'; // 'on_release' | 'scheduled'
const String kSnoozeMinutesKey = 'task_snooze_minutes';
const String kBudgetThresholdKey = 'budget_alert_threshold_pct'; // int, e.g. 20
/// Tracks whether the most-recent check saw the user below the alert threshold.
/// Notification fires on the transition above→below; resets when above.
const String kBudgetBelowThresholdKey = 'budget_alert_below_threshold';

/// Per-category enable flags (default true). The master 'notifications_enabled'
/// still short-circuits all categories when off.
const String kTasksEnabledKey = 'notifications_tasks_enabled';
const String kMoodEnabledKey = 'notifications_mood_enabled';
const String kGratitudeEnabledKey = 'notifications_gratitude_enabled';
const String kBudgetAlertsEnabledKey = 'notifications_budget_alerts_enabled';

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
      NotificationChannel(
        channelKey: kBudgetChannelKey,
        channelName: 'Budget Alerts',
        channelDescription: 'Alerts when spending approaches your budget limit',
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
  /// when the user has revoked the SCHEDULE_EXACT_ALARM permission. Accepts
  /// any NotificationSchedule subtype (Calendar, Interval, Cron).
  Future<void> _scheduleSafely({
    required NotificationContent content,
    required NotificationSchedule Function(bool precise) scheduleBuilder,
    List<NotificationActionButton>? actionButtons,
  }) async {
    try {
      final ok = await AwesomeNotifications().createNotification(
        content: content,
        schedule: scheduleBuilder(_canScheduleExact),
        actionButtons: actionButtons,
      );
      debugPrint(
          'Scheduled notification id=${content.id} precise=$_canScheduleExact ok=$ok');
    } catch (e) {
      if (_canScheduleExact) {
        debugPrint('Precise schedule failed; retrying id=${content.id} inexact: $e');
        _canScheduleExact = false;
        final ok = await AwesomeNotifications().createNotification(
          content: content,
          schedule: scheduleBuilder(false),
          actionButtons: actionButtons,
        );
        debugPrint('Inexact retry id=${content.id} ok=$ok');
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

    // Bail loudly if the OS-level permission isn't granted — silently
    // scheduling against a denied channel is the #1 cause of "I set a
    // reminder and nothing happened".
    final allowed = await AwesomeNotifications().isNotificationAllowed();
    if (!allowed) {
      debugPrint(
          'scheduleTaskReminder id=${todo.id}: ABORTED — notifications not allowed at OS level');
      return;
    }

    // Clear any prior schedules (including weekly sub-ids from a previous edit)
    // before re-scheduling. Safe no-op for fresh tasks.
    await cancelTaskReminder(todo.id!);

    final reminderAt = todo.startDate.subtract(Duration(minutes: minutesBefore));

    if (todo.isRecurring) {
      await _scheduleRecurringTaskReminder(todo, reminderAt);
      return;
    }

    final now = DateTime.now();
    // Compute seconds-from-now for NotificationInterval. If the user explicitly
    // set a reminder but the computed fire time is in the past (e.g. "At time"
    // reminder where startDate is the current minute, or the user spent a few
    // seconds in the form), fire ~5 seconds from now rather than silently
    // dropping the notification.
    final secondsUntil = reminderAt.isAfter(now)
        ? reminderAt.difference(now).inSeconds
        : 5;
    debugPrint(
        'scheduleTaskReminder id=${todo.id} startDate=${todo.startDate.toIso8601String()} '
        'reminderAt=${reminderAt.toIso8601String()} secondsUntil=$secondsUntil');

    await _scheduleSafely(
      content: NotificationContent(
        id: todo.id!,
        channelKey: kTasksChannelKey,
        title: todo.task,
        body: _dueBodyText(todo.startDate),
        category: NotificationCategory.Reminder,
        notificationLayout: NotificationLayout.Default,
        wakeUpScreen: true,
        payload: {
          'type': 'task',
          'id': todo.id!.toString(),
          'title': todo.task,
        },
      ),
      // NotificationInterval is more reliable than Calendar.fromDate for
      // short, one-shot delays — it's a relative offset so it can't be
      // confused by timezone or DST edge cases.
      scheduleBuilder: (precise) => NotificationInterval(
        interval: Duration(seconds: secondsUntil),
        timeZone: _localTimeZone,
        allowWhileIdle: true,
        preciseAlarm: precise,
        repeats: false,
      ),
      actionButtons: _taskActionButtons(),
    );
  }

  /// Schedule recurring task reminders using awesome_notifications' calendar
  /// repetition primitives. The reminder offset (e.g., 15 min before 8:00 AM)
  /// is baked into the hour/minute/weekday/day of the recurring schedule so
  /// each occurrence fires at startTime - reminderMinutes.
  ///
  /// NOTE: dueDate (recurrence end) is not enforced here — NotificationCalendar
  /// has no native end date. Tasks past their dueDate will keep firing until
  /// the user deletes them.
  Future<void> _scheduleRecurringTaskReminder(
    Todo todo,
    DateTime reminderAt,
  ) async {
    final id = todo.id!;
    final hour = reminderAt.hour;
    final minute = reminderAt.minute;
    final groupKey = 'task_$id';

    NotificationContent buildContent(int notifId) => NotificationContent(
          id: notifId,
          channelKey: kTasksChannelKey,
          groupKey: groupKey,
          title: todo.task,
          body: _dueBodyText(todo.startDate),
          category: NotificationCategory.Reminder,
          notificationLayout: NotificationLayout.Default,
          wakeUpScreen: true,
          payload: {
            'type': 'task',
            'id': id.toString(),
            'title': todo.task,
          },
        );

    switch (todo.recurrenceType) {
      case 'daily':
        debugPrint(
            'scheduleTaskReminder id=$id recurring=daily at $hour:$minute');
        await _scheduleSafely(
          content: buildContent(id),
          scheduleBuilder: (precise) => NotificationCalendar(
            hour: hour,
            minute: minute,
            second: 0,
            timeZone: _localTimeZone,
            allowWhileIdle: true,
            preciseAlarm: precise,
            repeats: true,
          ),
          actionButtons: _taskActionButtons(),
        );
        break;
      case 'weekly':
        final weekdays = _parseWeekdays(todo.recurrenceDays);
        debugPrint(
            'scheduleTaskReminder id=$id recurring=weekly weekdays=$weekdays at $hour:$minute');
        for (var i = 0; i < weekdays.length; i++) {
          final subId = i == 0 ? id : id + kRecurringSubIdStride * i;
          final weekday = weekdays[i];
          await _scheduleSafely(
            content: buildContent(subId),
            scheduleBuilder: (precise) => NotificationCalendar(
              weekday: weekday,
              hour: hour,
              minute: minute,
              second: 0,
              timeZone: _localTimeZone,
              allowWhileIdle: true,
              preciseAlarm: precise,
              repeats: true,
            ),
            actionButtons: _taskActionButtons(),
          );
        }
        break;
      case 'monthly':
        final day = reminderAt.day;
        debugPrint(
            'scheduleTaskReminder id=$id recurring=monthly day=$day at $hour:$minute');
        await _scheduleSafely(
          content: buildContent(id),
          scheduleBuilder: (precise) => NotificationCalendar(
            day: day,
            hour: hour,
            minute: minute,
            second: 0,
            timeZone: _localTimeZone,
            allowWhileIdle: true,
            preciseAlarm: precise,
            repeats: true,
          ),
          actionButtons: _taskActionButtons(),
        );
        break;
      default:
        // Unknown recurrenceType — fall back to a one-shot at reminderAt.
        debugPrint(
            'scheduleTaskReminder id=$id unknown recurrenceType=${todo.recurrenceType}; '
            'falling back to one-shot');
        final now = DateTime.now();
        final secondsUntil = reminderAt.isAfter(now)
            ? reminderAt.difference(now).inSeconds
            : 5;
        await _scheduleSafely(
          content: buildContent(id),
          scheduleBuilder: (precise) => NotificationInterval(
            interval: Duration(seconds: secondsUntil),
            timeZone: _localTimeZone,
            allowWhileIdle: true,
            preciseAlarm: precise,
            repeats: false,
          ),
          actionButtons: _taskActionButtons(),
        );
    }
  }

  /// Map a comma-separated weekday CSV (`'Mon,Wed,Fri'`) to Dart weekday
  /// numbers (Mon=1..Sun=7). Returns all 7 days when csv is null/empty —
  /// matches `Todo.appearsOnDate`'s behavior for empty recurrenceDays.
  static List<int> _parseWeekdays(String? csv) {
    const weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (csv == null || csv.trim().isEmpty) {
      return const [1, 2, 3, 4, 5, 6, 7];
    }
    final result = <int>[];
    for (final name in csv.split(',')) {
      final idx = weekdayNames.indexOf(name.trim());
      if (idx >= 0) result.add(idx + 1);
    }
    return result.isEmpty ? const [1, 2, 3, 4, 5, 6, 7] : result;
  }

  Future<void> cancelTaskReminder(int id) async {
    await AwesomeNotifications().cancel(id);
    // Recurring weekly tasks fan out to multiple sub-ids under this groupKey;
    // single-id cancel above isn't enough. No-op for one-shot tasks.
    await AwesomeNotifications().cancelNotificationsByGroupKey('task_$id');
  }

  /// Cancel every scheduled task reminder without touching mood/gratitude.
  Future<void> cancelAllTaskReminders() =>
      AwesomeNotifications().cancelNotificationsByChannelKey(kTasksChannelKey);

  Future<void> snoozeTask(int id, Duration d, {required String title}) async {
    final seconds = d.inSeconds < 1 ? 5 : d.inSeconds;
    await _scheduleSafely(
      content: NotificationContent(
        id: id,
        channelKey: kTasksChannelKey,
        title: title,
        body: 'Snoozed — due soon.',
        category: NotificationCategory.Reminder,
        notificationLayout: NotificationLayout.Default,
        wakeUpScreen: true,
        payload: {
          'type': 'task',
          'id': id.toString(),
          'title': title,
        },
      ),
      scheduleBuilder: (precise) => NotificationInterval(
        interval: Duration(seconds: seconds),
        timeZone: _localTimeZone,
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
        // Non-recurring past-due tasks: skip (we don't fire yesterday's alarm
        // on cold launch). Recurring tasks: always re-register — their
        // calendar schedule is time-of-day based and the original startDate
        // doesn't matter for future occurrences.
        if (!t.isRecurring && t.startDate.isBefore(now)) continue;
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

  // ───── Budget alerts ──────────────────────────────────────────────

  /// Fires a "low budget" notification on the first below-threshold check since
  /// the user was last seen above the threshold. Call [resetBudgetAboveThreshold]
  /// when the user is above threshold so the next crossing fires fresh.
  Future<void> showBudgetThresholdNotification({
    required double spent,
    required double limitAmount,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final masterOn = prefs.getBool('notifications_enabled') ?? true;
      final budgetOn = prefs.getBool(kBudgetAlertsEnabledKey) ?? true;
      if (!masterOn || !budgetOn) {
        debugPrint('budgetAlert: skipped (master=$masterOn budget=$budgetOn)');
        return;
      }

      final alreadyNotified = prefs.getBool(kBudgetBelowThresholdKey) ?? false;
      if (alreadyNotified) {
        debugPrint('budgetAlert: already notified since last above-threshold');
        return;
      }

      final remaining = limitAmount - spent;
      final pct = ((remaining / limitAmount) * 100).round();

      final created = await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: kBudgetNotifId,
          channelKey: kBudgetChannelKey,
          title: 'Budget Alert',
          body:
              'Only $pct% of your budget remains — \$${remaining.toStringAsFixed(2)} left.',
          notificationLayout: NotificationLayout.Default,
          payload: const {'type': 'budget'},
        ),
      );

      debugPrint('budgetAlert: createNotification returned $created');
      if (created) {
        await prefs.setBool(kBudgetBelowThresholdKey, true);
      }
    } catch (e) {
      debugPrint('budgetAlert: error — $e');
    }
  }

  /// Clears the "already notified" flag so the next time the user crosses
  /// below the threshold, a fresh notification fires.
  Future<void> resetBudgetAboveThreshold() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kBudgetBelowThresholdKey, false);
    } catch (e) {
      debugPrint('budgetAlert: reset error — $e');
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
