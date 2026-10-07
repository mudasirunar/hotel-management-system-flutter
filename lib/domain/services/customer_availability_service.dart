import '../models/customer_booking.dart';
import '../models/hotel_catalog.dart';
import '../models/hotel_room.dart';
import '../models/inventory_block.dart';
import '../models/stay_date.dart';

enum RoomAvailabilityStatus {
  available,
  occupied,
  reserved,
}

final class CustomerAvailabilityService {
  const CustomerAvailabilityService();

  /// Evaluates room status for a given calendar interval `[arrival, departure)`
  /// taking into account catalog inventory blocks and active user bookings.
  RoomAvailabilityStatus checkRoomStatus({
    required HotelRoom room,
    required StayDate arrival,
    required StayDate departure,
    required List<InventoryBlock> inventoryBlocks,
    required List<CustomerBooking> userBookings,
  }) {
    // Check catalog fixture blocks for this room
    for (final block in inventoryBlocks) {
      if (block.roomId == room.id && block.overlaps(arrival, departure)) {
        if (block.kind == 'occupied') {
          return RoomAvailabilityStatus.occupied;
        }
        return RoomAvailabilityStatus.reserved;
      }
    }

    // Check user's own active bookings for this room
    for (final booking in userBookings) {
      if (booking.roomId == room.id && booking.overlaps(arrival, departure)) {
        return RoomAvailabilityStatus.reserved;
      }
    }

    return RoomAvailabilityStatus.available;
  }

  /// Evaluates whether a room can be booked for the specified stay.
  /// Returns null if eligible, or an error message if ineligible.
  String? validateBookingEligibility({
    required HotelRoom room,
    required StayDate arrival,
    required StayDate departure,
    required int partySize,
    required StayDate earliestAllowedArrival,
    required HotelCatalog catalog,
    required List<CustomerBooking> userBookings,
  }) {
    if (arrival.isBefore(earliestAllowedArrival)) {
      return 'Check-in date cannot be in the past.';
    }
    if (!arrival.isBefore(departure)) {
      return 'Departure date must be after check-in date.';
    }
    if (partySize < 1) {
      return 'Party size must be at least 1 guest.';
    }
    if (partySize > room.capacity) {
      return 'This room accommodates up to ${room.capacity} guests.';
    }

    final status = checkRoomStatus(
      room: room,
      arrival: arrival,
      departure: departure,
      inventoryBlocks: catalog.inventoryBlocks,
      userBookings: userBookings,
    );

    if (status == RoomAvailabilityStatus.occupied) {
      return 'This room is occupied during the selected dates.';
    }
    if (status == RoomAvailabilityStatus.reserved) {
      return 'This room is already reserved for the selected dates.';
    }

    return null;
  }

  /// Calculates total stay cost in minor units (or PKR).
  int calculateTotalAmount({
    required HotelRoom room,
    required StayDate arrival,
    required StayDate departure,
  }) {
    final nights = arrival.nightsUntil(departure);
    if (nights <= 0) return 0;
    return nights * room.nightlyRateMinor;
  }
}
