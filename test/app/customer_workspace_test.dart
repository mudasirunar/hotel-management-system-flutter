import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_management_system/app/customer_workspace.dart';
import 'package:hotel_management_system/application/customer_controller.dart';
import 'package:hotel_management_system/application/theme_controller.dart';
import 'package:hotel_management_system/data/local/theme_preferences.dart';

import '../support/fake_customer_repository.dart';

class _TestThemePrefs implements ThemePreferences {
  String? _val;
  @override
  Future<String?> load() async => _val;
  @override
  Future<void> save(String val) async {
    _val = val;
  }
  @override
  Future<void> close() async {}
}

void main() {
  group('CustomerWorkspace', () {
    late FakeCustomerRepository repository;
    late CustomerController customerController;
    late ThemeController themeController;

    setUp(() async {
      repository = FakeCustomerRepository();
      customerController = CustomerController(repository: repository);
      await customerController.load();
      themeController = ThemeController(preferences: _TestThemePrefs());
      await themeController.load();
    });

    tearDown(() {
      customerController.dispose();
      themeController.dispose();
    });

    testWidgets('renders mobile layout with bottom bar destinations', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: CustomerWorkspace(
            customerController: customerController,
            themeController: themeController,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Explore'), findsWidgets);
      expect(find.text('Saved'), findsWidgets);
      expect(find.text('Bookings'), findsWidgets);
      expect(find.text('Profile'), findsWidgets);

      // Initially on Explore
      expect(find.text('Find your stay'), findsOneWidget);

      // Tap Saved
      await tester.tap(find.text('Saved'));
      await tester.pumpAndSettle();
      expect(find.text('Saved Stays'), findsOneWidget);

      // Tap Bookings
      await tester.tap(find.text('Bookings'));
      await tester.pumpAndSettle();
      expect(find.text('My Bookings'), findsOneWidget);

      // Tap Profile
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Profile & Settings'), findsOneWidget);
    });

    testWidgets('renders navigation rail on wide screens', (tester) async {
      tester.view.physicalSize = const Size(900, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: CustomerWorkspace(
            customerController: customerController,
            themeController: themeController,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.text('Find your stay'), findsOneWidget);
    });
  });
}
