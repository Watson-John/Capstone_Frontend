import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Onboarding Page',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
              },
              child: const Text('Get Started'),
            ),
          ],
        ),
      ),
    );
  }
}
