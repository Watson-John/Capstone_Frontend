import 'package:flutter/material.dart';

class ThemedPageContent extends StatelessWidget {
  const ThemedPageContent({
    super.key,
    required this.title,
    this.showTextHierarchy = false,
    this.showColorRoles = false,
  });

  final String title;
  final bool showTextHierarchy;
  final bool showColorRoles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Text(
                    title,
                    style: textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              if (showTextHierarchy) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Text Hierarchy', style: textTheme.titleMedium),
                        const SizedBox(height: 12),
                        Text('Heading 1', style: textTheme.displaySmall),
                        const SizedBox(height: 8),
                        Text('Heading 2', style: textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        Text('Section Title', style: textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(
                          'Regular text: use this style for normal paragraph content in the app.',
                          style: textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 6),
                        Text('Secondary text', style: textTheme.bodyMedium),
                        const SizedBox(height: 6),
                        Text('Caption / helper text', style: textTheme.bodySmall),
                        const SizedBox(height: 10),
                        Text('Button Label', style: textTheme.labelLarge),
                      ],
                    ),
                  ),
                ),
              ],
              if (showColorRoles) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Color Roles', style: textTheme.titleMedium),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _RoleChip(
                              label: 'Primary',
                              background: theme.colorScheme.primary,
                              foreground: theme.colorScheme.onPrimary,
                            ),
                            _RoleChip(
                              label: 'Primary Container',
                              background: theme.colorScheme.primaryContainer,
                              foreground: theme.colorScheme.onPrimaryContainer,
                            ),
                            _RoleChip(
                              label: 'Tertiary',
                              background: theme.colorScheme.tertiary,
                              foreground: theme.colorScheme.onTertiary,
                            ),
                            _RoleChip(
                              label: 'Tertiary Container',
                              background: theme.colorScheme.tertiaryContainer,
                              foreground: theme.colorScheme.onTertiaryContainer,
                            ),
                            _RoleChip(
                              label: 'Error',
                              background: theme.colorScheme.error,
                              foreground: theme.colorScheme.onError,
                            ),
                            _RoleChip(
                              label: 'Error Container',
                              background: theme.colorScheme.errorContainer,
                              foreground: theme.colorScheme.onErrorContainer,
                            ),
                            _RoleChip(
                              label: 'Surface',
                              background: theme.colorScheme.surface,
                              foreground: theme.colorScheme.onSurface,
                            ),
                            _RoleChip(
                              label: 'Surface Container',
                              background: theme.colorScheme.surfaceContainer,
                              foreground: theme.colorScheme.onSurface,
                            ),
                            _RoleChip(
                              label: 'Inverse Surface',
                              background: theme.colorScheme.inverseSurface,
                              foreground: theme.colorScheme.onInverseSurface,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 160),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: foreground),
      ),
    );
  }
}