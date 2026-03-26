import 'package:flutter/material.dart';

enum MoodFilterPeriod { weekly, monthly, yearly }

class MoodFilterPills extends StatelessWidget {
  const MoodFilterPills({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final MoodFilterPeriod selectedFilter;
  final ValueChanged<MoodFilterPeriod> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<MoodFilterPeriod>(
        segments: const [
          ButtonSegment(value: MoodFilterPeriod.weekly, label: Text('Week')),
          ButtonSegment(value: MoodFilterPeriod.monthly, label: Text('Month')),
          ButtonSegment(value: MoodFilterPeriod.yearly, label: Text('Year')),
        ],
        selected: {selectedFilter},
        onSelectionChanged: (s) => onFilterChanged(s.first),
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
