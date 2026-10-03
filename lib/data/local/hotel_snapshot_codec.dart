import 'dart:convert';

import '../../domain/hotel_exception.dart';
import '../../domain/models/booking.dart';
import '../../domain/models/guest.dart';
import '../../domain/models/hotel_state.dart';
import '../../domain/models/room.dart';
import '../../domain/models/stay_date.dart';
import '../../domain/services/hotel_rules.dart';

final class HotelSnapshotCodec {
  static const schemaVersion = 1;

  String encode(HotelState state) {
    HotelRules.validateSnapshot(state);
    return jsonEncode({
      'schemaVersion': schemaVersion,
      'rooms': [
        for (final r in state.rooms)
          {
            'id': r.id,
            'number': r.number,
            'type': r.type,
            'nightlyRateMinor': r.nightlyRateMinor,
            'createdAt': r.createdAt.toIso8601String(),
            'updatedAt': r.updatedAt.toIso8601String(),
          },
      ],
      'guests': [
        for (final g in state.guests)
          {
            'id': g.id,
            'name': g.name,
            'phone': g.phone,
            'cnic': g.cnic,
            'address': g.address,
            'createdAt': g.createdAt.toIso8601String(),
            'updatedAt': g.updatedAt.toIso8601String(),
          },
      ],
      'bookings': [
        for (final b in state.bookings)
          {
            'id': b.id,
            'roomId': b.roomId,
            'guestIds': b.guestIds,
            'primaryGuestId': b.primaryGuestId,
            'arrivalDate': b.arrivalDate.toString(),
            'departureDate': b.departureDate.toString(),
            'nightlyRateMinorSnapshot': b.nightlyRateMinorSnapshot,
            'status': b.status.name,
            'createdAt': b.createdAt.toIso8601String(),
            'updatedAt': b.updatedAt.toIso8601String(),
            'actualCheckInAt': b.actualCheckInAt?.toIso8601String(),
            'actualCheckOutAt': b.actualCheckOutAt?.toIso8601String(),
          },
      ],
    });
  }

  HotelState decode(String source) {
    try {
      final json = _object(jsonDecode(source));
      if (_integer(json, 'schemaVersion') != schemaVersion) {
        throw const HotelException(
          HotelErrorCode.unsupportedSchema,
          'These records use an unsupported data version. Use a compatible app version; your records have not been changed.',
        );
      }
      final state = HotelState(
        rooms: [
          for (final r in _records(json, 'rooms'))
            Room(
              id: _string(r, 'id'),
              number: _string(r, 'number'),
              type: _string(r, 'type'),
              nightlyRateMinor: _integer(r, 'nightlyRateMinor'),
              createdAt: _time(r, 'createdAt'),
              updatedAt: _time(r, 'updatedAt'),
            ),
        ],
        guests: [
          for (final g in _records(json, 'guests'))
            Guest(
              id: _string(g, 'id'),
              name: _string(g, 'name'),
              phone: _string(g, 'phone'),
              cnic: _string(g, 'cnic'),
              address: _string(g, 'address'),
              createdAt: _time(g, 'createdAt'),
              updatedAt: _time(g, 'updatedAt'),
            ),
        ],
        bookings: [
          for (final b in _records(json, 'bookings'))
            Booking(
              id: _string(b, 'id'),
              roomId: _string(b, 'roomId'),
              guestIds: (b['guestIds'] as List).cast<String>(),
              primaryGuestId: _string(b, 'primaryGuestId'),
              arrivalDate: StayDate.parse(_string(b, 'arrivalDate')),
              departureDate: StayDate.parse(_string(b, 'departureDate')),
              nightlyRateMinorSnapshot: _integer(b, 'nightlyRateMinorSnapshot'),
              status: BookingStatus.values.byName(_string(b, 'status')),
              createdAt: _time(b, 'createdAt'),
              updatedAt: _time(b, 'updatedAt'),
              actualCheckInAt: _optionalTime(b, 'actualCheckInAt'),
              actualCheckOutAt: _optionalTime(b, 'actualCheckOutAt'),
            ),
        ],
      );
      HotelRules.validateSnapshot(state);
      return state;
    } on HotelException catch (error) {
      if (error.code == HotelErrorCode.unsupportedSchema) rethrow;
      throw _corrupt;
    } on FormatException {
      throw _corrupt;
    } on TypeError {
      throw _corrupt;
    } on ArgumentError {
      throw _corrupt;
    }
  }

  static const _corrupt = HotelException(
    HotelErrorCode.corruptStorage,
    'Saved records could not be read safely. Your records have not been changed.',
  );
  static Map<String, dynamic> _object(Object? value) =>
      value as Map<String, dynamic>;
  static Iterable<Map<String, dynamic>> _records(
    Map<String, dynamic> json,
    String key,
  ) => (json[key] as List).map(_object);
  static String _string(Map<String, dynamic> json, String key) =>
      json[key] as String;
  static int _integer(Map<String, dynamic> json, String key) =>
      json[key] as int;
  static DateTime _time(Map<String, dynamic> json, String key) {
    final raw = _string(json, key);
    final time = DateTime.parse(raw);
    if (!time.isUtc || time.toIso8601String() != raw) throw _corrupt;
    return time;
  }

  static DateTime? _optionalTime(Map<String, dynamic> json, String key) =>
      json[key] == null ? null : _time(json, key);
}
