import 'package:flutter/material.dart';

import '../../../../core/database/database_helper.dart';
import '../../../gratitude_journal/domain/models/gratitude_entry.dart';
import '../../../gratitude_journal/presentation/widgets/streak_card.dart';

/// Self-fetching card that renders the gratitude StreakCard with live data.
class DashboardStreakCard extends StatefulWidget {
  const DashboardStreakCard({super.key});

  @override
  State<DashboardStreakCard> createState() => _DashboardStreakCardState();
}

class _DashboardStreakCardState extends State<DashboardStreakCard> {
  bool _isLoading = true;
  List<GratitudeEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await DatabaseHelper().getGratitudeEntries();
    if (mounted) {
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return StreakCard(entries: _entries);
  }
}
