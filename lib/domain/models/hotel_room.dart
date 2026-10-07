/// An immutable room within a customer catalog hotel.
final class HotelRoom {
  const HotelRoom({
    required this.id,
    required this.hotelId,
    required this.number,
    required this.type,
    required this.description,
    required this.capacity,
    required this.bedDescription,
    required this.nightlyRateMinor,
    this.currency = 'PKR',
    this.gallery = const [],
    this.amenities = const [],
  });

  factory HotelRoom.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final hotelId = json['hotelId'] as String?;
    final number = json['number'] as String?;
    final type = json['type'] as String?;
    final description = json['description'] as String? ?? '';
    final capacity = json['capacity'] as int? ?? 1;
    final bedDescription = json['bedDescription'] as String? ?? '1 Queen Bed';
    final nightlyRateMinor = json['nightlyRateMinor'] as int?;
    final currency = json['currency'] as String? ?? 'PKR';
    final gallery = (json['gallery'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [];
    final amenities = (json['amenities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [];

    if (id == null || id.trim().isEmpty) {
      throw const FormatException('Room requires an id.');
    }
    if (hotelId == null || hotelId.trim().isEmpty) {
      throw const FormatException('Room requires a hotelId.');
    }
    if (number == null || number.trim().isEmpty) {
      throw const FormatException('Room requires a number.');
    }
    if (type == null || type.trim().isEmpty) {
      throw const FormatException('Room requires a type.');
    }
    if (capacity < 1) {
      throw const FormatException('Room capacity must be at least 1.');
    }
    if (nightlyRateMinor == null || nightlyRateMinor <= 0) {
      throw const FormatException('Room nightly rate must be a positive integer.');
    }

    return HotelRoom(
      id: id.trim(),
      hotelId: hotelId.trim(),
      number: number.trim(),
      type: type.trim(),
      description: description.trim(),
      capacity: capacity,
      bedDescription: bedDescription.trim(),
      nightlyRateMinor: nightlyRateMinor,
      currency: currency.trim(),
      gallery: List.unmodifiable(gallery),
      amenities: List.unmodifiable(amenities),
    );
  }

  final String id;
  final String hotelId;
  final String number;
  final String type;
  final String description;
  final int capacity;
  final String bedDescription;
  final int nightlyRateMinor;
  final String currency;
  final List<String> gallery;
  final List<String> amenities;

  Map<String, dynamic> toJson() => {
    'id': id,
    'hotelId': hotelId,
    'number': number,
    'type': type,
    'description': description,
    'capacity': capacity,
    'bedDescription': bedDescription,
    'nightlyRateMinor': nightlyRateMinor,
    'currency': currency,
    'gallery': gallery,
    'amenities': amenities,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HotelRoom &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          hotelId == other.hotelId;

  @override
  int get hashCode => Object.hash(id, hotelId);
}
