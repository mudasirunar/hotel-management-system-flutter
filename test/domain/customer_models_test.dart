import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_management_system/data/local/customer_snapshot_codec.dart';
import 'package:hotel_management_system/domain/hotel_exception.dart';
import 'package:hotel_management_system/domain/models/customer_booking.dart';
import 'package:hotel_management_system/domain/models/customer_state.dart';
import 'package:hotel_management_system/domain/models/hotel.dart';
import 'package:hotel_management_system/domain/models/hotel_catalog.dart';
import 'package:hotel_management_system/domain/models/hotel_room.dart';
import 'package:hotel_management_system/domain/models/inventory_block.dart';
import 'package:hotel_management_system/domain/models/stay_date.dart';
import 'package:hotel_management_system/domain/models/traveler_profile.dart';
import 'package:hotel_management_system/domain/services/customer_availability_service.dart';

void main() {
  group('Customer Domain Models & Validation', () {
    test('InventoryBlock overlaps correctly with intervals', () {
      final block = InventoryBlock(
        id: 'b1',
        roomId: 'r1',
        startDate: StayDate(2026, 10, 10),
        endDate: StayDate(2026, 10, 14),
        kind: 'occupied',
      );

      // Overlaps
      expect(block.overlaps(StayDate(2026, 10, 9), StayDate(2026, 10, 11)), isTrue);
      expect(block.overlaps(StayDate(2026, 10, 11), StayDate(2026, 10, 13)), isTrue);
      expect(block.overlaps(StayDate(2026, 10, 13), StayDate(2026, 10, 15)), isTrue);
      expect(block.overlaps(StayDate(2026, 10, 8), StayDate(2026, 10, 16)), isTrue);

      // Adjacent (checkout day is next arrival day) - NO overlap
      expect(block.overlaps(StayDate(2026, 10, 6), StayDate(2026, 10, 10)), isFalse);
      expect(block.overlaps(StayDate(2026, 10, 14), StayDate(2026, 10, 18)), isFalse);
    });

    test('Hotel and HotelRoom parse correctly and validate fields', () {
      final room = HotelRoom(
        id: 'r_101',
        hotelId: 'h_khi_1',
        number: '101',
        type: 'Deluxe King',
        description: 'A cozy room',
        capacity: 2,
        bedDescription: '1 King Bed',
        nightlyRateMinor: 15000,
        currency: 'PKR',
      );

      final hotel = Hotel(
        id: 'h_khi_1',
        name: 'Pearl Karachi',
        description: 'Luxury hotel',
        city: 'Karachi',
        area: 'Clifton',
        address: 'Marine Drive',
        latitude: 24.8,
        longitude: 67.0,
        gallery: const ['https://example.com/photo.jpg'],
        rating: 4.8,
        reviewCount: 150,
        amenities: const ['WiFi', 'Pool'],
        rooms: [room],
      );

      expect(hotel.startingNightlyRateMinor, 15000);
      final json = hotel.toJson();
      final roundtrip = Hotel.fromJson(json);
      expect(roundtrip.id, 'h_khi_1');
      expect(roundtrip.rooms.first.number, '101');
    });

    test('TravelerProfile serializes and updates', () {
      const profile = TravelerProfile(
        id: 'user_1',
        name: 'Ahmed Khan',
        phone: '03001234567',
        email: 'ahmed@test.com',
      );

      final updated = profile.copyWith(name: 'Ahmed Ali');
      expect(updated.name, 'Ahmed Ali');
      expect(updated.phone, '03001234567');
      expect(TravelerProfile.fromJson(updated.toJson()).name, 'Ahmed Ali');
    });

    test('CustomerBooking cancellation and overlaps', () {
      final booking = CustomerBooking(
        id: 'BK-1001',
        ownerId: 'u1',
        hotelId: 'h1',
        roomId: 'r1',
        arrivalDate: StayDate(2026, 10, 20),
        departureDate: StayDate(2026, 10, 23),
        partySize: 2,
        travelerName: 'Sarah',
        travelerPhone: '03123456789',
        hotelName: 'Serena',
        hotelAddress: 'Islamabad',
        roomType: 'Deluxe',
        roomNumber: '201',
        nightlyRateMinor: 25000,
        totalAmountMinor: 75000,
        cancellationPolicy: 'Free cancellation',
        createdAt: DateTime(2026, 10, 1),
      );

      expect(booking.nights, 3);
      expect(booking.isActive, isTrue);
      expect(booking.overlaps(StayDate(2026, 10, 21), StayDate(2026, 10, 22)), isTrue);
      expect(booking.overlaps(StayDate(2026, 10, 23), StayDate(2026, 10, 25)), isFalse);

      final cancelled = booking.cancel(at: DateTime(2026, 10, 5));
      expect(cancelled.isCancelled, isTrue);
      expect(cancelled.isActive, isFalse);
      // Cancelled booking no longer blocks availability
      expect(cancelled.overlaps(StayDate(2026, 10, 21), StayDate(2026, 10, 22)), isFalse);
    });

    test('CustomerSnapshotCodec round-trips CustomerState', () {
      const codec = CustomerSnapshotCodec();
      final state = CustomerState(
        anchorDate: StayDate(2026, 10, 1),
        isInitialized: true,
        savedHotelIds: const {'hotel_1', 'hotel_2'},
        selectedCity: 'Lahore',
      );

      final encoded = codec.encode(state);
      final decoded = codec.decode(encoded);

      expect(decoded.isInitialized, isTrue);
      expect(decoded.savedHotelIds, contains('hotel_1'));
      expect(decoded.selectedCity, 'Lahore');
      expect(decoded.anchorDate, StayDate(2026, 10, 1));
    });

    test('CustomerSnapshotCodec rejects corrupt string', () {
      const codec = CustomerSnapshotCodec();
      expect(
        () => codec.decode('NOT_JSON'),
        throwsA(isA<HotelException>().having(
          (e) => e.code,
          'code',
          HotelErrorCode.corruptStorage,
        )),
      );
    });
  });

  group('Catalog Manifest Verification', () {
    test('assets/data/hotel_catalog.json is valid and contains 12 hotels', () {
      final file = File('assets/data/hotel_catalog.json');
      expect(file.existsSync(), isTrue);

      final jsonContent = file.readAsStringSync();
      final jsonMap = jsonDecode(jsonContent) as Map<String, dynamic>;
      final catalog = HotelCatalog.fromJson(jsonMap);

      expect(catalog.hotels.length, 12);
      expect(catalog.inventoryBlocks.length, greaterThanOrEqualTo(5));

      final cities = catalog.hotels.map((h) => h.city).toSet();
      expect(cities, containsAll(['Karachi', 'Lahore', 'Islamabad', 'Murree']));

      for (final hotel in catalog.hotels) {
        expect(hotel.rooms.length, greaterThanOrEqualTo(2));
        expect(hotel.startingNightlyRateMinor, isNotNull);
        expect(hotel.startingNightlyRateMinor!, greaterThan(0));
      }
    });
  });

  group('CustomerAvailabilityService', () {
    const service = CustomerAvailabilityService();

    final room = HotelRoom(
      id: 'room_1',
      hotelId: 'hotel_1',
      number: '101',
      type: 'Executive',
      description: 'Room',
      capacity: 2,
      bedDescription: '1 King',
      nightlyRateMinor: 20000,
    );

    final catalog = HotelCatalog(
      hotels: [
        Hotel(
          id: 'hotel_1',
          name: 'Hotel 1',
          description: '',
          city: 'Karachi',
          area: '',
          address: '',
          latitude: 0,
          longitude: 0,
          gallery: const [],
          rating: 4.5,
          reviewCount: 10,
          amenities: const [],
          rooms: [room],
        ),
      ],
      inventoryBlocks: [
        InventoryBlock(
          id: 'b1',
          roomId: 'room_1',
          startDate: StayDate(2026, 10, 12),
          endDate: StayDate(2026, 10, 15),
          kind: 'occupied',
        ),
      ],
    );

    test('detects occupied status when dates overlap with inventory block', () {
      final status = service.checkRoomStatus(
        room: room,
        arrival: StayDate(2026, 10, 13),
        departure: StayDate(2026, 10, 14),
        inventoryBlocks: catalog.inventoryBlocks,
        userBookings: const [],
      );
      expect(status, RoomAvailabilityStatus.occupied);
    });

    test('allows booking on non-overlapping interval', () {
      final status = service.checkRoomStatus(
        room: room,
        arrival: StayDate(2026, 10, 16),
        departure: StayDate(2026, 10, 18),
        inventoryBlocks: catalog.inventoryBlocks,
        userBookings: const [],
      );
      expect(status, RoomAvailabilityStatus.available);
    });

    test('rejects party size exceeding room capacity', () {
      final error = service.validateBookingEligibility(
        room: room,
        arrival: StayDate(2026, 10, 16),
        departure: StayDate(2026, 10, 18),
        partySize: 3, // Room sleeps 2
        earliestAllowedArrival: StayDate(2026, 10, 1),
        catalog: catalog,
        userBookings: const [],
      );
      expect(error, contains('accommodates up to 2 guests'));
    });

    test('calculates stay price accurately', () {
      final total = service.calculateTotalAmount(
        room: room,
        arrival: StayDate(2026, 10, 16),
        departure: StayDate(2026, 10, 19), // 3 nights
      );
      expect(total, 60000); // 3 * 20000
    });
  });
}
