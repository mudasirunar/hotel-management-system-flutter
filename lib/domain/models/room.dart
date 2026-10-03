enum RoomStatus { available, occupied }

final class Room {
  const Room({
    required this.id,
    required this.number,
    required this.type,
    required this.nightlyRateMinor,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String number;
  final String type;
  final int nightlyRateMinor;
  final DateTime createdAt;
  final DateTime updatedAt;
}
