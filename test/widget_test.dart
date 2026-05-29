// This is a basic Flutter widget test for the JIHC Campus app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jihc_campus_app/screens/onboarding_screen.dart';

void main() {
  testWidgets('Onboarding screen displays first slide title',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OnboardingScreen(),
      ),
    );

    expect(find.text('Stay in the Loop'), findsOneWidget);
    expect(find.text('Discover Events'), findsNothing);
  });
}
