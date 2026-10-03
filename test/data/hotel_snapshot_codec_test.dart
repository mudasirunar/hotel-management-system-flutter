import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_management_system/data/local/hotel_snapshot_codec.dart';
import 'package:hotel_management_system/domain/hotel_exception.dart';
import 'package:hotel_management_system/domain/models/booking.dart';
import 'package:hotel_management_system/domain/models/hotel_state.dart';

import '../support/fixtures.dart';

void main() {
  final codec = HotelSnapshotCodec();

  test('complete snapshot round trip retains rate, relationships, dates and timestamps', () {
    final f = HotelFixture()..reserve();
    f.state = f.operations.checkIn(f.state, f.state.bookings.single.id);
    final raw = codec.encode(f.state);
    final result = codec.decode(raw);
    expect(codec.encode(result), raw);
    expect(result.bookings.single.status, BookingStatus.checkedIn);
    expect(result.guests.single.phone, '+923001234567');
    expect(result.metrics.occupiedRooms, 1);
    expect(result.bookings.single.arrivalDate.toString(), '2026-10-04');
  });

  test('empty initial snapshot is a valid round trip', () {
    expect(codec.decode(codec.encode(HotelState())).rooms, isEmpty);
  });

  test('malformed input is sanitized and never treated as empty records', () {
    for (final raw in [
      '',
      '{',
      '[]',
      'null',
      '{"schemaVersion":1}',
      '{"phone":"private"}',
    ]) {
      expect(
        () => codec.decode(raw),
        throwsA(hotelError(HotelErrorCode.corruptStorage)),
      );
    }
  });

  test('unsupported schema has a distinct recovery error', () {
    final raw = jsonDecode(codec.encode(HotelState())) as Map<String, dynamic>;
    raw['schemaVersion'] = 2;
    expect(
      () => codec.decode(jsonEncode(raw)),
      throwsA(hotelError(HotelErrorCode.unsupportedSchema)),
    );
  });

  final corruptions = <String, void Function(Map<String, dynamic>)>{
    'duplicate IDs': (j) => j['guests'][0]['id'] = j['rooms'][0]['id'],
    'duplicate room numbers': (j) => (j['rooms'] as List).add({
      ...j['rooms'][0] as Map,
      'id': 'another-room',
    }),
    'duplicate CNIC': (j) => (j['guests'] as List).add({
      ...j['guests'][0] as Map,
      'id': 'another-guest',
    }),
    'missing room reference': (j) => j['bookings'][0]['roomId'] = 'missing',
    'missing guest reference': (j) =>
        j['bookings'][0]['guestIds'] = ['missing'],
    'empty guest list': (j) => j['bookings'][0]['guestIds'] = [],
    'primary guest not selected': (j) =>
        j['bookings'][0]['primaryGuestId'] = 'other',
    'duplicate selected guests': (j) => j['bookings'][0]['guestIds'] = [
      j['guests'][0]['id'],
      j['guests'][0]['id'],
    ],
    'unknown status': (j) => j['bookings'][0]['status'] = 'unknown',
    'overlapping reservations': (j) => (j['bookings'] as List).add({
      ...j['bookings'][0] as Map,
      'id': 'another-booking',
    }),
    'zero nightly rate': (j) => j['rooms'][0]['nightlyRateMinor'] = 0,
    'fractional minor units': (j) => j['rooms'][0]['nightlyRateMinor'] = 1.5,
    'zero quoted rate': (j) => j['bookings'][0]['nightlyRateMinorSnapshot'] = 0,
    'invalid calendar date': (j) =>
        j['bookings'][0]['arrivalDate'] = '2026-02-30',
    'zero night stay': (j) =>
        j['bookings'][0]['departureDate'] = j['bookings'][0]['arrivalDate'],
    'missing check-in timestamp': (j) =>
        j['bookings'][0]['status'] = 'checkedIn',
    'timestamp on reserved booking': (j) =>
        j['bookings'][0]['actualCheckInAt'] = j['bookings'][0]['createdAt'],
    'audit timestamp before creation': (j) =>
        j['rooms'][0]['updatedAt'] = '2020-01-01T00:00:00.000Z',
    'invalid audit date': (j) =>
        j['rooms'][0]['updatedAt'] = '2026-02-30T00:00:00.000Z',
    'noncanonical phone': (j) => j['guests'][0]['phone'] = '03001234567',
  };
  for (final entry in corruptions.entries) {
    test('rejects ${entry.key}', () {
      final f = HotelFixture()..reserve();
      final raw = jsonDecode(codec.encode(f.state)) as Map<String, dynamic>;
      entry.value(raw);
      expect(
        () => codec.decode(jsonEncode(raw)),
        throwsA(hotelError(HotelErrorCode.corruptStorage)),
      );
    });
  }

  test(
    'saved past and overdue reservations remain readable as dates move on',
    () {
      final f = HotelFixture()..reserve();
      f.state = f.operations.checkIn(f.state, f.state.bookings.single.id);
      f.reserve(arrival: 6, departure: 8);
      f.now = DateTime(2026, 10, 20);
      expect(codec.decode(codec.encode(f.state)).bookings.length, 2);
    },
  );
  test('two physical occupants cannot share a room even with adjacent planned dates', () {
    final f = HotelFixture()..reserve();
    f.state = f.operations.checkIn(f.state, f.state.bookings.single.id);
    f.reserve(arrival: 6, departure: 8);
    final raw = jsonDecode(codec.encode(f.state)) as Map<String, dynamic>;
    raw['bookings'][1]['status'] = 'checkedIn';
    raw['bookings'][1]['actualCheckInAt'] = raw['bookings'][1]['createdAt'];
    expect(
      () => codec.decode(jsonEncode(raw)),
      throwsA(hotelError(HotelErrorCode.corruptStorage)),
    );
  });

  test(
    'completed stay timestamps must be ordered and bounded by audit timestamps',
    () {
      final f = HotelFixture()..reserve();
      final id = f.state.bookings.single.id;
      f.state = f.operations.checkIn(f.state, id);
      f.state = f.operations.checkOut(f.state, id);
      final valid = codec.encode(f.state);
      for (final field in ['actualCheckInAt', 'actualCheckOutAt']) {
        final raw = jsonDecode(valid) as Map<String, dynamic>;
        raw['bookings'][0][field] = null;
        expect(
          () => codec.decode(jsonEncode(raw)),
          throwsA(hotelError(HotelErrorCode.corruptStorage)),
        );
      }
      final raw = jsonDecode(valid) as Map<String, dynamic>;
      raw['bookings'][0]['actualCheckOutAt'] = f.now
          .toUtc()
          .subtract(const Duration(hours: 1))
          .toIso8601String();
      expect(
        () => codec.decode(jsonEncode(raw)),
        throwsA(hotelError(HotelErrorCode.corruptStorage)),
      );
    },
  );
}
