import 'hotel_room.dart';

/// A customer catalog hotel with location, ratings, amenities, and rooms.
final class Hotel {
  const Hotel({
    required this.id,
    required this.name,
    required this.description,
    required this.city,
    required this.area,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.gallery,
    required this.rating,
    required this.reviewCount,
    required this.amenities,
    this.checkInTime = '14:00',
    this.checkOutTime = '12:00',
    this.cancellationPolicy = 'Free cancellation up to 24 hours before arrival.',
    this.rooms = const [],
  });

  factory Hotel.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final name = json['name'] as String?;
    final description = json['description'] as String? ?? '';
    final city = json['city'] as String?;
    final area = json['area'] as String? ?? '';
    final address = json['address'] as String? ?? '';
    final latitude = (json['latitude'] as num?)?.toDouble() ?? 0.0;
    final longitude = (json['longitude'] as num?)?.toDouble() ?? 0.0;
    final gallery = (json['gallery'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [];
    final rating = (json['rating'] as num?)?.toDouble() ?? 4.0;
    final reviewCount = json['reviewCount'] as int? ?? 0;
    final amenities = (json['amenities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [];
    final checkIn = json['checkInTime'] as String? ?? '14:00';
    final checkOut = json['checkOutTime'] as String? ?? '12:00';
    final policy = json['cancellationPolicy'] as String? ?? 'Free cancellation up to 24 hours before arrival.';

    final rawRooms = json['rooms'] as List<dynamic>? ?? const [];
    final rooms = rawRooms.map((r) => HotelRoom.fromJson(r as Map<String, dynamic>)).toList();

    if (id == null || id.trim().isEmpty) {
      throw const FormatException('Hotel requires an id.');
    }
    if (name == null || name.trim().isEmpty) {
      throw const FormatException('Hotel requires a name.');
    }
    if (city == null || city.trim().isEmpty) {
      throw const FormatException('Hotel requires a city.');
    }
    if (rating < 0 || rating > 5) {
      throw const FormatException('Hotel rating must be between 0.0 and 5.0.');
    }

    return Hotel(
      id: id.trim(),
      name: name.trim(),
      description: description.trim(),
      city: city.trim(),
      area: area.trim(),
      address: address.trim(),
      latitude: latitude,
      longitude: longitude,
      gallery: List.unmodifiable(gallery),
      rating: rating,
      reviewCount: reviewCount < 0 ? 0 : reviewCount,
      amenities: List.unmodifiable(amenities),
      checkInTime: checkIn.trim(),
      checkOutTime: checkOut.trim(),
      cancellationPolicy: policy.trim(),
      rooms: List.unmodifiable(rooms),
    );
  }

  final String id;
  final String name;
  final String description;
  final String city;
  final String area;
  final String address;
  final double latitude;
  final double longitude;
  final List<String> gallery;
  final double rating;
  final int reviewCount;
  final List<String> amenities;
  final String checkInTime;
  final String checkOutTime;
  final String cancellationPolicy;
  final List<HotelRoom> rooms;

  /// Returns the lowest nightly rate among all rooms in this hotel.
  int? get startingNightlyRateMinor {
    if (rooms.isEmpty) return null;
    return rooms.map((r) => r.nightlyRateMinor).reduce((a, b) => a < b ? a : b);
  }

  Hotel copyWith({List<HotelRoom>? rooms}) => Hotel(
    id: id,
    name: name,
    description: description,
    city: city,
    area: area,
    address: address,
    latitude: latitude,
    longitude: longitude,
    gallery: gallery,
    rating: rating,
    reviewCount: reviewCount,
    amenities: amenities,
    checkInTime: checkInTime,
    checkOutTime: checkOutTime,
    cancellationPolicy: cancellationPolicy,
    rooms: rooms ?? this.rooms,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'city': city,
    'area': area,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'gallery': gallery,
    'rating': rating,
    'reviewCount': reviewCount,
    'amenities': amenities,
    'checkInTime': checkInTime,
    'checkOutTime': checkOutTime,
    'cancellationPolicy': cancellationPolicy,
    'rooms': rooms.map((r) => r.toJson()).toList(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Hotel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
