import 'package:flutter/material.dart';

import '../../data/mood_analysis_cache.dart';
import '../../data/mood_analysis_service.dart';
import '../../domain/models/mood_log.dart';
import 'mood_card_shell.dart';

class MoodAnalysisCard extends StatefulWidget {
  const MoodAnalysisCard({super.key, required this.moodLogs});

  final List<MoodLog> moodLogs;

  @override
  State<MoodAnalysisCard> createState() => _MoodAnalysisCardState();
}

class _MoodAnalysisCardState extends State<MoodAnalysisCard> {
  final _service = MoodAnalysisService();
  final _cache = MoodAnalysisCache();

  String? _analysis;
  bool _loading = false;
  String? _error;
  String? _lastSignature;

  @override
  void initState() {
    super.initState();
    _syncAnalysis();
  }

  @override
  void didUpdateWidget(covariant MoodAnalysisCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newSig = _cache.signatureFor(widget.moodLogs);
    if (newSig != _lastSignature) _syncAnalysis();
  }

  Future<void> _syncAnalysis() async {
    final logs = widget.moodLogs;
    final sig = _cache.signatureFor(logs);
    _lastSignature = sig;

    if (logs.isEmpty) {
      setState(() {
        _analysis = null;
        _loading = false;
        _error = null;
      });
      return;
    }

    final cached = await _cache.read(logs);
    if (!mounted) return;
    if (cached != null) {
      setState(() {
        _analysis = cached;
        _loading = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final text = await _service.fetchAnalysis(logs);
      await _cache.write(text, logs);
      if (!mounted) return;
      setState(() {
        _analysis = text;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = "Couldn't reach the analysis service — try again later.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MoodCardShell(
      title: 'Mood Trends',
      titleIcon: Icons.auto_awesome,
      child: _buildBody(cs),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    if (widget.moodLogs.isEmpty) {
      return Text(
        'Log a few moods and your trend summary will appear here.',
        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
      );
    }
    if (_loading && _analysis == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null && _analysis == null) {
      return Text(
        _error!,
        style: TextStyle(color: cs.error, fontSize: 13),
      );
    }
    return Text(
      _analysis ?? '',
      style: TextStyle(
        color: cs.onSurface,
        fontSize: 13,
        height: 1.45,
      ),
    );
  }
}
