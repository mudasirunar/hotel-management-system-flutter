import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_management_system/domain/hotel_exception.dart';
import 'package:hotel_management_system/domain/models/hotel_state.dart';
import 'package:hotel_management_system/domain/models/stay_date.dart';
import 'package:hotel_management_system/domain/services/hotel_operations.dart';

Matcher hotelError(HotelErrorCode code) =>
    isA<HotelException>().having((e) => e.code, 'code', code);

final class HotelFixture {
  DateTime now = DateTime(2026, 10, 4, 12);
  int _id = 0;
  late final operations = HotelOperations(
    clock: () => now,
    createId: () => 'record-${_id++}',
  );
  late HotelState state = _seed();
  String get roomId => state.rooms.first.id;
  String get guestId => state.guests.first.id;

  HotelState _seed() {
    var s = operations.saveRoom(
      HotelState(),
      number: '101',
      type: 'Double',
      nightlyRateMinor: 125050,
    );
    s = operations.saveGuest(
      s,
      name: 'Sample Guest',
      phone: '03001234567',
      cnic: '12345-1234567-1',
      address: 'Fictional test address',
    );
    return s;
  }

  HotelState reserve({int arrival = 4, int departure = 6, String? room}) {
    state = operations.createBooking(
      state,
      roomId: room ?? roomId,
      guestIds: [guestId],
      primaryGuestId: guestId,
      arrivalDate: StayDate(2026, 10, arrival),
      departureDate: StayDate(2026, 10, departure),
    );
    return state;
  }
}
