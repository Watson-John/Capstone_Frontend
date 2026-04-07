// integration_test/test_helpers.dart
//
// Shared utilities for all integration tests.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:lifelog/app.dart';
import 'package:lifelog/firebase_options.dart';

/// Call once in `setUpAll` to initialize the binding, dotenv, and Firebase.
///
/// Returns the [IntegrationTestWidgetsFlutterBinding] so callers can
/// configure it further (e.g. set framePolicy).
Future<IntegrationTestWidgetsFlutterBinding> initTestBinding() async {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform);

  return binding;
}

/// Pump frames until [finder] matches at least one widget, or fail after
/// [timeoutSecs]. Returns immediately once found.
Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  int timeoutSecs = 10,
  String? reason,
}) async {
  for (int i = 0; i < timeoutSecs * 4; i++) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail(reason ?? 'Timed out after ${timeoutSecs}s waiting for: $finder');
}

/// Launch the app at [initialRoute] and wait for the first frame.
Future<void> pumpApp(WidgetTester tester, String initialRoute) async {
  await tester.pumpWidget(LifelogApp(initialRoute: initialRoute));
  await tester.pump(const Duration(seconds: 1));
}

/// Tap a widget found by [finder] and pump a short settle duration.
Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 500));
}
