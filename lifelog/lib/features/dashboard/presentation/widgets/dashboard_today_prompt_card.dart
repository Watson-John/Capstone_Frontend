import 'package:flutter/material.dart';

import '../../../../core/database/database_helper.dart';
import '../../../gratitude_journal/data/gratitude_prompt_service.dart';
import '../../../gratitude_journal/presentation/add_gratitude_page.dart';
import '../../../gratitude_journal/presentation/widgets/today_prompt_card.dart';

/// Self-fetching card that shows today's gratitude prompt and
/// lets the user write an entry directly from the dashboard.
class DashboardTodayPromptCard extends StatefulWidget {
  const DashboardTodayPromptCard({super.key});

  @override
  State<DashboardTodayPromptCard> createState() =>
      _DashboardTodayPromptCardState();
}

class _DashboardTodayPromptCardState extends State<DashboardTodayPromptCard> {
  String _prompt = '';
  bool _hasEntryToday = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final now = DateTime.now();
    final results = await Future.wait([
      GratitudePromptService().fetchPrompt(now),
      DatabaseHelper().getGratitudeEntries(),
    ]);

    if (!mounted) return;

    final prompt = results[0] as String;
    final entries = results[1] as List;
    final todayKey = '${now.year}-${now.month}-${now.day}';
    final hasToday = entries.any((e) {
      final dt = DateTime.parse(e.dateTime as String);
      return '${dt.year}-${dt.month}-${dt.day}' == todayKey;
    });

    setState(() {
      _prompt = prompt;
      _hasEntryToday = hasToday;
    });
  }

  Future<void> _openAddPage() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddGratitudePage(prompt: _prompt),
      ),
    );
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return TodayPromptCard(
      prompt: _prompt,
      hasEntryToday: _hasEntryToday,
      onWriteTap: _openAddPage,
    );
  }
}
