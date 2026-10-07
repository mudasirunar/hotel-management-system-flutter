import 'stay_date.dart';

/// An anonymous inventory block indicating dates when a room is unavailable
/// (e.g. booked by fixture or maintenance).
final class InventoryBlock {
  const InventoryBlock({
    required this.id,
    required this.roomId,
    required this.startDate,
    required this.endDate,
    required this.kind,
  });

  factory InventoryBlock.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final roomId = json['roomId'] as String?;
    final start = json['startDate'] as String?;
    final end = json['endDate'] as String?;
    final kind = json['kind'] as String? ?? 'reserved';

    if (id == null || id.trim().isEmpty) {
      throw const FormatException('Inventory block requires an id.');
    }
    if (roomId == null || roomId.trim().isEmpty) {
      throw const FormatException('Inventory block requires a roomId.');
    }
    if (start == null || end == null) {
      throw const FormatException('Inventory block requires start and end dates.');
    }

    final startDate = StayDate.parse(start);
    final endDate = StayDate.parse(end);
    if (!startDate.isBefore(endDate)) {
      throw const FormatException('Inventory block start must precede end date.');
    }

    return InventoryBlock(
      id: id.trim(),
      roomId: roomId.trim(),
      startDate: startDate,
      endDate: endDate,
      kind: kind.trim(),
    );
  }

  final String id;
  final String roomId;
  final StayDate startDate;
  final StayDate endDate;
  final String kind;

  Map<String, dynamic> toJson() => {
    'id': id,
    'roomId': roomId,
    'startDate': startDate.toString(),
    'endDate': endDate.toString(),
    'kind': kind,
  };

  /// Returns true if this block overlaps with the interval `[arrival, departure)`.
  bool overlaps(StayDate arrival, StayDate departure) =>
      startDate.isBefore(departure) && arrival.isBefore(endDate);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryBlock &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          roomId == other.roomId &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          kind == other.kind;

  @override
  int get hashCode => Object.hash(id, roomId, startDate, endDate, kind);
}
