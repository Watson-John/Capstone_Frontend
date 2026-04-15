import 'package:flutter/material.dart';

enum DashboardWidgetType {
  quickStats,
  todoStats,
  budgetOverview,
  gratitudeStreak,
  gratitudePrompt,
  quoteOfDay;

  String get displayName => switch (this) {
        DashboardWidgetType.quickStats => 'Quick Stats',
        DashboardWidgetType.todoStats => 'Tasks',
        DashboardWidgetType.budgetOverview => 'Budget',
        DashboardWidgetType.gratitudeStreak => 'Streak',
        DashboardWidgetType.gratitudePrompt => 'Journal',
        DashboardWidgetType.quoteOfDay => 'Quote',
      };

  IconData get icon => switch (this) {
        DashboardWidgetType.quickStats => Icons.dashboard_outlined,
        DashboardWidgetType.todoStats => Icons.checklist_rounded,
        DashboardWidgetType.budgetOverview => Icons.account_balance_wallet_outlined,
        DashboardWidgetType.gratitudeStreak => Icons.favorite_border_rounded,
        DashboardWidgetType.gratitudePrompt => Icons.edit_note_rounded,
        DashboardWidgetType.quoteOfDay => Icons.format_quote_rounded,
      };

  static const List<DashboardWidgetType> defaultWidgets = [
    DashboardWidgetType.quickStats,
    DashboardWidgetType.quoteOfDay,
    DashboardWidgetType.todoStats,
  ];
}
