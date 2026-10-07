import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_management_system/application/customer_controller.dart';
import 'package:hotel_management_system/application/location_controller.dart';
import 'package:hotel_management_system/domain/models/hotel.dart';
import 'package:hotel_management_system/domain/models/hotel_room.dart';
import 'package:hotel_management_system/domain/models/stay_date.dart';
import 'package:hotel_management_system/features/hotels/presentation/hotel_detail_screen.dart';

import '../../support/fake_customer_repository.dart';

void main() {
  group('HotelDetailScreen', () {
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

    testWidgets('renders hotel title, amenities, policies, and room cards',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final hotel = repository.catalog.hotels.first; // Pearl Continental Karachi

      await tester.pumpWidget(
        MaterialApp(
          home: HotelDetailScreen(
            hotel: hotel,
            customerController: customerController,
            locationController: locationController,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify hotel info rendered
      expect(find.text('Pearl Continental Karachi'), findsOneWidget);
      expect(find.text('Property Amenities'), findsOneWidget);
      expect(find.text('Hotel Policies'), findsOneWidget);
      expect(find.text('Deluxe Room'), findsOneWidget);
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('Reserve Room'), findsOneWidget);
    });

    testWidgets('tapping reserve room calls onProceedToBooking callback',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final hotel = repository.catalog.hotels.first;
      Hotel? bookedHotel;
      HotelRoom? bookedRoom;
      StayDate? bookedArrival;

      await tester.pumpWidget(
        MaterialApp(
          home: HotelDetailScreen(
            hotel: hotel,
            customerController: customerController,
            locationController: locationController,
            onProceedToBooking: (h, r, arr, dep, party) {
              bookedHotel = h;
              bookedRoom = r;
              bookedArrival = arr;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reserve Room'));
      await tester.pumpAndSettle();

      expect(bookedHotel?.id, equals('h_khi_1'));
      expect(bookedRoom?.id, equals('r_khi_101'));
      expect(bookedArrival, isNotNull);
    });
  });
}
