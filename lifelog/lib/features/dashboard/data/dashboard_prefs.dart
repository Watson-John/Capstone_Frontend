import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/dashboard_widget_type.dart';

/// Persists and retrieves the user's chosen dashboard widget order.
class DashboardPrefs {
  static const _key = 'dashboard_widget_order';

  Future<List<DashboardWidgetType>> loadOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return List.of(DashboardWidgetType.defaultWidgets);

    final parsed = raw
        .split(',')
        .map((name) {
          try {
            return DashboardWidgetType.values.firstWhere((e) => e.name == name);
          } catch (_) {
            return null;
          }
        })
        .whereType<DashboardWidgetType>()
        .toList();

    return parsed.isEmpty ? List.of(DashboardWidgetType.defaultWidgets) : parsed;
  }

  Future<void> saveOrder(List<DashboardWidgetType> order) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, order.map((e) => e.name).join(','));
  }
}
