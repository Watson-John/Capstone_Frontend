import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/services/app_instance_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _autoInProgress = true;
  String _swipeLtrAction = 'complete';
  String _swipeRtlAction = 'complete';
  bool _donateAliases = false;
  bool _loaded = false;

  String get _baseUrl => dotenv.env['BACKEND_URL'] ?? '';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadDonatePreferenceFromBackend();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoInProgress = prefs.getBool('auto_in_progress_enabled') ?? true;
      _swipeLtrAction = prefs.getString('swipe_ltr_action') ?? 'complete';
      _swipeRtlAction = prefs.getString('swipe_rtl_action') ?? 'delete';
      _donateAliases = prefs.getBool('donate_aliases_pref') ?? false;
      _loaded = true;
    });
  }

  /// Fetches the donate preference from the backend and updates state.
  /// Falls back silently on error — local SharedPreferences value is used.
  Future<void> _loadDonatePreferenceFromBackend() async {
    final headers = await AppInstanceService.instanceHeaders();
    if (headers.isEmpty) return;
    try {
      final url = Uri.parse('$_baseUrl/api/aliases/preferences/');
      final response = await http.get(url, headers: headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final value = data['donate_aliases'] as bool? ?? false;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('donate_aliases_pref', value);
        if (mounted) setState(() => _donateAliases = value);
      }
    } catch (_) {}
  }

  Future<void> _setDonateAliases(bool value) async {
    setState(() => _donateAliases = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('donate_aliases_pref', value);

    final headers = await AppInstanceService.instanceHeaders();
    if (headers.isEmpty) return;
    try {
      final url = Uri.parse('$_baseUrl/api/aliases/preferences/');
      await http.patch(
        url,
        headers: {...headers, 'Content-Type': 'application/json'},
        body: jsonEncode({'donate_aliases': value}),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  Future<void> _setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  String _swipeActionLabel(String action) {
    switch (action) {
      case 'complete':
        return 'Mark Completed';
      case 'in_progress':
        return 'Mark In Progress';
      case 'delete':
        return 'Delete';
      default:
        return 'Mark Completed';
    }
  }

  IconData _swipeActionIcon(String action) {
    switch (action) {
      case 'complete':
        return Icons.check_circle_outline;
      case 'in_progress':
        return Icons.play_circle_outline;
      case 'delete':
        return Icons.delete_outline;
      default:
        return Icons.check_circle_outline;
    }
  }

  void _showSwipeActionPicker(String direction) {
    final isLtr = direction == 'ltr';
    final current = isLtr ? _swipeLtrAction : _swipeRtlAction;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return Padding(
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
              Text(
                isLtr ? 'Swipe Left \u2192 Right' : 'Swipe Right \u2192 Left',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
              ),
              const SizedBox(height: 8),
              for (final action in ['complete', 'in_progress', 'delete'])
                ListTile(
                  leading: Icon(_swipeActionIcon(action), color: cs.primary),
                  title: Text(_swipeActionLabel(action)),
                  trailing: action == current
                      ? Icon(Icons.check, color: cs.primary)
                      : null,
                  onTap: () {
                    final key =
                        isLtr ? 'swipe_ltr_action' : 'swipe_rtl_action';
                    _setString(key, action);
                    setState(() {
                      if (isLtr) {
                        _swipeLtrAction = action;
                      } else {
                        _swipeRtlAction = action;
                      }
                    });
                    Navigator.pop(ctx);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (!_loaded) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
      ),
      body: ListView(
        children: [
          // ── Notifications ─────────────────────────────────────
          _SectionHeader(label: 'Notifications', cs: cs),
          ListTile(
            leading: Icon(Icons.notifications_outlined, color: cs.primary),
            title: const Text('Notifications'),
            subtitle: const Text('Categories, times, and delivery'),
            trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            onTap: () => Navigator.pushNamed(
                context, AppRoutes.notificationsSettings),
          ),
          const Divider(height: 1),

          // ── Todo Behavior ─────────────────────────────────────
          _SectionHeader(label: 'Task Behavior', cs: cs),
          SwitchListTile(
            secondary: Icon(Icons.play_arrow_rounded, color: cs.primary),
            title: const Text('Auto In-Progress'),
            subtitle:
                const Text('Move tasks to In Progress when start time arrives'),
            value: _autoInProgress,
            onChanged: (v) {
              _setBool('auto_in_progress_enabled', v);
              setState(() => _autoInProgress = v);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.swipe_right_outlined, color: cs.primary),
            title: const Text('Swipe Left \u2192 Right'),
            subtitle: Text(_swipeActionLabel(_swipeLtrAction)),
            trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            onTap: () => _showSwipeActionPicker('ltr'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.swipe_left_outlined, color: cs.primary),
            title: const Text('Swipe Right \u2192 Left'),
            subtitle: Text(_swipeActionLabel(_swipeRtlAction)),
            trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            onTap: () => _showSwipeActionPicker('rtl'),
          ),
          const Divider(height: 1),

          // ── Expense Aliases ───────────────────────────────────
          _SectionHeader(label: 'Expense Aliases', cs: cs),
          ListTile(
            leading: Icon(Icons.label_outline, color: cs.primary),
            title: const Text('Manage Aliases'),
            subtitle: const Text('View item & store category mappings'),
            trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.aliasManagement),
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: Icon(Icons.volunteer_activism_outlined, color: cs.primary),
            title: const Text('Donate Aliases'),
            subtitle: const Text(
                'Share your item & store corrections to improve results for everyone'),
            value: _donateAliases,
            onChanged: _setDonateAliases,
          ),
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
