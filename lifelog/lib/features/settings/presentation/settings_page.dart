import 'package:flutter/material.dart';

import '../../../core/widgets/themed_page_content.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: const ThemedPageContent(
        title: 'Settings Page',
      ),
    );
  }
}
