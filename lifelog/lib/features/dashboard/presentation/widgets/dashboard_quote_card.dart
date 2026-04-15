import 'package:flutter/material.dart';

import '../../../../core/services/notification_service.dart';

/// Self-fetching card that displays the daily inspirational quote.
class DashboardQuoteCard extends StatefulWidget {
  const DashboardQuoteCard({super.key});

  @override
  State<DashboardQuoteCard> createState() => _DashboardQuoteCardState();
}

class _DashboardQuoteCardState extends State<DashboardQuoteCard> {
  bool _isLoading = true;
  String _quote = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final quote = await NotificationService().getDailyQuote();
    if (mounted) {
      setState(() {
        _quote = quote;
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
