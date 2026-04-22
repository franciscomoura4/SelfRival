import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:selfrival/main.dart';

void main() {
  testWidgets('Self Rival starts on service selection screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SelfRivalApp());

    expect(find.text('Self Rival'), findsOneWidget);
    expect(find.text('Choose a service'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('User can complete the booking flow', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SelfRivalApp());

    await tester.tap(find.text('Repair'));
    await tester.pump();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Rui');
    await tester.enterText(find.byType(TextFormField).at(1), 'rui@example.com');

    await tester.tap(find.text('Confirm booking'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Booking confirmed'), findsOneWidget);
    expect(find.text('Service: Repair'), findsOneWidget);
    expect(find.text('Name: Rui'), findsOneWidget);
  });
}
