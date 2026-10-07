import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_management_system/domain/models/hotel.dart';
import 'package:hotel_management_system/domain/models/hotel_catalog.dart';
import 'package:hotel_management_system/domain/models/hotel_room.dart';
import 'package:hotel_management_system/domain/models/inventory_block.dart';
import 'package:hotel_management_system/domain/models/stay_date.dart';
import 'package:hotel_management_system/domain/services/hotel_search_service.dart';
import 'package:hotel_management_system/domain/services/location_service.dart';

void main() {
  const searchService = HotelSearchService();

  final anchor = StayDate(2026, 10, 10);
  final departure = StayDate(2026, 10, 12);

  const roomStandard = HotelRoom(
    id: 'r_std',
    hotelId: 'h1',
    number: '101',
    type: 'Standard Room',
    description: 'Cozy standard room',
    capacity: 2,
    bedDescription: '1 Queen Bed',
    nightlyRateMinor: 1000000, // 10,000 PKR
    amenities: ['WiFi', 'Air Conditioning'],
  );

  const roomDeluxe = HotelRoom(
    id: 'r_dlx',
    hotelId: 'h1',
    number: '102',
    type: 'Deluxe Room',
    description: 'Spacious deluxe room',
    capacity: 3,
    bedDescription: '1 King Bed + 1 Single',
    nightlyRateMinor: 1800000, // 18,000 PKR
    amenities: ['WiFi', 'Air Conditioning', 'Swimming Pool'],
  );

  final hotel1 = Hotel(
    id: 'h1',
    name: 'Karachi Pearl Continental',
    description: '5-star luxury in Karachi',
    city: 'Karachi',
    area: 'Club Road',
    address: 'Club Road, Karachi',
    latitude: 24.8530,
    longitude: 67.0280,
    rating: 4.6,
    reviewCount: 210,
    gallery: const ['https://example.com/h1.jpg'],
    amenities: const ['WiFi', 'Swimming Pool', 'Air Conditioning', 'Restaurant'],
    rooms: const [roomStandard, roomDeluxe],
  );

  final hotel2 = Hotel(
    id: 'h2',
    name: 'Lahore Heritage Inn',
    description: 'Boutique stay in Gulberg',
    city: 'Lahore',
    area: 'Gulberg',
    address: 'Gulberg III, Lahore',
    latitude: 31.5100,
    longitude: 74.3400,
    rating: 4.8,
    reviewCount: 95,
    gallery: const ['https://example.com/h2.jpg'],
    amenities: const ['WiFi', 'Breakfast', 'Air Conditioning'],
    rooms: const [
      HotelRoom(
        id: 'r_lh1',
        hotelId: 'h2',
        number: '201',
        type: 'Heritage Suite',
        description: 'Traditional suite',
        capacity: 2,
        bedDescription: '1 King Bed',
        nightlyRateMinor: 2500000, // 25,000 PKR
      ),
    ],
  );

  final catalog = HotelCatalog(
    catalogVersion: 1,
    hotels: [hotel1, hotel2],
    inventoryBlocks: [
      // Block standard room on 2026-10-10 -> 2026-10-11
      InventoryBlock(
        id: 'block_1',
        roomId: 'r_std',
        startDate: StayDate(2026, 10, 10),
        endDate: StayDate(2026, 10, 11),
        kind: 'maintenance',
      ),
    ],
  );

  group('HotelSearchService - calculateLowestEligibleRatePKR', () {
    test('returns lowest available room meeting capacity', () {
      final rate = searchService.calculateLowestEligibleRatePKR(
        hotel: hotel1,
        arrival: StayDate(2026, 10, 15),
        departure: StayDate(2026, 10, 17),
        partySize: 2,
        inventoryBlocks: catalog.inventoryBlocks,
        userBookings: const [],
      );

      // Both rooms available; standard room is 10,000 PKR, deluxe is 18,000 PKR
      expect(rate, 10000);
    });

    test('excludes blocked room and returns next eligible available room', () {
      final rate = searchService.calculateLowestEligibleRatePKR(
        hotel: hotel1,
        arrival: anchor, // overlaps with r_std block
        departure: departure,
        partySize: 2,
        inventoryBlocks: catalog.inventoryBlocks,
        userBookings: const [],
      );

      // r_std is blocked; r_dlx (18,000 PKR) is eligible and available
      expect(rate, 18000);
    });

    test('excludes rooms that cannot fit party size', () {
      final rate = searchService.calculateLowestEligibleRatePKR(
        hotel: hotel1,
        arrival: StayDate(2026, 10, 15),
        departure: StayDate(2026, 10, 17),
        partySize: 3, // r_std has capacity 2, r_dlx has capacity 3
        inventoryBlocks: catalog.inventoryBlocks,
        userBookings: const [],
      );

      expect(rate, 18000);
    });

    test('returns null if all rooms are unavailable or under-capacity', () {
      final rate = searchService.calculateLowestEligibleRatePKR(
        hotel: hotel1,
        arrival: StayDate(2026, 10, 15),
        departure: StayDate(2026, 10, 17),
        partySize: 5, // exceeds all rooms capacity
        inventoryBlocks: catalog.inventoryBlocks,
        userBookings: const [],
      );

      expect(rate, isNull);
    });
  });

  group('HotelSearchService - searchHotels filters and sorting', () {
    test('filters by city correctly', () {
      final criteria = HotelFilterCriteria(
        city: 'Lahore',
        arrival: anchor,
        departure: departure,
      );

      final results = searchService.searchHotels(
        catalog: catalog,
        userBookings: const [],
        criteria: criteria,
      );

      expect(results.length, 1);
      expect(results.first.hotel.id, 'h2');
    });

    test('searches by query matching area or name', () {
      final criteria = HotelFilterCriteria(
        query: 'Gulberg',
        arrival: anchor,
        departure: departure,
      );

      final results = searchService.searchHotels(
        catalog: catalog,
        userBookings: const [],
        criteria: criteria,
      );

      expect(results.length, 1);
      expect(results.first.hotel.id, 'h2');
    });

    test('filters by max budget PKR', () {
      final criteria = HotelFilterCriteria(
        maxNightlyPricePKR: 20000,
        arrival: anchor,
        departure: departure,
      );

      final results = searchService.searchHotels(
        catalog: catalog,
        userBookings: const [],
        criteria: criteria,
      );

      // h1 lowest available is 18,000 PKR; h2 is 25,000 PKR
      expect(results.length, 1);
      expect(results.first.hotel.id, 'h1');
    });

    test('sorts by price low to high', () {
      final criteria = HotelFilterCriteria(
        arrival: StayDate(2026, 10, 15),
        departure: StayDate(2026, 10, 16),
        sortOption: HotelSortOption.priceLowToHigh,
      );

      final results = searchService.searchHotels(
        catalog: catalog,
        userBookings: const [],
        criteria: criteria,
      );

      // h1 is 10,000 PKR, h2 is 25,000 PKR
      expect(results.first.hotel.id, 'h1');
      expect(results.last.hotel.id, 'h2');
    });

    test('sorts by nearest when origin provided', () {
      final criteria = HotelFilterCriteria(
        arrival: anchor,
        departure: departure,
        sortOption: HotelSortOption.nearest,
      );

      final khiOrigin = UserLocationOrigin.city(
        'Karachi',
        LocationService.cityCenters['Karachi']!,
      );

      final results = searchService.searchHotels(
        catalog: catalog,
        userBookings: const [],
        criteria: criteria,
        origin: khiOrigin,
      );

      expect(results.first.hotel.city, 'Karachi');
    });
  });
}
