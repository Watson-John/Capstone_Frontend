import 'package:flutter/material.dart';

import '../../../core/widgets/themed_page_content.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
      ),
      body: const ThemedPageContent(
        showTextHierarchy: true,
        showColorRoles: true,
      ),
    );
  }
}
