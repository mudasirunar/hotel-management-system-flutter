import '../hotel_exception.dart';
import 'booking.dart';
import 'guest.dart';
import 'room.dart';

final class HotelState {
  HotelState({
    List<Room> rooms = const [],
    List<Guest> guests = const [],
    List<Booking> bookings = const [],
  }) : rooms = List.unmodifiable(rooms),
       guests = List.unmodifiable(guests),
       bookings = List.unmodifiable(bookings);

  final List<Room> rooms;
  final List<Guest> guests;
  final List<Booking> bookings;

  HotelState copyWith({
    List<Room>? rooms,
    List<Guest>? guests,
    List<Booking>? bookings,
  }) => HotelState(
    rooms: rooms ?? this.rooms,
    guests: guests ?? this.guests,
    bookings: bookings ?? this.bookings,
  );

  Room room(String id) => rooms.firstWhere(
    (r) => r.id == id,
    orElse: () => throw const HotelException(
      HotelErrorCode.notFound,
      'Room no longer exists.',
    ),
  );
  Guest guest(String id) => guests.firstWhere(
    (g) => g.id == id,
    orElse: () => throw const HotelException(
      HotelErrorCode.notFound,
      'Guest no longer exists.',
    ),
  );
  Booking booking(String id) => bookings.firstWhere(
    (b) => b.id == id,
    orElse: () => throw const HotelException(
      HotelErrorCode.notFound,
      'Booking no longer exists.',
    ),
  );

  RoomStatus roomStatus(String roomId) {
    room(roomId);
    return bookings.any(
          (b) => b.roomId == roomId && b.status == BookingStatus.checkedIn,
        )
        ? RoomStatus.occupied
        : RoomStatus.available;
  }

  HotelMetrics get metrics {
    final occupied = bookings
        .where((b) => b.status == BookingStatus.checkedIn)
        .map((b) => b.roomId)
        .toSet()
        .length;
    return HotelMetrics(
      totalRooms: rooms.length,
      availableRooms: rooms.length - occupied,
      occupiedRooms: occupied,
      totalGuests: guests.length,
      activeBookings: bookings.where((b) => b.isActive).length,
    );
  }
}

final class HotelMetrics {
  const HotelMetrics({
    required this.totalRooms,
    required this.availableRooms,
    required this.occupiedRooms,
    required this.totalGuests,
    required this.activeBookings,
  });
  final int totalRooms;
  final int availableRooms;
  final int occupiedRooms;
  final int totalGuests;
  final int activeBookings;
}
