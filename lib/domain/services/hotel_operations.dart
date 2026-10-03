import 'dart:math';

import '../hotel_exception.dart';
import '../models/booking.dart';
import '../models/guest.dart';
import '../models/hotel_state.dart';
import '../models/room.dart';
import '../models/stay_date.dart';
import 'hotel_rules.dart';
import 'input_validation.dart';

/// Pure state transformations. The controller is responsible for persistence.
final class HotelOperations {
  HotelOperations({DateTime Function()? clock, String Function()? createId})
    : _clock = clock ?? DateTime.now,
      _createId = createId ?? _randomId;

  final DateTime Function() _clock;
  final String Function() _createId;
  static final _random = Random.secure();
  static String _randomId() => List.generate(
    16,
    (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();

  StayDate get today => StayDate.fromDateTime(_clock());

  HotelState saveRoom(
    HotelState state, {
    String? id,
    required String number,
    required String type,
    required int nightlyRateMinor,
  }) {
    final old = id == null ? null : state.room(id);
    final normalized = InputValidation.roomNumber(number);
    if (state.rooms.any(
      (r) => r.id != id && r.number.toLowerCase() == normalized.toLowerCase(),
    )) {
      throw const HotelException(
        HotelErrorCode.duplicate,
        'That room number is already in use.',
        field: 'number',
      );
    }
    InputValidation.rate(nightlyRateMinor);
    final now = _clock().toUtc();
    final room = Room(
      id: old?.id ?? _createId(),
      number: normalized,
      type: InputValidation.roomType(type),
      nightlyRateMinor: nightlyRateMinor,
      createdAt: old?.createdAt ?? now,
      updatedAt: now,
    );
    return _checked(
      state.copyWith(
        rooms: old == null
            ? [...state.rooms, room]
            : [
                for (final r in state.rooms)
                  if (r.id == id) room else r,
              ],
      ),
    );
  }

  HotelState deleteRoom(HotelState state, String id) {
    state.room(id);
    if (state.bookings.any((b) => b.roomId == id)) {
      throw const HotelException(
        HotelErrorCode.linkedRecord,
        'This room has booking history and cannot be deleted.',
      );
    }
    return state.copyWith(rooms: state.rooms.where((r) => r.id != id).toList());
  }

  HotelState saveGuest(
    HotelState state, {
    String? id,
    required String name,
    required String phone,
    required String cnic,
    required String address,
  }) {
    final old = id == null ? null : state.guest(id);
    final normalizedCnic = InputValidation.cnic(cnic);
    if (state.guests.any((g) => g.id != id && g.cnic == normalizedCnic)) {
      throw const HotelException(
        HotelErrorCode.duplicate,
        'A guest with that CNIC already exists.',
        field: 'cnic',
      );
    }
    final now = _clock().toUtc();
    final guest = Guest(
      id: old?.id ?? _createId(),
      name: InputValidation.name(name),
      phone: InputValidation.phone(phone),
      cnic: normalizedCnic,
      address: InputValidation.address(address),
      createdAt: old?.createdAt ?? now,
      updatedAt: now,
    );
    return _checked(
      state.copyWith(
        guests: old == null
            ? [...state.guests, guest]
            : [
                for (final g in state.guests)
                  if (g.id == id) guest else g,
              ],
      ),
    );
  }

  HotelState deleteGuest(HotelState state, String id) {
    state.guest(id);
    if (state.bookings.any((b) => b.guestIds.contains(id))) {
      throw const HotelException(
        HotelErrorCode.linkedRecord,
        'This guest has booking history and cannot be deleted.',
      );
    }
    return state.copyWith(
      guests: state.guests.where((g) => g.id != id).toList(),
    );
  }

  HotelState createBooking(
    HotelState state, {
    required String roomId,
    required List<String> guestIds,
    required String primaryGuestId,
    required StayDate arrivalDate,
    required StayDate departureDate,
  }) {
    final now = _clock();
    final today = StayDate.fromDateTime(now);
    HotelRules.dateRange(arrivalDate, departureDate, today: today);
    final room = state.room(roomId);
    if (guestIds.isEmpty ||
        guestIds.toSet().length != guestIds.length ||
        !guestIds.contains(primaryGuestId)) {
      InputValidation.invalid(
        'guests',
        'Select guests once each and choose a primary guest.',
      );
    }
    for (final id in guestIds) {
      state.guest(id);
    }
    if (!HotelRules.roomAvailable(
      state,
      roomId,
      arrivalDate,
      departureDate,
      today: today,
    )) {
      throw const HotelException(
        HotelErrorCode.bookingConflict,
        'This room is unavailable for those dates. Choose another room or change the dates.',
        field: 'room',
      );
    }
    final booking = Booking(
      id: _createId(),
      roomId: roomId,
      guestIds: guestIds,
      primaryGuestId: primaryGuestId,
      arrivalDate: arrivalDate,
      departureDate: departureDate,
      nightlyRateMinorSnapshot: room.nightlyRateMinor,
      status: BookingStatus.reserved,
      createdAt: now.toUtc(),
      updatedAt: now.toUtc(),
    );
    return _checked(state.copyWith(bookings: [...state.bookings, booking]));
  }

  HotelState checkIn(HotelState state, String id) {
    final booking = state.booking(id);
    _expectStatus(booking, BookingStatus.reserved);
    final now = _clock();
    final today = StayDate.fromDateTime(now);
    if (today.isBefore(booking.arrivalDate) ||
        !today.isBefore(booking.departureDate)) {
      throw const HotelException(
        HotelErrorCode.invalidTransition,
        'Check-in is available from the arrival date until the day before departure.',
      );
    }
    if (state.roomStatus(booking.roomId) == RoomStatus.occupied ||
        !HotelRules.roomAvailable(
          state,
          booking.roomId,
          booking.arrivalDate,
          booking.departureDate,
          today: today,
          excludingBookingId: id,
        )) {
      throw const HotelException(
        HotelErrorCode.bookingConflict,
        'This room is still occupied or has a conflicting reservation.',
      );
    }
    return _transition(state, booking, BookingStatus.checkedIn, now.toUtc());
  }

  HotelState checkOut(HotelState state, String id) {
    final booking = state.booking(id);
    _expectStatus(booking, BookingStatus.checkedIn);
    return _transition(
      state,
      booking,
      BookingStatus.checkedOut,
      _clock().toUtc(),
    );
  }

  HotelState cancelBooking(HotelState state, String id) {
    final booking = state.booking(id);
    _expectStatus(booking, BookingStatus.reserved);
    return _transition(
      state,
      booking,
      BookingStatus.cancelled,
      _clock().toUtc(),
    );
  }

  HotelState _transition(
    HotelState state,
    Booking booking,
    BookingStatus status,
    DateTime at,
  ) {
    if (at.isBefore(booking.updatedAt)) {
      throw const HotelException(
        HotelErrorCode.invalidTransition,
        'The device clock is earlier than the last change. Check the date and time, then retry.',
      );
    }
    return _checked(
      state.copyWith(
        bookings: [
          for (final b in state.bookings)
            if (b.id == booking.id) b.transitionTo(status, at) else b,
        ],
      ),
    );
  }

  static void _expectStatus(Booking booking, BookingStatus expected) {
    if (booking.status != expected) {
      throw const HotelException(
        HotelErrorCode.invalidTransition,
        'This action is not available for the current booking status.',
      );
    }
  }

  static HotelState _checked(HotelState state) {
    HotelRules.validateSnapshot(state);
    return state;
  }
}
