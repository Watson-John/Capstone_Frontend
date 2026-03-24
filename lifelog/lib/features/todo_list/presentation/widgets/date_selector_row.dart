import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class DateSelectorRow extends StatefulWidget {
  const DateSelectorRow({
    super.key,
    required this.selectedDate,
    required this.daysInMonth,
    required this.onDateSelected,
  });

  final DateTime selectedDate;
  final int daysInMonth;
  final ValueChanged<DateTime> onDateSelected;

  @override
  State<DateSelectorRow> createState() => _DateSelectorRowState();
}

class _DateSelectorRowState extends State<DateSelectorRow> {
  late final CarouselController _controller;

  static const _kWeekLabels = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];

  @override
  void initState() {
    super.initState();
    _controller = CarouselController(initialItem: widget.selectedDate.day - 1);
  }

  @override
  void didUpdateWidget(DateSelectorRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate.day != widget.selectedDate.day) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_controller.hasClients) {
          _controller.animateTo(
            (widget.selectedDate.day - 1) * 64.0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _weekLabel(int day) {
    final dt = DateTime(
        widget.selectedDate.year, widget.selectedDate.month, day);
    return _kWeekLabels[dt.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: 74,
      child: CarouselView(
        controller: _controller,
        itemExtent: 64,
        shrinkExtent: 44,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        onTap: (index) => widget.onDateSelected(DateTime(
          widget.selectedDate.year,
          widget.selectedDate.month,
          index + 1,
        )),
        children: List.generate(widget.daysInMonth, (index) {
          final day = index + 1;
          final isSelected = day == widget.selectedDate.day;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutBack,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: isSelected ? cs.primary : AppTheme.cardChildBg,
              border: isSelected
                  ? null
                  : Border.all(color: cs.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? cs.primary.withValues(alpha: 0.30)
                      : Colors.black.withValues(alpha: 0.06),
                  blurRadius: isSelected ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _weekLabel(day),
                  style: TextStyle(
                    color: isSelected
                        ? cs.onPrimary.withValues(alpha: 0.75)
                        : cs.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$day',
                  style: TextStyle(
                    color: isSelected ? cs.onPrimary : cs.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
