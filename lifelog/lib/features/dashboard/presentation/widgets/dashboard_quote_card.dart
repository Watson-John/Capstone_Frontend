import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/notification_service.dart';

/// Self-fetching card that displays the daily inspirational quote.
///
/// The quote is cached in SharedPreferences keyed by calendar date, so we
/// only hit the backend once per day. Any cached quote is shown immediately
/// (no spinner) and a new-day refresh happens silently in the background.
class DashboardQuoteCard extends StatefulWidget {
  const DashboardQuoteCard({super.key});

  @override
  State<DashboardQuoteCard> createState() => _DashboardQuoteCardState();
}

class _DashboardQuoteCardState extends State<DashboardQuoteCard> {
  static const _kQuoteKey = 'cached_daily_quote_text';
  static const _kQuoteDateKey = 'cached_daily_quote_date';

  bool _isLoading = true;
  String _quote = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _todayKey() {
    final n = DateTime.now();
    final m = n.month.toString().padLeft(2, '0');
    final d = n.day.toString().padLeft(2, '0');
    return '${n.year}-$m-$d';
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_kQuoteKey);
    final cachedDate = prefs.getString(_kQuoteDateKey);
    final today = _todayKey();

    if (cached != null && cached.isNotEmpty) {
      if (mounted) {
        setState(() {
          _quote = cached;
          _isLoading = false;
        });
      }
      if (cachedDate == today) return;
    }

    final fresh = await NotificationService().getDailyQuote();
    await prefs.setString(_kQuoteKey, fresh);
    await prefs.setString(_kQuoteDateKey, today);
    if (mounted) {
      setState(() {
        _quote = fresh;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_quote_rounded, color: cs.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'Quote of the Day',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _isLoading
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: cs.primary),
                  ),
                )
              : Text(
                  '"$_quote"',
                  style: TextStyle(
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    color: cs.onSurface,
                    height: 1.5,
                  ),
                ),
        ],
      ),
    );
  }
}
