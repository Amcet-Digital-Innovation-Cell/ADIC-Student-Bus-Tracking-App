import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttermobileapp/screens/home_screen.dart';
import 'package:fluttermobileapp/screens/tracking_screen.dart';

void main() {
  testWidgets('renders home screen without overflow on narrow screens', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(timeProvider: () => DateTime(2026, 8, 3, 9)),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('renders the home screen and opens the stops bottom sheet', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(timeProvider: () => DateTime(2026, 8, 3, 9)),
      ),
    );

    expect(find.text('Available Routes'), findsOneWidget);

    await tester.tap(find.text('Stops').first);
    await tester.pumpAndSettle();

    expect(find.text('Morning Route (To College)'), findsOneWidget);
  });

  testWidgets('renders the home screen and navigates to tracking', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(timeProvider: () => DateTime(2026, 8, 3, 15)),
      ),
    );

    expect(find.text('Available Routes'), findsOneWidget);

    await tester.tap(find.text('Track').first);
    await tester.pumpAndSettle();

    expect(find.byType(TrackingScreen), findsOneWidget);
    expect(find.text('Sankaranpalayam'), findsWidgets);
  });
}
