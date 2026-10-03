import 'stay_date.dart';

enum BookingStatus { reserved, checkedIn, checkedOut, cancelled }

final class Booking {
  Booking({
    required this.id,
    required this.roomId,
    required List<String> guestIds,
    required this.primaryGuestId,
    required this.arrivalDate,
    required this.departureDate,
    required this.nightlyRateMinorSnapshot,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.actualCheckInAt,
    this.actualCheckOutAt,
  }) : guestIds = List.unmodifiable(guestIds);

  final String id;
  final String roomId;
  final List<String> guestIds;
  final String primaryGuestId;
  final StayDate arrivalDate;
  final StayDate departureDate;
  final int nightlyRateMinorSnapshot;
  final BookingStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? actualCheckInAt;
  final DateTime? actualCheckOutAt;

  bool get isActive =>
      status == BookingStatus.reserved || status == BookingStatus.checkedIn;
  int get nights => arrivalDate.nightsUntil(departureDate);

  Booking transitionTo(BookingStatus next, DateTime at) => Booking(
    id: id,
    roomId: roomId,
    guestIds: guestIds,
    primaryGuestId: primaryGuestId,
    arrivalDate: arrivalDate,
    departureDate: departureDate,
    nightlyRateMinorSnapshot: nightlyRateMinorSnapshot,
    status: next,
    createdAt: createdAt,
    updatedAt: at,
    actualCheckInAt: next == BookingStatus.checkedIn ? at : actualCheckInAt,
    actualCheckOutAt: next == BookingStatus.checkedOut ? at : actualCheckOutAt,
  );
}
