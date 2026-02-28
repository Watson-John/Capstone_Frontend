import 'package:flutter/material.dart';

import '../../../core/widgets/themed_page_content.dart';
import 'widgets/scan_button.dart';

class ExpenseTrackerPage extends StatelessWidget {
  const ExpenseTrackerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: const [
        ThemedPageContent(
          title: 'Expense Tracker Page',
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: SafeArea(
            minimum: EdgeInsets.only(right: 20, bottom: 24),
            child: ScanButton(),
          ),
        ),
      ],
    );
  }
}
