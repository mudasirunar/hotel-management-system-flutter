import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_management_system/application/location_controller.dart';
import 'package:hotel_management_system/data/location/location_adapter.dart';
import 'package:hotel_management_system/domain/models/hotel.dart';
import 'package:hotel_management_system/domain/models/hotel_room.dart';
import 'package:hotel_management_system/domain/services/location_service.dart';

void main() {
  group('LocationController', () {
    test('initializes with default city (Karachi) origin', () {
      final controller = LocationController();
      expect(controller.hasOrigin, isTrue);
      expect(controller.isCityOrigin, isTrue);
      expect(controller.isDeviceLocation, isFalse);
      expect(controller.originLabel, 'Karachi');
      expect(controller.getOriginDescription(), 'Near Karachi center');
    });

    test('selectCity changes reference city and updates origin', () {
      final controller = LocationController();
      controller.selectCity('Lahore');

      expect(controller.originLabel, 'Lahore');
      expect(controller.currentOrigin?.coordinates, LocationService.cityCenters['Lahore']);
      expect(controller.getOriginDescription(), 'Near Lahore center');
    });

    test('clearOrigin removes origin and descriptions reflect empty state', () {
      final controller = LocationController();
      controller.clearOrigin();

      expect(controller.hasOrigin, isFalse);
      expect(controller.currentOrigin, isNull);
      expect(controller.getOriginDescription(), 'No location selected');
    });

    test('requestDeviceLocation success updates to device origin', () async {
      const mockCoords = GeoCoordinates(latitude: 33.7200, longitude: 73.0600);
      final adapter = ConfigurableLocationAdapter(
        initialResult: const LocationResultSuccess(mockCoords),
      );
      final controller = LocationController(locationAdapter: adapter);

      await controller.requestDeviceLocation();

      expect(controller.accessState, LocationAccessState.granted);
      expect(controller.isDeviceLocation, isTrue);
      expect(controller.currentOrigin?.coordinates, mockCoords);
      expect(controller.getOriginDescription(), 'Near your current location (approximate)');
    });

    test('requestDeviceLocation permission denied retains existing city', () async {
      final adapter = ConfigurableLocationAdapter(
        initialResult: const LocationResultPermissionDenied(isPermanent: false),
      );
      final controller = LocationController(
        locationAdapter: adapter,
        defaultCity: 'Islamabad',
      );

      await controller.requestDeviceLocation();

      expect(controller.accessState, LocationAccessState.denied);
      expect(controller.isDeviceLocation, isFalse);
      expect(controller.isCityOrigin, isTrue);
      expect(controller.originLabel, 'Islamabad');
      expect(controller.statusFeedback?.toLowerCase(), contains('browsing with selected destination'));
    });

    test('requestDeviceLocation permanent denial explains settings path', () async {
      final adapter = ConfigurableLocationAdapter(
        initialResult: const LocationResultPermissionDenied(isPermanent: true),
      );
      final controller = LocationController(locationAdapter: adapter);

      await controller.requestDeviceLocation();

      expect(controller.accessState, LocationAccessState.permanentlyDenied);
      expect(controller.statusFeedback, contains('device settings'));
    });

    test('requestDeviceLocation services disabled updates state without throwing', () async {
      final adapter = ConfigurableLocationAdapter(
        initialResult: const LocationResultServicesDisabled(),
      );
      final controller = LocationController(locationAdapter: adapter);

      await controller.requestDeviceLocation();

      expect(controller.accessState, LocationAccessState.servicesDisabled);
      expect(controller.statusFeedback, contains('Location services are disabled'));
    });

    test('formats distance and sorts hotels when origin is active', () {
      final controller = LocationController(defaultCity: 'Lahore');
      final hotel = Hotel(
        id: 'h_gulberg',
        name: 'Gulberg Grand',
        description: 'Luxury hotel in Gulberg',
        city: 'Lahore',
        area: 'Gulberg III',
        address: 'Main Boulevard, Gulberg',
        latitude: 31.5204,
        longitude: 74.3587,
        rating: 4.6,
        reviewCount: 88,
        gallery: const ['https://example.com/gulberg.jpg'],
        amenities: const ['WiFi', 'Pool'],
        rooms: const [
          HotelRoom(
            id: 'r_g1',
            hotelId: 'h_gulberg',
            number: '101',
            type: 'Executive Suite',
            description: 'Spacious executive room',
            capacity: 2,
            bedDescription: '1 King Bed',
            nightlyRateMinor: 2000000,
          ),
        ],
      );

      final distance = controller.distanceToHotel(hotel);
      expect(distance, isNotNull);
      expect(distance!, closeTo(0.0, 0.01));

      final formatted = controller.formatDistanceToHotel(hotel);
      expect(formatted, '< 1 km');
    });
  });
}
