import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_management_system/app/app.dart';
import 'package:hotel_management_system/application/hotel_controller.dart';
import 'package:hotel_management_system/application/theme_controller.dart';
import 'package:hotel_management_system/data/local/theme_preferences.dart';

import '../support/fake_repository.dart';

void main() {
  testWidgets('startup shows progress then error, retry opens the workspace', (
    tester,
  ) async {
    final repository = FakeRepository()
      ..readGate = Completer<void>()
      ..failRead = true;
    final controller = HotelController(repository: repository);
    final themeController = ThemeController(
      preferences: _MemoryThemePreferences(),
    );
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
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    repository.readGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Unable to open your records'), findsOneWidget);
    expect(find.text('Rooms'), findsNothing);
    repository.failRead = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Rooms'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await controller.close();
    controller.dispose();
  });

  testWidgets(
    'startup recovery remains usable with large text on a small viewport',
    (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(() {
        tester.view.reset();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
      final controller = HotelController(
        repository: FakeRepository()..failRead = true,
      );
      final themeController = ThemeController(
        preferences: _MemoryThemePreferences(),
      );
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
      await tester.ensureVisible(find.text('Retry'));
      expect(find.text('Retry'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await controller.close();
      controller.dispose();
    },
  );
}

class _MemoryThemePreferences extends ThemePreferences {
  @override
  Future<String?> load() async => null;
  @override
  Future<void> save(String mode) async {}
  @override
  Future<void> close() async {}
}
