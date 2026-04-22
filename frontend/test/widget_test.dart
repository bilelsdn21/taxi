import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:test_windows/screens/auth/driver_layout.dart';

void main() {
  testWidgets('Driver layout renders shell and child content',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/driver': (_) => const SizedBox.shrink(),
          '/driver/requests': (_) => const SizedBox.shrink(),
          '/driver/active': (_) => const SizedBox.shrink(),
          '/driver/history': (_) => const SizedBox.shrink(),
          '/driver/profile': (_) => const SizedBox.shrink(),
        },
        home: const DriverLayout(
          title: 'Active Ride',
          currentIndex: 2,
          child: Text('Test Child'),
        ),
      ),
    );

    expect(find.text('SmartPickup'), findsOneWidget);
    expect(find.text('Driver Portal'), findsOneWidget);
    expect(find.text('Test Child'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
}
