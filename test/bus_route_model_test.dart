import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttermobileapp/screens/home_screen.dart';
import 'package:fluttermobileapp/screens/stops_bottom_sheet.dart';
import 'package:fluttermobileapp/screens/tracking_screen.dart';

void main() {
  testWidgets('renders home screen without overflow on narrow screens',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(timeProvider: () => DateTime(2026, 8, 3, 9)),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(tester.takeException(), isNull);
  });

  testWidgets('renders the home screen route list and action buttons',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(timeProvider: () => DateTime(2026, 8, 3, 9)),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Available Routes'), findsOneWidget);
    expect(find.text('Sankaranpalayam'), findsWidgets);
    expect(find.text('Stops'), findsWidgets);
    expect(find.text('Track'), findsWidgets);
  });

  testWidgets('opens the route sheet from the home screen action',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(timeProvider: () => DateTime(2026, 8, 3, 9)),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    final stopsButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Stops').first,
    );
    expect(stopsButton.onPressed, isNotNull);

    stopsButton.onPressed!.call();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byType(StopsBottomSheet), findsOneWidget);
    expect(find.text('Main Bus Stand'), findsWidgets);

    final sheetContext = tester.element(find.byType(StopsBottomSheet));
    Navigator.of(sheetContext).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byType(StopsBottomSheet), findsNothing);
  });

  testWidgets('renders the home screen route list for evening mode',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(timeProvider: () => DateTime(2026, 8, 3, 15)),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Available Routes'), findsOneWidget);
    expect(find.text('Old Bus Stand'), findsWidgets);
    expect(find.text('Track'), findsWidgets);
  });
}
