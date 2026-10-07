import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_management_system/application/customer_controller.dart';
import 'package:hotel_management_system/domain/hotel_exception.dart';
import 'package:hotel_management_system/domain/models/customer_state.dart';
import 'package:hotel_management_system/domain/models/hotel.dart';
import 'package:hotel_management_system/domain/models/hotel_catalog.dart';
import 'package:hotel_management_system/domain/models/hotel_room.dart';
import 'package:hotel_management_system/domain/models/inventory_block.dart';
import 'package:hotel_management_system/domain/models/stay_date.dart';
import 'package:hotel_management_system/domain/repositories/customer_repository.dart';

void main() {
  group('CustomerController', () {
    late _FakeCustomerRepository repository;
    late CustomerController controller;

    final testRoom = HotelRoom(
      id: 'r_101',
      hotelId: 'h_1',
      number: '101',
      type: 'Deluxe King',
      description: 'Room',
      capacity: 2,
      bedDescription: '1 King',
      nightlyRateMinor: 15000,
    );

    final testHotel = Hotel(
      id: 'h_1',
      name: 'Luxury Pearl',
      description: 'Grand resort',
      city: 'Karachi',
      area: 'Clifton',
      address: 'Sea View',
      latitude: 24.8,
      longitude: 67.0,
      gallery: const [],
      rating: 4.8,
      reviewCount: 50,
      amenities: const ['WiFi'],
      rooms: [testRoom],
    );

    setUp(() {
      repository = _FakeCustomerRepository(
        catalog: HotelCatalog(
          hotels: [testHotel],
          inventoryBlocks: [
            InventoryBlock(
              id: 'b_1',
              roomId: 'r_101',
              startDate: StayDate(2026, 10, 5),
              endDate: StayDate(2026, 10, 8),
              kind: 'occupied',
            ),
          ],
        ),
      );
      controller = CustomerController(repository: repository);
    });

    tearDown(() async {
      await controller.close();
      controller.dispose();
    });

    test('initializes cleanly and loads catalog and state', () async {
      expect(controller.status, CustomerLoadStatus.initial);
      await controller.load();
      expect(controller.status, CustomerLoadStatus.ready);
      expect(controller.catalog.hotels.length, 1);
      expect(controller.state.isInitialized, isTrue);
    });

    test('creates booking and saves to repository', () async {
      await controller.load();

      final booking = await controller.createBooking(
        hotel: testHotel,
        room: testRoom,
        arrival: StayDate(2026, 10, 10),
        departure: StayDate(2026, 10, 12),
        partySize: 2,
        travelerName: 'Hamza Khan',
        travelerPhone: '03001234567',
      );

      expect(booking.id, startsWith('BK-'));
      expect(booking.totalAmountMinor, 30000); // 2 nights * 15000
      expect(controller.state.bookings.length, 1);
      expect(repository.savedState?.bookings.length, 1);
    });

    test('rejects booking that conflicts with inventory block', () async {
      await controller.load();

      expect(
        () => controller.createBooking(
          hotel: testHotel,
          room: testRoom,
          arrival: StayDate(2026, 10, 6),
          departure: StayDate(2026, 10, 7),
          partySize: 1,
          travelerName: 'Test',
          travelerPhone: '0300',
        ),
        throwsA(isA<HotelException>().having(
          (e) => e.code,
          'code',
          HotelErrorCode.bookingConflict,
        )),
      );
    });

    test('cancels booking and releases availability block', () async {
      await controller.load();

      final booking = await controller.createBooking(
        hotel: testHotel,
        room: testRoom,
        arrival: StayDate(2026, 10, 10),
        departure: StayDate(2026, 10, 12),
        partySize: 1,
        travelerName: 'Test',
        travelerPhone: '0300',
      );

      // Now booking for the same dates should fail due to conflict with existing booking
      expect(
        () => controller.createBooking(
          hotel: testHotel,
          room: testRoom,
          arrival: StayDate(2026, 10, 10),
          departure: StayDate(2026, 10, 12),
          partySize: 1,
          travelerName: 'Second Person',
          travelerPhone: '0301',
        ),
        throwsA(isA<HotelException>().having(
          (e) => e.code,
          'code',
          HotelErrorCode.bookingConflict,
        )),
      );

      // Cancel the first booking
      await controller.cancelBooking(booking.id);
      expect(controller.state.bookings.first.isCancelled, isTrue);

      // Now the room is available again for those dates
      final newBooking = await controller.createBooking(
        hotel: testHotel,
        room: testRoom,
        arrival: StayDate(2026, 10, 10),
        departure: StayDate(2026, 10, 12),
        partySize: 1,
        travelerName: 'Second Person',
        travelerPhone: '0301',
      );
      expect(newBooking.id, isNotNull);
    });

    test('toggles saved hotel in favorites', () async {
      await controller.load();

      expect(controller.state.isHotelSaved('h_1'), isFalse);
      await controller.toggleSavedHotel('h_1');
      expect(controller.state.isHotelSaved('h_1'), isTrue);
      expect(repository.savedState?.isHotelSaved('h_1'), isTrue);

      await controller.toggleSavedHotel('h_1');
      expect(controller.state.isHotelSaved('h_1'), isFalse);
    });

    test('updates traveler profile', () async {
      await controller.load();

      await controller.updateProfile(
        name: 'Zainab Noor',
        phone: '03219876543',
        email: 'zainab@example.com',
      );

      expect(controller.state.profile?.name, 'Zainab Noor');
      expect(controller.state.profile?.phone, '03219876543');
      expect(controller.state.profile?.email, 'zainab@example.com');
      expect(repository.savedState?.profile?.name, 'Zainab Noor');
    });
  });
}

class _FakeCustomerRepository implements CustomerRepository {
  _FakeCustomerRepository({required this.catalog});

  final HotelCatalog catalog;
  CustomerState? savedState;
  bool closed = false;

  @override
  Future<HotelCatalog> loadCatalog() async => catalog;

  @override
  Future<CustomerState> loadState() async {
    savedState ??= CustomerState.initial().copyWith(isInitialized: true);
    return savedState!;
  }

  @override
  Future<void> saveState(CustomerState state) async {
    savedState = state;
  }

  @override
  Future<void> close() async {
    closed = true;
  }
}
