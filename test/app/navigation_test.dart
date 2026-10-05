import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_management_system/app/app.dart';
import 'package:hotel_management_system/application/hotel_controller.dart';
import 'package:hotel_management_system/application/theme_controller.dart';
import 'package:hotel_management_system/data/local/theme_preferences.dart';

import '../support/fake_repository.dart';

void main() {
  testWidgets(
    'renders mobile workspace with glass bottom bar without layout or parent data errors',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final controller = HotelController(repository: FakeRepository());
      final themeController = ThemeController(preferences: _MemoryThemePrefs());
      addTearDown(() async {
        await themeController.close();
        themeController.dispose();
      });

      await tester.pumpWidget(
        HotelManagementApp(
          controller: controller,
          themeController: themeController,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Dashboard'), findsWidgets);
      expect(find.text('Rooms'), findsWidgets);
      expect(find.text('Guests'), findsWidgets);
      expect(find.text('Bookings'), findsWidgets);

      await tester.pumpWidget(const SizedBox.shrink());
      await controller.close();
      controller.dispose();
    },
  );

  testWidgets(
    'renders rail workspace on wider viewports without errors',
    (tester) async {
      tester.view.physicalSize = const Size(900, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final controller = HotelController(repository: FakeRepository());
      final themeController = ThemeController(preferences: _MemoryThemePrefs());
      addTearDown(() async {
        await themeController.close();
        themeController.dispose();
      });

      await tester.pumpWidget(
        HotelManagementApp(
          controller: controller,
          themeController: themeController,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(NavigationRail), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await controller.close();
      controller.dispose();
    },
  );
}

class _MemoryThemePrefs extends ThemePreferences {
  @override
  Future<String?> load() async => null;
  @override
  Future<void> save(String mode) async {}
  @override
  Future<void> close() async {}
}
