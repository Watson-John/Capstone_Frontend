import 'package:flutter/material.dart';

import '../../../core/widgets/app_page_header.dart';

class GratitudeJournalPage extends StatelessWidget {
  const GratitudeJournalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppPageHeader(title: 'Gratitude Journal'),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
