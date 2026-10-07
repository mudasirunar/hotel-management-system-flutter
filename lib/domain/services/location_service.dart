import 'dart:math';

import '../models/hotel.dart';

/// Geographical coordinates (latitude and longitude).
final class GeoCoordinates {
  const GeoCoordinates({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeoCoordinates &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => '($latitude, $longitude)';
}

enum LocationOriginType { device, city }

/// Origin point used for sorting and displaying nearby hotels.
final class UserLocationOrigin {
  const UserLocationOrigin({
    required this.coordinates,
    required this.type,
    this.label,
  });

  factory UserLocationOrigin.device(GeoCoordinates coordinates) =>
      UserLocationOrigin(
        coordinates: coordinates,
        type: LocationOriginType.device,
        label: 'Your location',
      );

  factory UserLocationOrigin.city(String cityName, GeoCoordinates coordinates) =>
      UserLocationOrigin(
        coordinates: coordinates,
        type: LocationOriginType.city,
        label: cityName,
      );

  final GeoCoordinates coordinates;
  final LocationOriginType type;
  final String? label;

  bool get isDevice => type == LocationOriginType.device;
  bool get isCity => type == LocationOriginType.city;
}

final class LocationService {
  const LocationService();

  /// Documented city center coordinates for the catalog destinations.
  static const Map<String, GeoCoordinates> cityCenters = {
    'Karachi': GeoCoordinates(latitude: 24.8607, longitude: 67.0011),
    'Lahore': GeoCoordinates(latitude: 31.5204, longitude: 74.3587),
    'Islamabad': GeoCoordinates(latitude: 33.6844, longitude: 73.0479),
    'Murree': GeoCoordinates(latitude: 33.9070, longitude: 73.3943),
  };

  /// Calculates straight-line great-circle distance between two coordinates in kilometers (Haversine formula).
  double calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;

    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Calculates distance from an origin to a hotel.
  double distanceToHotel(UserLocationOrigin origin, Hotel hotel) =>
      calculateDistanceKm(
        origin.coordinates.latitude,
        origin.coordinates.longitude,
        hotel.latitude,
        hotel.longitude,
      );

  /// Sorts a list of hotels by distance from the origin ascending,
  /// with a stable tie-breaker (rating desc, name asc).
  List<Hotel> sortHotelsByDistance(List<Hotel> hotels, UserLocationOrigin origin) {
    final list = List<Hotel>.from(hotels);
    list.sort((a, b) {
      final distA = distanceToHotel(origin, a);
      final distB = distanceToHotel(origin, b);
      final distCompare = distA.compareTo(distB);
      if (distCompare != 0) return distCompare;

      final ratingCompare = b.rating.compareTo(a.rating);
      if (ratingCompare != 0) return ratingCompare;

      return a.name.compareTo(b.name);
    });
    return list;
  }

  /// Formats a distance in kilometers into a friendly string (e.g. "1.4 km", "< 1 km", "45 km").
  String formatDistanceKm(double km) {
    if (km < 1.0) {
      return '< 1 km';
    }
    if (km < 10.0) {
      return '${km.toStringAsFixed(1)} km';
    }
    return '${km.round()} km';
  }

  static double _degToRad(double deg) => deg * (pi / 180.0);
}
