import 'package:flutter_test/flutter_test.dart';

import 'package:lifelog/app.dart';

void main() {
  testWidgets('Onboarding page renders', (WidgetTester tester) async {
    await tester.pumpWidget(const LifelogApp(initialRoute: '/onboarding'));

    expect(find.text('What should we call you by?'), findsWidgets);
  });
}
