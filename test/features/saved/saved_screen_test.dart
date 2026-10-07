import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_management_system/application/customer_controller.dart';
import 'package:hotel_management_system/application/location_controller.dart';
import 'package:hotel_management_system/domain/models/customer_state.dart';
import 'package:hotel_management_system/features/saved/presentation/saved_screen.dart';

import '../../support/fake_customer_repository.dart';

void main() {
  group('SavedScreen', () {
    late FakeCustomerRepository repository;
    late CustomerController customerController;
    late LocationController locationController;

    setUp(() async {
      repository = FakeCustomerRepository();
      customerController = CustomerController(repository: repository);
      await customerController.load();
      locationController = LocationController();
    });

    tearDown(() {
      customerController.dispose();
      locationController.dispose();
    });

    testWidgets('shows empty state when no hotels are saved', (tester) async {
      var navigatedToExplore = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SavedScreen(
            customerController: customerController,
            locationController: locationController,
            onNavigateToExplore: () {
              navigatedToExplore = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No saved stays yet'), findsOneWidget);
      expect(find.text('Explore Hotels'), findsOneWidget);

      await tester.tap(find.text('Explore Hotels'));
      await tester.pumpAndSettle();

      expect(navigatedToExplore, isTrue);
    });

    testWidgets('displays saved hotel card and removes it on un-save', (tester) async {
      final preSavedRepo = FakeCustomerRepository(
        initialState: CustomerState.initial().copyWith(
          savedHotelIds: {'h_khi_1'},
        ),
      );
      final preSavedCtrl = CustomerController(repository: preSavedRepo);
      await preSavedCtrl.load();
      addTearDown(preSavedCtrl.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: SavedScreen(
            customerController: preSavedCtrl,
            locationController: locationController,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pearl Continental Karachi'), findsOneWidget);
      expect(find.text('1 stay saved locally'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);

      // Tap heart to un-save
      await tester.tap(find.byIcon(Icons.favorite));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(preSavedCtrl.state.savedHotelIds, isEmpty);
      expect(find.text('No saved stays yet'), findsOneWidget);
    });
  });
}
