import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
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
      body: Column(
        children: [
          ListTile(
            leading: Icon(Icons.label_outline, color: cs.primary),
            title: const Text('Receipt Aliases'),
            subtitle: const Text('Manage saved item name mappings'),
            trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Alias management coming soon')),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.waves_rounded, color: cs.primary),
            title: const Text('M3 Expressive Progress Bar'),
            subtitle: const Text('Preview the squiggle indicator'),
            trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            onTap: () => Navigator.pushNamed(context, AppRoutes.squiggleDemo),
          ),
          const Divider(height: 1),
          const Expanded(
            child: ThemedPageContent(
              showTextHierarchy: true,
              showColorRoles: true,
            ),
          ),
        ],
      ),
    );
  }
}
