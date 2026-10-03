import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:hotel_management_system/application/hotel_controller.dart';
import 'package:hotel_management_system/data/local/hive_hotel_repository.dart';
import 'package:hotel_management_system/domain/models/stay_date.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'native application storage survives a complete stay and reopen',
    (tester) async {
      await tester.runAsync(() async {
        const boxName = 'hotel_storage_smoke';
        final path = (await getApplicationSupportDirectory()).path;
        // Dedicated fictional test records never share the application's real box.
        await Hive.deleteBoxFromDisk(boxName, path: path);
        var controller = HotelController(
          repository: HiveHotelRepository(boxName: boxName),
        );
        Future<void> reopen() async {
          await controller.close();
          controller.dispose();
          controller = HotelController(
            repository: HiveHotelRepository(boxName: boxName),
          );
          await controller.load();
          expect(controller.status, HotelLoadStatus.ready);
        }

        try {
          await controller.load();
          expect(controller.status, HotelLoadStatus.ready);
          await controller.saveRoom(
            number: 'TEST-101',
            type: 'Double',
            nightlyRateMinor: 100000,
          );
          await controller.saveGuest(
            name: 'Fictional Test Guest',
            phone: '03001234567',
            cnic: '12345-1234567-1',
            address: 'Fictional test address',
          );
          final roomId = controller.state.rooms.single.id;
          final guestId = controller.state.guests.single.id;
          final now = DateTime.now();
          final arrival = StayDate.fromDateTime(now);
          final departure = StayDate.fromDateTime(
            DateTime(now.year, now.month, now.day + 2),
          );
          await controller.createBooking(
            roomId: roomId,
            guestIds: [guestId],
            primaryGuestId: guestId,
            arrivalDate: arrival,
            departureDate: departure,
          );
          await reopen();
          final bookingId = controller.state.bookings.single.id;
          expect(controller.state.bookings.single.guestIds, [guestId]);
          await controller.checkIn(bookingId);
          await reopen();
          expect(controller.state.metrics.occupiedRooms, 1);
          await controller.checkOut(bookingId);
          await reopen();
          expect(controller.state.metrics.availableRooms, 1);
          expect(controller.state.metrics.activeBookings, 0);
          expect(controller.state.bookings.single.actualCheckOutAt, isNotNull);
        } finally {
          await controller.close();
          controller.dispose();
          await Hive.deleteBoxFromDisk(boxName, path: path);
        }
      });
    },
  );
}
