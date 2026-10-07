import 'package:hotel_management_system/domain/models/customer_state.dart';
import 'package:hotel_management_system/domain/models/hotel.dart';
import 'package:hotel_management_system/domain/models/hotel_catalog.dart';
import 'package:hotel_management_system/domain/models/hotel_room.dart';
import 'package:hotel_management_system/domain/repositories/customer_repository.dart';

class FakeCustomerRepository implements CustomerRepository {
  FakeCustomerRepository({
    CustomerState? initialState,
    HotelCatalog? catalog,
  })  : state = initialState ?? CustomerState.initial(),
        catalog = catalog ?? defaultSampleCatalog;

  CustomerState state;
  HotelCatalog catalog;

  static const HotelCatalog defaultSampleCatalog = HotelCatalog(
    catalogVersion: 1,
    hotels: [
      Hotel(
        id: 'h_khi_1',
        name: 'Pearl Continental Karachi',
        description: 'Iconic luxury hotel in central Karachi.',
        city: 'Karachi',
        area: 'Club Road',
        address: 'Club Road, Civil Lines, Karachi',
        latitude: 24.8532,
        longitude: 67.0281,
        rating: 4.6,
        reviewCount: 320,
        gallery: ['https://example.com/pc_khi.jpg'],
        amenities: ['WiFi', 'Pool', 'Breakfast', 'Parking', 'AC'],
        rooms: [
          HotelRoom(
            id: 'r_khi_101',
            hotelId: 'h_khi_1',
            number: '101',
            type: 'Deluxe Room',
            description: 'Spacious deluxe room with city views.',
            capacity: 2,
            bedDescription: '1 King Bed',
            nightlyRateMinor: 1500000, // 15,000 PKR
          ),
        ],
      ),
      Hotel(
        id: 'h_lhr_1',
        name: 'Avari Lahore',
        description: 'Elegance on Mall Road.',
        city: 'Lahore',
        area: 'Mall Road',
        address: '87 Mall Road, Lahore',
        latitude: 31.5546,
        longitude: 74.3318,
        rating: 4.7,
        reviewCount: 280,
        gallery: ['https://example.com/avari_lhr.jpg'],
        amenities: ['WiFi', 'Pool', 'Breakfast', 'Parking', 'Gym'],
        rooms: [
          HotelRoom(
            id: 'r_lhr_201',
            hotelId: 'h_lhr_1',
            number: '201',
            type: 'Executive Suite',
            description: 'Executive suite with lounge access.',
            capacity: 2,
            bedDescription: '1 King Bed',
            nightlyRateMinor: 2200000, // 22,000 PKR
          ),
        ],
      ),
    ],
    inventoryBlocks: [],
  );

  @override
  Future<HotelCatalog> loadCatalog() async => catalog;

  @override
  Future<CustomerState> loadState() async => state;

  @override
  Future<void> saveState(CustomerState newState) async {
    state = newState;
  }

  @override
  Future<void> close() async {}
}
