import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_management_system/domain/models/hotel.dart';
import 'package:hotel_management_system/domain/models/hotel_room.dart';
import 'package:hotel_management_system/domain/services/location_service.dart';

void main() {
  const service = LocationService();

  group('LocationService - Haversine calculations', () {
    test('calculates 0 distance for identical coordinates', () {
      final dist = service.calculateDistanceKm(24.8607, 67.0011, 24.8607, 67.0011);
      expect(dist, closeTo(0.0, 0.001));
    });

    test('calculates accurate distance between Islamabad and Murree (~37 km)', () {
      final isb = LocationService.cityCenters['Islamabad']!;
      final murree = LocationService.cityCenters['Murree']!;

      final dist = service.calculateDistanceKm(
        isb.latitude,
        isb.longitude,
        murree.latitude,
        murree.longitude,
      );

      // Straight-line distance between Islamabad center and Murree center is ~39 km
      expect(dist, inInclusiveRange(35.0, 45.0));
    });

    test('calculates accurate distance between Karachi and Lahore (~1025-1035 km)', () {
      final khi = LocationService.cityCenters['Karachi']!;
      final lhr = LocationService.cityCenters['Lahore']!;

      final dist = service.calculateDistanceKm(
        khi.latitude,
        khi.longitude,
        lhr.latitude,
        lhr.longitude,
      );

      expect(dist, inInclusiveRange(1000.0, 1050.0));
    });
  });

  group('LocationService - Formatting', () {
    test('formats sub-kilometer distance as < 1 km', () {
      expect(service.formatDistanceKm(0.4), '< 1 km');
      expect(service.formatDistanceKm(0.95), '< 1 km');
    });

    test('formats single-decimal kilometer distance under 10 km', () {
      expect(service.formatDistanceKm(1.42), '1.4 km');
      expect(service.formatDistanceKm(8.79), '8.8 km');
    });

    test('formats rounded whole kilometer distance for 10 km and above', () {
      expect(service.formatDistanceKm(12.3), '12 km');
      expect(service.formatDistanceKm(1045.8), '1046 km');
    });
  });

  group('LocationService - Hotel distance and sorting', () {
    const sampleRooms = [
      HotelRoom(
        id: 'r1',
        hotelId: 'h1',
        number: '101',
        type: 'Deluxe King',
        description: 'Spacious deluxe room',
        capacity: 2,
        bedDescription: '1 King Bed',
        nightlyRateMinor: 1500000,
      ),
    ];

    const hotelFar = Hotel(
      id: 'h_far',
      name: 'Far Retreat',
      description: 'Mountain retreat',
      city: 'Islamabad',
      area: 'Margalla Foothills',
      address: 'Near Margalla Hills',
      latitude: 33.7800,
      longitude: 73.1000,
      rating: 4.8,
      reviewCount: 100,
      gallery: ['https://example.com/far.jpg'],
      amenities: ['WiFi', 'Parking'],
      rooms: sampleRooms,
    );

    const hotelNear = Hotel(
      id: 'h_near',
      name: 'Central Inn',
      description: 'Business hotel',
      city: 'Islamabad',
      area: 'Blue Area',
      address: 'Blue Area',
      latitude: 33.6900,
      longitude: 73.0500,
      rating: 4.5,
      reviewCount: 90,
      gallery: ['https://example.com/near.jpg'],
      amenities: ['WiFi'],
      rooms: sampleRooms,
    );

    const hotelNearTie = Hotel(
      id: 'h_near_tie',
      name: 'A-Grade Suites',
      description: 'Premium suites',
      city: 'Islamabad',
      area: 'Blue Area',
      address: 'Blue Area West',
      latitude: 33.6900,
      longitude: 73.0500,
      rating: 4.5,
      reviewCount: 50,
      gallery: ['https://example.com/tie.jpg'],
      amenities: ['WiFi'],
      rooms: sampleRooms,
    );

    test('calculates distance to hotel from city origin', () {
      final origin = UserLocationOrigin.city(
        'Islamabad',
        LocationService.cityCenters['Islamabad']!,
      );
      final dist = service.distanceToHotel(origin, hotelNear);
      expect(dist, inInclusiveRange(0.1, 5.0));
    });

    test('sorts hotels by distance ascending with rating and name tie-breakers', () {
      final origin = UserLocationOrigin.city(
        'Islamabad',
        LocationService.cityCenters['Islamabad']!,
      );

      final sorted = service.sortHotelsByDistance(
        [hotelFar, hotelNear, hotelNearTie],
        origin,
      );

      // Both hotelNear and hotelNearTie have the same distance and rating (4.5),
      // so name tie breaker applies: 'A-Grade Suites' before 'Central Inn'
      expect(sorted[0].id, 'h_near_tie');
      expect(sorted[1].id, 'h_near');
      expect(sorted[2].id, 'h_far');
    });
  });
}
