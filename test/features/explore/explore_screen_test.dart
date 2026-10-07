import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_management_system/application/customer_controller.dart';
import 'package:hotel_management_system/application/location_controller.dart';
import 'package:hotel_management_system/features/explore/presentation/explore_screen.dart';

import '../../support/fake_customer_repository.dart';

void main() {
  group('ExploreScreen', () {
    late FakeCustomerRepository repository;
    late CustomerController customerController;
    late LocationController locationController;

    setUp(() async {
      repository = FakeCustomerRepository();
      customerController = CustomerController(repository: repository);
      await customerController.load();
      locationController = LocationController(defaultCity: 'All Cities');
    });

    tearDown(() {
      customerController.dispose();
      locationController.dispose();
    });

    testWidgets('renders discovery header, search bar, dates bar, and hotel cards',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: ExploreScreen(
            customerController: customerController,
            locationController: locationController,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Find your stay'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Avari Lahore'), findsOneWidget);
      expect(find.text('Pearl Continental Karachi'), findsOneWidget);
    });

    testWidgets('typing search query filters the hotel card list',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: ExploreScreen(
            customerController: customerController,
            locationController: locationController,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Lahore');
      await tester.pumpAndSettle();

      expect(find.text('Avari Lahore'), findsOneWidget);
      expect(find.text('Pearl Continental Karachi'), findsNothing);
    });

    testWidgets('empty search results show friendly empty state with reset action',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: ExploreScreen(
            customerController: customerController,
            locationController: locationController,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'NonExistentHotelXYZ');
      await tester.pumpAndSettle();

      expect(find.text('No stays match your search'), findsOneWidget);
      expect(find.text('Reset search & filters'), findsOneWidget);

      await tester.tap(find.text('Reset search & filters'));
      await tester.pumpAndSettle();

      expect(find.text('Avari Lahore'), findsOneWidget);
      expect(find.text('Pearl Continental Karachi'), findsOneWidget);
    });

    testWidgets('tapping favorite heart icon saves and updates state',
        (tester) async {
      final repo = FakeCustomerRepository();
      final ctrl = CustomerController(repository: repo);
      await ctrl.load();
      addTearDown(ctrl.dispose);

      final locCtrl = LocationController(defaultCity: 'All Cities');
      addTearDown(locCtrl.dispose);

      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: ExploreScreen(
            customerController: ctrl,
            locationController: locCtrl,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Both hotels initially unsaved
      expect(ctrl.state.savedHotelIds, isEmpty);

      // Tap first heart button (Avari Lahore is top-rated at index 0)
      await tester.tap(find.byIcon(Icons.favorite_border).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(ctrl.state.savedHotelIds.contains('h_lhr_1'), isTrue);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });
  });
}
