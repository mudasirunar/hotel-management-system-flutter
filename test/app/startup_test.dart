import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_management_system/app/app.dart';
import 'package:hotel_management_system/application/customer_controller.dart';
import 'package:hotel_management_system/application/theme_controller.dart';
import 'package:hotel_management_system/data/local/theme_preferences.dart';

import '../support/fake_customer_repository.dart';

void main() {
  testWidgets('customer startup shows progress then error, retry opens customer workspace', (
    tester,
  ) async {
    final gate = Completer<void>();
    final repository = FakeCustomerRepository()
      ..readGate = gate.future
      ..failRead = true;
    final controller = CustomerController(repository: repository);
    final themeController = ThemeController(
      preferences: _MemoryThemePreferences(),
    );
    addTearDown(() async {
      await themeController.close();
      themeController.dispose();
    });

    await tester.pumpWidget(
      HotelManagementApp(
        customerController: controller,
        themeController: themeController,
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();

    expect(find.text('Unable to open hotel catalog'), findsOneWidget);
    expect(find.text('Find your stay'), findsNothing);

    repository.failRead = false;
    await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Find your stay'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Retry'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await controller.close();
    controller.dispose();
  });

  testWidgets(
    'customer startup recovery remains usable with large text on a small viewport',
    (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(() {
        tester.view.reset();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });

      final controller = CustomerController(
        repository: FakeCustomerRepository()..failRead = true,
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
          customerController: controller,
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
