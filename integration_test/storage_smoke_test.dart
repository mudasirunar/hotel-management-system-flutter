import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:hotel_management_system/application/customer_controller.dart';
import 'package:hotel_management_system/data/local/hive_customer_repository.dart';
import 'package:hotel_management_system/domain/models/stay_date.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'native customer storage survives booking creation and reopen',
    (tester) async {
      await tester.runAsync(() async {
        const boxName = 'customer_storage_smoke';
        final path = (await getApplicationSupportDirectory()).path;
        await Hive.deleteBoxFromDisk(boxName, path: path);
        var controller = CustomerController(
          repository: HiveCustomerRepository(boxName: boxName),
        );
        Future<void> reopen() async {
          await controller.close();
          controller.dispose();
          controller = CustomerController(
            repository: HiveCustomerRepository(boxName: boxName),
          );
          await controller.load();
          expect(controller.status, CustomerLoadStatus.ready);
        }

        try {
          await controller.load();
          expect(controller.status, CustomerLoadStatus.ready);
          expect(controller.catalog.hotels.isNotEmpty, isTrue);

          final hotel = controller.catalog.hotels.first;
          final room = hotel.rooms.first;
          final arrival = StayDate(2026, 12, 1);
          final departure = StayDate(2026, 12, 3);

          final booking = await controller.createBooking(
            hotel: hotel,
            room: room,
            arrival: arrival,
            departure: departure,
            partySize: 1,
            travelerName: 'Test Traveler',
            travelerPhone: '+92 300 1234567',
          );
          expect(controller.state.bookings.length, 1);

          await reopen();
          expect(controller.state.bookings.length, 1);
          expect(controller.state.bookings.first.id, booking.id);
          expect(controller.state.bookings.first.travelerName, 'Test Traveler');

          await controller.cancelBooking(booking.id);
          expect(controller.state.bookings.first.isCancelled, isTrue);

          await reopen();
          expect(controller.state.bookings.first.isCancelled, isTrue);
        } finally {
          await controller.close();
          controller.dispose();
          await Hive.deleteBoxFromDisk(boxName, path: path);
        }
      });
    },
  );
}
