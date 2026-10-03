import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_management_system/application/hotel_controller.dart';
import 'package:hotel_management_system/domain/hotel_exception.dart';
import 'package:hotel_management_system/domain/models/stay_date.dart';

import '../support/fake_repository.dart';
import '../support/fixtures.dart';

void main() {
  late HotelFixture f;
  late FakeRepository repository;
  late HotelController controller;
  setUp(() {
    f = HotelFixture();
    repository = FakeRepository(f.state);
    controller = HotelController(
      repository: repository,
      operations: f.operations,
    );
  });
  tearDown(() async {
    await controller.close();
    controller.dispose();
  });

  test(
    'startup distinguishes loading, failure and a successful retry',
    () async {
      repository.readGate = Completer<void>();
      repository.failRead = true;
      final loading = controller.load();
      await Future<void>.delayed(Duration.zero);
      expect(controller.status, HotelLoadStatus.loading);
      repository.readGate!.complete();
      await loading;
      expect(controller.status, HotelLoadStatus.failed);
      expect(controller.loadError?.code, HotelErrorCode.storageRead);
      await expectLater(
        controller.deleteRoom(f.roomId),
        throwsA(hotelError(HotelErrorCode.notReady)),
      );
      repository.failRead = false;
      await controller.load();
      expect(controller.status, HotelLoadStatus.ready);
      expect(controller.loadError, isNull);
    },
  );

  test(
    'pending writes do not publish state and failed writes preserve it',
    () async {
      await controller.load();
      final before = controller.state;
      repository.writeGate = Completer<void>();
      repository.failWrite = true;
      final saving = controller.saveRoom(
        number: '102',
        type: 'Single',
        nightlyRateMinor: 50000,
      );
      final error = expectLater(
        saving,
        throwsA(hotelError(HotelErrorCode.storageWrite)),
      );
      await Future<void>.delayed(Duration.zero);
      expect(controller.activeOperation, 'room:new');
      expect(controller.state, same(before));
      repository.writeGate!.complete();
      await error;
      expect(controller.state, same(before));
      expect(repository.saved, same(before));
      expect(controller.activeOperation, isNull);
      repository.failWrite = false;
      await controller.saveRoom(
        number: '102',
        type: 'Single',
        nightlyRateMinor: 50000,
      );
      expect(controller.state.rooms.length, 2);
    },
  );

  test(
    'queued overlapping reservations re-check the latest committed state',
    () async {
      await controller.load();
      Future<void> reserve() => controller.createBooking(
        roomId: f.roomId,
        guestIds: [f.guestId],
        primaryGuestId: f.guestId,
        arrivalDate: StayDate(2026, 10, 4),
        departureDate: StayDate(2026, 10, 6),
      );
      final first = reserve();
      final second = expectLater(
        reserve(),
        throwsA(hotelError(HotelErrorCode.bookingConflict)),
      );
      await first;
      await second;
      expect(controller.state.bookings.length, 1);
      expect(repository.writes, 1);
    },
  );

  test('queued independent writes cannot lose one another', () async {
    await controller.load();
    await Future.wait([
      controller.saveRoom(number: '102', type: 'Single', nightlyRateMinor: 100),
      controller.saveRoom(number: '103', type: 'Single', nightlyRateMinor: 200),
    ]);
    expect(controller.state.rooms.map((r) => r.number), ['101', '102', '103']);
  });

  test(
    'mutable guest input is captured when the booking is requested',
    () async {
      await controller.load();
      final guests = [f.guestId];
      final saving = controller.createBooking(
        roomId: f.roomId,
        guestIds: guests,
        primaryGuestId: f.guestId,
        arrivalDate: StayDate(2026, 10, 4),
        departureDate: StayDate(2026, 10, 6),
      );
      guests.clear();
      await saving;
      expect(controller.state.bookings.single.guestIds, [f.guestId]);
    },
  );

  test(
    'failed check-in preserves metrics and double taps transition only once',
    () async {
      f.reserve();
      repository.saved = f.state;
      await controller.load();
      final id = f.state.bookings.single.id;
      repository.failWrite = true;
      await expectLater(
        controller.checkIn(id),
        throwsA(hotelError(HotelErrorCode.storageWrite)),
      );
      expect(controller.state.metrics.occupiedRooms, 0);
      repository.failWrite = false;
      final first = controller.checkIn(id);
      final duplicate = expectLater(
        controller.checkIn(id),
        throwsA(hotelError(HotelErrorCode.invalidTransition)),
      );
      await first;
      await duplicate;
      expect(controller.state.metrics.occupiedRooms, 1);
      expect(controller.state.metrics.availableRooms, 0);
    },
  );

  test(
    'failed reload preserves committed records and disables writes',
    () async {
      await controller.load();
      final before = controller.state;
      repository.failRead = true;
      await controller.load();
      expect(controller.state, same(before));
      expect(controller.status, HotelLoadStatus.failed);
      await expectLater(
        controller.deleteRoom(f.roomId),
        throwsA(hotelError(HotelErrorCode.notReady)),
      );
    },
  );

  test('room availability uses dates and excludes reserved overlaps', () async {
    f.reserve(arrival: 6, departure: 8);
    repository.saved = f.state;
    await controller.load();
    expect(
      controller.availableRooms(StayDate(2026, 10, 6), StayDate(2026, 10, 8)),
      isEmpty,
    );
    expect(
      controller
          .availableRooms(StayDate(2026, 10, 8), StayDate(2026, 10, 9))
          .single
          .id,
      f.roomId,
    );
    expect(controller.state.metrics.availableRooms, 1);
  });

  test(
    'close drains queued writes before closing storage and rejects new work',
    () async {
      await controller.load();
      repository.writeGate = Completer<void>();
      final saving = controller.saveRoom(
        number: '102',
        type: 'Single',
        nightlyRateMinor: 100,
      );
      final closing = controller.close();
      await Future<void>.delayed(Duration.zero);
      expect(repository.closed, false);
      await expectLater(
        controller.deleteRoom(f.roomId),
        throwsA(hotelError(HotelErrorCode.notReady)),
      );
      repository.writeGate!.complete();
      await saving;
      await closing;
      expect(repository.saved.rooms.length, 2);
      expect(repository.closed, true);
    },
  );
}
