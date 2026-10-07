import 'stay_date.dart';

enum CustomerBookingStatus { reserved, cancelled }

/// An immutable reservation made by the local traveler.
final class CustomerBooking {
  const CustomerBooking({
    required this.id,
    required this.ownerId,
    required this.hotelId,
    required this.roomId,
    required this.arrivalDate,
    required this.departureDate,
    required this.partySize,
    required this.travelerName,
    required this.travelerPhone,
    this.travelerEmail,
    required this.hotelName,
    required this.hotelAddress,
    required this.roomType,
    required this.roomNumber,
    required this.nightlyRateMinor,
    required this.totalAmountMinor,
    this.currency = 'PKR',
    required this.cancellationPolicy,
    this.status = CustomerBookingStatus.reserved,
    required this.createdAt,
    this.cancelledAt,
  });

  factory CustomerBooking.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final ownerId = json['ownerId'] as String? ?? 'default_traveler';
    final hotelId = json['hotelId'] as String?;
    final roomId = json['roomId'] as String?;
    final arrival = json['arrivalDate'] as String?;
    final departure = json['departureDate'] as String?;
    final partySize = json['partySize'] as int? ?? 1;

    final travelerName = json['travelerName'] as String? ?? '';
    final travelerPhone = json['travelerPhone'] as String? ?? '';
    final travelerEmail = json['travelerEmail'] as String?;

    final hotelName = json['hotelName'] as String? ?? '';
    final hotelAddress = json['hotelAddress'] as String? ?? '';
    final roomType = json['roomType'] as String? ?? '';
    final roomNumber = json['roomNumber'] as String? ?? '';

    final nightlyRateMinor = json['nightlyRateMinor'] as int? ?? 0;
    final totalAmountMinor = json['totalAmountMinor'] as int? ?? 0;
    final currency = json['currency'] as String? ?? 'PKR';
    final policy = json['cancellationPolicy'] as String? ?? '';

    final statusStr = json['status'] as String? ?? 'reserved';
    final status = statusStr == 'cancelled'
        ? CustomerBookingStatus.cancelled
        : CustomerBookingStatus.reserved;

    final createdStr = json['createdAt'] as String?;
    final createdAt = createdStr != null ? DateTime.parse(createdStr) : DateTime.now();

    final cancelledStr = json['cancelledAt'] as String?;
    final cancelledAt = cancelledStr != null ? DateTime.parse(cancelledStr) : null;

    if (id == null || id.trim().isEmpty) {
      throw const FormatException('Booking requires an id.');
    }
    if (hotelId == null || hotelId.trim().isEmpty) {
      throw const FormatException('Booking requires a hotelId.');
    }
    if (roomId == null || roomId.trim().isEmpty) {
      throw const FormatException('Booking requires a roomId.');
    }
    if (arrival == null || departure == null) {
      throw const FormatException('Booking requires arrival and departure dates.');
    }

    final arrivalDate = StayDate.parse(arrival);
    final departureDate = StayDate.parse(departure);
    if (!arrivalDate.isBefore(departureDate)) {
      throw const FormatException('Arrival date must precede departure date.');
    }

    return CustomerBooking(
      id: id.trim(),
      ownerId: ownerId.trim(),
      hotelId: hotelId.trim(),
      roomId: roomId.trim(),
      arrivalDate: arrivalDate,
      departureDate: departureDate,
      partySize: partySize < 1 ? 1 : partySize,
      travelerName: travelerName.trim(),
      travelerPhone: travelerPhone.trim(),
      travelerEmail: travelerEmail?.trim(),
      hotelName: hotelName.trim(),
      hotelAddress: hotelAddress.trim(),
      roomType: roomType.trim(),
      roomNumber: roomNumber.trim(),
      nightlyRateMinor: nightlyRateMinor,
      totalAmountMinor: totalAmountMinor,
      currency: currency.trim(),
      cancellationPolicy: policy.trim(),
      status: status,
      createdAt: createdAt,
      cancelledAt: cancelledAt,
    );
  }

  final String id;
  final String ownerId;
  final String hotelId;
  final String roomId;
  final StayDate arrivalDate;
  final StayDate departureDate;
  final int partySize;

  // Contact snapshot
  final String travelerName;
  final String travelerPhone;
  final String? travelerEmail;

  // Hotel & Room snapshot
  final String hotelName;
  final String hotelAddress;
  final String roomType;
  final String roomNumber;

  // Pricing & Policy snapshot
  final int nightlyRateMinor;
  final int totalAmountMinor;
  final String currency;
  final String cancellationPolicy;

  // Status & Timestamps
  final CustomerBookingStatus status;
  final DateTime createdAt;
  final DateTime? cancelledAt;

  int get nights => arrivalDate.nightsUntil(departureDate);
  bool get isCancelled => status == CustomerBookingStatus.cancelled;
  bool get isActive => status == CustomerBookingStatus.reserved;

  /// Returns true if this booking is active and overlaps with `[arrival, departure)`.
  bool overlaps(StayDate arrival, StayDate departure) =>
      isActive &&
      arrivalDate.isBefore(departure) &&
      arrival.isBefore(departureDate);

  CustomerBooking cancel({required DateTime at}) => CustomerBooking(
    id: id,
    ownerId: ownerId,
    hotelId: hotelId,
    roomId: roomId,
    arrivalDate: arrivalDate,
    departureDate: departureDate,
    partySize: partySize,
    travelerName: travelerName,
    travelerPhone: travelerPhone,
    travelerEmail: travelerEmail,
    hotelName: hotelName,
    hotelAddress: hotelAddress,
    roomType: roomType,
    roomNumber: roomNumber,
    nightlyRateMinor: nightlyRateMinor,
    totalAmountMinor: totalAmountMinor,
    currency: currency,
    cancellationPolicy: cancellationPolicy,
    status: CustomerBookingStatus.cancelled,
    createdAt: createdAt,
    cancelledAt: at,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'ownerId': ownerId,
    'hotelId': hotelId,
    'roomId': roomId,
    'arrivalDate': arrivalDate.toString(),
    'departureDate': departureDate.toString(),
    'partySize': partySize,
    'travelerName': travelerName,
    'travelerPhone': travelerPhone,
    if (travelerEmail != null) 'travelerEmail': travelerEmail,
    'hotelName': hotelName,
    'hotelAddress': hotelAddress,
    'roomType': roomType,
    'roomNumber': roomNumber,
    'nightlyRateMinor': nightlyRateMinor,
    'totalAmountMinor': totalAmountMinor,
    'currency': currency,
    'cancellationPolicy': cancellationPolicy,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    if (cancelledAt != null) 'cancelledAt': cancelledAt!.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerBooking &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          status == other.status;

  @override
  int get hashCode => Object.hash(id, status);
}
