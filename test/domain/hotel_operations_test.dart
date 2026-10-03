import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_management_system/domain/hotel_exception.dart';
import 'package:hotel_management_system/domain/models/booking.dart';
import 'package:hotel_management_system/domain/models/hotel_state.dart';
import 'package:hotel_management_system/domain/models/room.dart';
import 'package:hotel_management_system/domain/models/stay_date.dart';
import 'package:hotel_management_system/domain/services/hotel_rules.dart';

import '../support/fixtures.dart';

void main() {
  late HotelFixture f;
  setUp(() => f = HotelFixture());

  test(
    'room numbers are unique ignoring case/space; edits preserve identity',
    () {
      f.state = f.operations.saveRoom(
        f.state,
        id: f.roomId,
        number: ' A-101 ',
        type: 'Suite',
        nightlyRateMinor: 10000,
      );
      expect(f.state.rooms.single.number, 'A-101');
      expect(f.state.rooms.single.id, f.roomId);
      expect(
        () => f.operations.saveRoom(
          f.state,
          number: 'a-101',
          type: 'Single',
          nightlyRateMinor: 100,
        ),
        throwsA(hotelError(HotelErrorCode.duplicate)),
      );
    },
  );

  test('guest edits preserve ID and shared phone is allowed, duplicate CNIC is not', () {
    f.state = f.operations.saveGuest(
      f.state,
      id: f.guestId,
      name: 'Edited Guest',
      phone: '+923001234567',
      cnic: '1234512345671',
      address: 'Updated fictional address',
    );
    expect(f.state.guests.single.name, 'Edited Guest');
    expect(
      () => f.operations.saveGuest(
        f.state,
        name: 'Another Guest',
        phone: '03001234567',
        cnic: '12345-1234567-1',
        address: 'Sample',
      ),
      throwsA(hotelError(HotelErrorCode.duplicate)),
    );
    f.state = f.operations.saveGuest(
      f.state,
      name: 'Another Guest',
      phone: '03001234567',
      cnic: '12345-1234567-2',
      address: 'Sample',
    );
    expect(f.state.guests.length, 2);
  });

  test('unreferenced room and guest deletion works; unknown IDs fail', () {
    expect(f.operations.deleteRoom(f.state, f.roomId).rooms, isEmpty);
    expect(f.operations.deleteGuest(f.state, f.guestId).guests, isEmpty);
    expect(
      () => f.operations.deleteRoom(f.state, 'missing'),
      throwsA(hotelError(HotelErrorCode.notFound)),
    );
  });

  test(
    'booking conflicts cover identical, contained and containing intervals',
    () {
      f.reserve(arrival: 6, departure: 8);
      for (final dates in [(6, 8), (6, 7), (7, 8), (5, 9), (5, 7), (7, 9)]) {
        expect(
          () => f.reserve(arrival: dates.$1, departure: dates.$2),
          throwsA(hotelError(HotelErrorCode.bookingConflict)),
        );
      }
      f.reserve(arrival: 4, departure: 6);
      f.reserve(arrival: 8, departure: 10);
      expect(f.state.bookings.length, 3);
    },
  );

  test('same dates in another room are permitted', () {
    f.reserve();
    f.state = f.operations.saveRoom(
      f.state,
      number: '102',
      type: 'Double',
      nightlyRateMinor: 100,
    );
    f.reserve(room: f.state.rooms.last.id);
    expect(f.state.bookings.length, 2);
  });

  test('new reservations reject past, zero-night, and reversed dates', () {
    for (final dates in [(3, 5), (4, 4), (6, 5)]) {
      expect(
        () => f.reserve(arrival: dates.$1, departure: dates.$2),
        throwsA(hotelError(HotelErrorCode.validation)),
      );
    }
  });

  test('booking needs unique existing guests and a selected primary guest', () {
    for (final guests in <List<String>>[
      [],
      [f.guestId, f.guestId],
    ]) {
      expect(
        () => f.operations.createBooking(
          f.state,
          roomId: f.roomId,
          guestIds: guests,
          primaryGuestId: f.guestId,
          arrivalDate: StayDate(2026, 10, 4),
          departureDate: StayDate(2026, 10, 6),
        ),
        throwsA(hotelError(HotelErrorCode.validation)),
      );
    }
    expect(
      () => f.operations.createBooking(
        f.state,
        roomId: f.roomId,
        guestIds: ['missing'],
        primaryGuestId: 'missing',
        arrivalDate: StayDate(2026, 10, 4),
        departureDate: StayDate(2026, 10, 6),
      ),
      throwsA(hotelError(HotelErrorCode.notFound)),
    );
    expect(
      () => f.operations.createBooking(
        f.state,
        roomId: f.roomId,
        guestIds: [f.guestId],
        primaryGuestId: 'other',
        arrivalDate: StayDate(2026, 10, 4),
        departureDate: StayDate(2026, 10, 6),
      ),
      throwsA(hotelError(HotelErrorCode.validation)),
    );
  });

  test('booked rate and relationships survive room/guest edits', () {
    f.reserve();
    f.state = f.operations.saveRoom(
      f.state,
      id: f.roomId,
      number: '201',
      type: 'Suite',
      nightlyRateMinor: 99900,
    );
    expect(f.state.bookings.single.nightlyRateMinorSnapshot, 125050);
    expect(f.state.bookings.single.roomId, f.roomId);
    expect(f.state.bookings.single.nights, 2);
    expect(
      () => f.state.bookings.single.guestIds.add('other'),
      throwsUnsupportedError,
    );
    expect(() => f.state.rooms.clear(), throwsUnsupportedError);
  });

  test('occupancy and all dashboard counts follow the persisted lifecycle', () {
    f.reserve();
    final id = f.state.bookings.single.id;
    expect(f.state.metrics.totalRooms, 1);
    expect(f.state.metrics.totalGuests, 1);
    expect(f.state.metrics.availableRooms, 1);
    expect(f.state.metrics.occupiedRooms, 0);
    expect(f.state.metrics.activeBookings, 1);
    f.state = f.operations.checkIn(f.state, id);
    expect(f.state.roomStatus(f.roomId), RoomStatus.occupied);
    expect(f.state.metrics.availableRooms, 0);
    expect(f.state.metrics.occupiedRooms, 1);
    expect(f.state.bookings.single.actualCheckInAt, f.now.toUtc());
    expect(
      () => f.operations.checkIn(f.state, id),
      throwsA(hotelError(HotelErrorCode.invalidTransition)),
    );
    expect(
      () => f.operations.cancelBooking(f.state, id),
      throwsA(hotelError(HotelErrorCode.invalidTransition)),
    );
    f.state = f.operations.checkOut(f.state, id);
    expect(f.state.metrics.availableRooms, 1);
    expect(f.state.metrics.occupiedRooms, 0);
    expect(f.state.metrics.activeBookings, 0);
    expect(f.state.bookings.single.status, BookingStatus.checkedOut);
    expect(
      () => f.operations.checkOut(f.state, id),
      throwsA(hotelError(HotelErrorCode.invalidTransition)),
    );
    f.reserve(); // Early checkout releases the originally reserved interval.
  });

  test(
    'cancellation releases availability but protects historical references',
    () {
      f.reserve();
      f.state = f.operations.cancelBooking(f.state, f.state.bookings.single.id);
      expect(f.state.metrics.activeBookings, 0);
      expect(
        () => f.operations.deleteRoom(f.state, f.roomId),
        throwsA(hotelError(HotelErrorCode.linkedRecord)),
      );
      expect(
        () => f.operations.deleteGuest(f.state, f.guestId),
        throwsA(hotelError(HotelErrorCode.linkedRecord)),
      );
      expect(
        () => f.operations.checkIn(f.state, f.state.bookings.single.id),
        throwsA(hotelError(HotelErrorCode.invalidTransition)),
      );
      f.reserve();
    },
  );

  test('future and expired reservations cannot check in', () {
    f.reserve(arrival: 6, departure: 8);
    final id = f.state.bookings.single.id;
    expect(
      () => f.operations.checkIn(f.state, id),
      throwsA(hotelError(HotelErrorCode.invalidTransition)),
    );
    f.now = DateTime(2026, 10, 8);
    expect(
      () => f.operations.checkIn(f.state, id),
      throwsA(hotelError(HotelErrorCode.invalidTransition)),
    );
  });

  test('overdue occupant blocks arrivals until checkout without invalidating saved future stays', () {
    f.reserve();
    final first = f.state.bookings.first.id;
    f.state = f.operations.checkIn(f.state, first);
    f.reserve(arrival: 6, departure: 8);
    final next = f.state.bookings.last.id;
    f.now = DateTime(2026, 10, 6, 12);
    HotelRules.validateSnapshot(f.state);
    expect(
      () => f.operations.checkIn(f.state, next),
      throwsA(hotelError(HotelErrorCode.bookingConflict)),
    );
    expect(
      () => f.reserve(arrival: 10, departure: 12),
      throwsA(hotelError(HotelErrorCode.bookingConflict)),
    );
    f.state = f.operations.checkOut(f.state, first);
    f.state = f.operations.checkIn(f.state, next);
    expect(f.state.metrics.occupiedRooms, 1);
  });

  test('clock rollback cannot produce a checkout before check-in', () {
    f.reserve();
    final id = f.state.bookings.first.id;
    f.state = f.operations.checkIn(f.state, id);
    f.now = f.now.subtract(const Duration(hours: 1));
    expect(
      () => f.operations.checkOut(f.state, id),
      throwsA(hotelError(HotelErrorCode.invalidTransition)),
    );
  });

  test('empty aggregate has zero metrics', () {
    final m = HotelState().metrics;
    expect(
      [
        m.totalRooms,
        m.availableRooms,
        m.occupiedRooms,
        m.totalGuests,
        m.activeBookings,
      ],
      [0, 0, 0, 0, 0],
    );
  });
}
