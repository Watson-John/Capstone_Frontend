import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/local_notification_service.dart';

class NotificationsSettingsPage extends StatefulWidget {
  const NotificationsSettingsPage({super.key});

  @override
  State<NotificationsSettingsPage> createState() =>
      _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage> {
  bool _loaded = false;
  bool _masterOn = true;
  bool _tasksOn = true;
  bool _moodOn = true;
  bool _gratitudeOn = true;
  TimeOfDay _moodTime = const TimeOfDay(hour: 17, minute: 0);
  TimeOfDay _gratitudeTime = const TimeOfDay(hour: 8, minute: 0);
  String _gratitudeMode = 'on_release';
  int _snoozeMinutes = 10;

  String get _baseUrl => dotenv.env['BACKEND_URL'] ?? '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _masterOn = prefs.getBool('notifications_enabled') ?? true;
      _tasksOn = prefs.getBool(kTasksEnabledKey) ?? true;
      _moodOn = prefs.getBool(kMoodEnabledKey) ?? true;
      _gratitudeOn = prefs.getBool(kGratitudeEnabledKey) ?? true;
      _moodTime = LocalNotificationService.parseTime(
          prefs.getString(kMoodTimeKey),
          fallback: const TimeOfDay(hour: 17, minute: 0));
      _gratitudeTime = LocalNotificationService.parseTime(
          prefs.getString(kGratitudeTimeKey),
          fallback: const TimeOfDay(hour: 8, minute: 0));
      _gratitudeMode = prefs.getString(kGratitudeModeKey) ?? 'on_release';
      _snoozeMinutes = prefs.getInt(kSnoozeMinutesKey) ?? 10;
      _loaded = true;
    });
  }

  String _fmt(TimeOfDay t) {
    final h = t.hour > 12 ? t.hour - 12 : (t.hour == 0 ? 12 : t.hour);
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  Future<void> _setMaster(bool v) async {
    setState(() => _masterOn = v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', v);
    await LocalNotificationService.instance.applyDailySchedulesFromPrefs();
    if (v && _tasksOn) {
      await LocalNotificationService.instance.rehydrateTaskReminders();
    }
  }

  Future<void> _setTasks(bool v) async {
    setState(() => _tasksOn = v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kTasksEnabledKey, v);
    if (v && _masterOn) {
      await LocalNotificationService.instance.rehydrateTaskReminders();
    } else {
      // Turn all task notifications off. cancelAllSchedules would also drop
      // mood/gratitude, so instead we cancel just the tasks channel.
      // awesome_notifications exposes cancelNotificationsByChannelKey.
      await LocalNotificationService.instance.cancelAllTaskReminders();
    }
  }

  Future<void> _setMood(bool v) async {
    setState(() => _moodOn = v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kMoodEnabledKey, v);
    if (v && _masterOn) {
      await LocalNotificationService.instance.scheduleMoodDaily(_moodTime);
    } else {
      await LocalNotificationService.instance.cancelMoodDaily();
    }
  }

  Future<void> _setGratitude(bool v) async {
    setState(() => _gratitudeOn = v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kGratitudeEnabledKey, v);
    if (v && _masterOn && _gratitudeMode == 'scheduled') {
      await LocalNotificationService.instance
          .scheduleGratitudeDaily(_gratitudeTime);
    } else {
      await LocalNotificationService.instance.cancelGratitudeDaily();
    }
    // When the category toggles, keep the backend's gratitude-preference row
    // consistent too — push current mode, or an off sentinel if disabled.
    unawaited(_pushGratitudePreference(v ? _gratitudeMode : 'off'));
  }

  Future<void> _pickMoodTime() async {
    final picked = await showTimePicker(context: context, initialTime: _moodTime);
    if (picked == null) return;
    setState(() => _moodTime = picked);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        kMoodTimeKey, LocalNotificationService.formatTime(picked));
    if (_masterOn && _moodOn) {
      await LocalNotificationService.instance.scheduleMoodDaily(picked);
    }
  }

  Future<void> _pickGratitudeTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: _gratitudeTime);
    if (picked == null) return;
    setState(() => _gratitudeTime = picked);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        kGratitudeTimeKey, LocalNotificationService.formatTime(picked));
    if (_masterOn && _gratitudeOn && _gratitudeMode == 'scheduled') {
      await LocalNotificationService.instance.scheduleGratitudeDaily(picked);
    }
  }

  /// Toggle value maps to: ON = 'on_release' (live via FCM), OFF = 'scheduled'.
  Future<void> _setGratitudeLive(bool liveOn) async {
    final mode = liveOn ? 'on_release' : 'scheduled';
    setState(() => _gratitudeMode = mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kGratitudeModeKey, mode);
    if (_masterOn && _gratitudeOn && mode == 'scheduled') {
      await LocalNotificationService.instance
          .scheduleGratitudeDaily(_gratitudeTime);
    } else {
      await LocalNotificationService.instance.cancelGratitudeDaily();
    }
    unawaited(_pushGratitudePreference(_gratitudeOn ? mode : 'off'));
  }

  Future<void> _pushGratitudePreference(String mode) async {
    if (_baseUrl.isEmpty) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      String tz = 'UTC';
      try {
        tz = await FlutterTimezone.getLocalTimezone();
      } catch (_) {}
      final url = Uri.parse('$_baseUrl/api/commons/gratitude-preference/');
      await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'token': token,
              'mode': mode,
              'timezone': tz,
            }),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('gratitude-preference POST failed: $e');
    }
  }

  Future<void> _pickSnoozeMinutes() async {
    const options = [5, 10, 15, 30, 60];
    final cs = Theme.of(context).colorScheme;
    final chosen = await showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Snooze Duration',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    )),
            const SizedBox(height: 8),
            for (final m in options)
              ListTile(
                title: Text('$m minutes'),
                trailing: m == _snoozeMinutes
                    ? Icon(Icons.check, color: cs.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, m),
              ),
          ],
        ),
      ),
    );
    if (chosen == null) return;
    setState(() => _snoozeMinutes = chosen);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(kSnoozeMinutesKey, chosen);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (!_loaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final categoriesEnabled = _masterOn;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
      ),
      body: ListView(
        children: [
          _SectionHeader(label: 'General', cs: cs),
          SwitchListTile(
            secondary: Icon(Icons.notifications_outlined, color: cs.primary),
            title: const Text('Push Notifications'),
            subtitle: const Text('Master switch for all categories'),
            value: _masterOn,
            onChanged: _setMaster,
          ),
          const Divider(height: 1),

          _SectionHeader(label: 'Task Reminders', cs: cs),
          SwitchListTile(
            secondary: Icon(Icons.checklist_rounded, color: cs.primary),
            title: const Text('Task Reminders'),
            subtitle:
                const Text('Per-task reminders you set when creating a task'),
            value: _tasksOn,
            onChanged: categoriesEnabled ? _setTasks : null,
          ),
          ListTile(
            enabled: categoriesEnabled && _tasksOn,
            leading: Icon(Icons.snooze_outlined,
                color: (categoriesEnabled && _tasksOn)
                    ? cs.primary
                    : cs.onSurfaceVariant),
            title: const Text('Snooze Duration'),
            subtitle: Text('$_snoozeMinutes minutes'),
            trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            onTap: (categoriesEnabled && _tasksOn) ? _pickSnoozeMinutes : null,
          ),
          const Divider(height: 1),

          _SectionHeader(label: 'Mood Reminder', cs: cs),
          SwitchListTile(
            secondary: Icon(Icons.mood_outlined, color: cs.primary),
            title: const Text('Daily mood check-in'),
            subtitle: const Text('Remind me to log my mood each day'),
            value: _moodOn,
            onChanged: categoriesEnabled ? _setMood : null,
          ),
          ListTile(
            enabled: categoriesEnabled && _moodOn,
            leading: Icon(Icons.schedule_outlined,
                color: (categoriesEnabled && _moodOn)
                    ? cs.primary
                    : cs.onSurfaceVariant),
            title: const Text('Time'),
            subtitle: Text('Daily at ${_fmt(_moodTime)}'),
            trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            onTap: (categoriesEnabled && _moodOn) ? _pickMoodTime : null,
          ),
          const Divider(height: 1),

          _SectionHeader(label: 'Gratitude', cs: cs),
          SwitchListTile(
            secondary: Icon(Icons.auto_stories_outlined, color: cs.primary),
            title: const Text('Daily gratitude reminder'),
            subtitle: const Text('Nudges you to reflect each day'),
            value: _gratitudeOn,
            onChanged: categoriesEnabled ? _setGratitude : null,
          ),
          if (categoriesEnabled && _gratitudeOn) ...[
            SwitchListTile(
              secondary: Icon(Icons.campaign_outlined, color: cs.primary),
              title: const Text('Deliver live when prompt is released'),
              subtitle: const Text(
                  'On: today\u2019s prompt arrives as soon as it drops. Off: local reminder at a time you pick.'),
              value: _gratitudeMode == 'on_release',
              onChanged: _setGratitudeLive,
            ),
            if (_gratitudeMode == 'scheduled')
              ListTile(
                leading: Icon(Icons.schedule_outlined, color: cs.primary),
                title: const Text('Time'),
                subtitle: Text('Daily at ${_fmt(_gratitudeTime)}'),
                trailing:
                    Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                onTap: _pickGratitudeTime,
              ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.cs});
  final String label;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
