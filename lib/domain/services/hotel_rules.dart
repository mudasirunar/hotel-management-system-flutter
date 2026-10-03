import '../hotel_exception.dart';
import '../models/booking.dart';
import '../models/hotel_state.dart';
import '../models/stay_date.dart';
import 'input_validation.dart';

abstract final class HotelRules {
  static void dateRange(
    StayDate arrival,
    StayDate departure, {
    StayDate? today,
  }) {
    if (!arrival.isBefore(departure)) {
      InputValidation.invalid(
        'departureDate',
        'Departure must be after arrival.',
      );
    }
    if (today != null && arrival.isBefore(today)) {
      InputValidation.invalid('arrivalDate', 'Arrival cannot be in the past.');
    }
  }

  static bool overlaps(StayDate arrival, StayDate departure, Booking booking) =>
      arrival.isBefore(booking.departureDate) &&
      booking.arrivalDate.isBefore(departure);

  static bool roomAvailable(
    HotelState state,
    String roomId,
    StayDate arrival,
    StayDate departure, {
    required StayDate today,
    String? excludingBookingId,
  }) {
    state.room(roomId);
    dateRange(arrival, departure);
    for (final booking in state.bookings) {
      if (booking.roomId != roomId ||
          booking.id == excludingBookingId ||
          !booking.isActive) {
        continue;
      }
      if (overlaps(arrival, departure, booking)) return false;
      // An overdue occupant has not released the room, regardless of planned dates.
      if (booking.status == BookingStatus.checkedIn &&
          !today.isBefore(booking.departureDate) &&
          booking.arrivalDate.isBefore(departure)) {
        return false;
      }
    }
    return true;
  }

  /// Validates saved records without applying today's new-reservation policy.
  /// An overdue occupant and an existing, adjacent reservation remain readable.
  static void validateSnapshot(HotelState state) {
    final ids = <String>{};
    final numbers = <String>{};
    final cnics = <String>{};
    final roomIds = state.rooms.map((r) => r.id).toSet();
    final guestIds = state.guests.map((g) => g.id).toSet();
    void record(String id, DateTime created, DateTime updated) {
      _require(id.isNotEmpty && id == id.trim() && ids.add(id));
      _require(created.isUtc && updated.isUtc && !updated.isBefore(created));
    }

    for (final room in state.rooms) {
      record(room.id, room.createdAt, room.updatedAt);
      _require(InputValidation.roomNumber(room.number) == room.number);
      _require(InputValidation.roomType(room.type) == room.type);
      _require(numbers.add(room.number.toLowerCase()));
      InputValidation.rate(room.nightlyRateMinor);
    }
    for (final guest in state.guests) {
      record(guest.id, guest.createdAt, guest.updatedAt);
      _require(InputValidation.name(guest.name) == guest.name);
      _require(InputValidation.phone(guest.phone) == guest.phone);
      _require(InputValidation.cnic(guest.cnic) == guest.cnic);
      _require(InputValidation.address(guest.address) == guest.address);
      _require(cnics.add(guest.cnic));
    }
    final occupied = <String>{};
    final activeByRoom = <String, List<Booking>>{};
    for (final booking in state.bookings) {
      record(booking.id, booking.createdAt, booking.updatedAt);
      _require(roomIds.contains(booking.roomId));
      _require(
        booking.guestIds.isNotEmpty &&
            booking.guestIds.toSet().length == booking.guestIds.length,
      );
      _require(
        booking.guestIds.every(guestIds.contains) &&
            booking.guestIds.contains(booking.primaryGuestId),
      );
      dateRange(booking.arrivalDate, booking.departureDate);
      InputValidation.rate(booking.nightlyRateMinorSnapshot);
      final checkIn = booking.actualCheckInAt;
      final checkOut = booking.actualCheckOutAt;
      switch (booking.status) {
        case BookingStatus.reserved || BookingStatus.cancelled:
          _require(checkIn == null && checkOut == null);
        case BookingStatus.checkedIn:
          _require(
            checkIn != null && checkOut == null && occupied.add(booking.roomId),
          );
        case BookingStatus.checkedOut:
          _require(
            checkIn != null && checkOut != null && !checkOut.isBefore(checkIn),
          );
      }
      for (final time in [checkIn, checkOut].whereType<DateTime>()) {
        _require(
          time.isUtc &&
              !time.isBefore(booking.createdAt) &&
              !time.isAfter(booking.updatedAt),
        );
      }
      if (booking.isActive) (activeByRoom[booking.roomId] ??= []).add(booking);
    }
    for (final bookings in activeByRoom.values) {
      bookings.sort((a, b) => a.arrivalDate.compareTo(b.arrivalDate));
      for (var i = 1; i < bookings.length; i++) {
        _require(
          !bookings[i].arrivalDate.isBefore(bookings[i - 1].departureDate),
        );
      }
    }
  }

  static void _require(bool condition) {
    if (!condition) {
      throw const HotelException(
        HotelErrorCode.validation,
        'Records are inconsistent.',
      );
    }
  }
}
