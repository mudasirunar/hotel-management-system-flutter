import 'package:flutter/foundation.dart';

import '../data/location/location_adapter.dart';
import '../domain/models/hotel.dart';
import '../domain/services/location_service.dart';

/// State of foreground location access.
enum LocationAccessState {
  idle,
  requesting,
  granted,
  denied,
  permanentlyDenied,
  servicesDisabled,
  error,
}

/// Application controller managing city selection, optional device location, and distance calculation.
class LocationController extends ChangeNotifier {
  LocationController({
    LocationAdapter? locationAdapter,
    this._locationService = const LocationService(),
    String? defaultCity = 'Karachi',
  })  : _adapter = locationAdapter ?? ConfigurableLocationAdapter() {
    if (defaultCity != null && LocationService.cityCenters.containsKey(defaultCity)) {
      _currentOrigin = UserLocationOrigin.city(
        defaultCity,
        LocationService.cityCenters[defaultCity]!,
      );
    }
  }

  final LocationAdapter _adapter;
  final LocationService _locationService;

  UserLocationOrigin? _currentOrigin;
  LocationAccessState _accessState = LocationAccessState.idle;
  String? _statusFeedback;
  bool _isRequesting = false;

  UserLocationOrigin? get currentOrigin => _currentOrigin;
  LocationAccessState get accessState => _accessState;
  String? get statusFeedback => _statusFeedback;
  bool get isRequesting => _isRequesting;

  bool get hasOrigin => _currentOrigin != null;
  bool get isDeviceLocation => _currentOrigin?.isDevice ?? false;
  bool get isCityOrigin => _currentOrigin?.isCity ?? false;
  String? get originLabel => _currentOrigin?.label;

  /// Selects a catalog city as the reference origin for browsing and distance calculation.
  void selectCity(String cityName) {
    final coordinates = LocationService.cityCenters[cityName];
    if (coordinates == null) return;

    _currentOrigin = UserLocationOrigin.city(cityName, coordinates);
    _accessState = LocationAccessState.idle;
    _statusFeedback = null;
    notifyListeners();
  }

  /// Clears any selected reference origin.
  void clearOrigin() {
    _currentOrigin = null;
    _accessState = LocationAccessState.idle;
    _statusFeedback = null;
    notifyListeners();
  }

  /// Requests foreground device location.
  ///
  /// If granted, updates origin to device coordinates.
  /// If denied or disabled, retains the current city without blocking catalog browsing.
  Future<void> requestDeviceLocation() async {
    if (_isRequesting) return;
    _isRequesting = true;
    _accessState = LocationAccessState.requesting;
    notifyListeners();

    try {
      final result = await _adapter.requestDeviceLocation();
      switch (result) {
        case LocationResultSuccess(:final coordinates):
          _currentOrigin = UserLocationOrigin.device(coordinates);
          _accessState = LocationAccessState.granted;
          _statusFeedback = 'Using your current location';
        case LocationResultPermissionDenied(:final isPermanent):
          _accessState = isPermanent
              ? LocationAccessState.permanentlyDenied
              : LocationAccessState.denied;
          _statusFeedback = isPermanent
              ? 'Location permission permanently denied. Enable in device settings or select a city.'
              : 'Location permission denied. Browsing with selected destination.';
        case LocationResultServicesDisabled():
          _accessState = LocationAccessState.servicesDisabled;
          _statusFeedback = 'Location services are disabled on your device.';
        case LocationResultError(:final message):
          _accessState = LocationAccessState.error;
          _statusFeedback = message.isNotEmpty
              ? message
              : 'Could not determine device location.';
      }
    } catch (e) {
      _accessState = LocationAccessState.error;
      _statusFeedback = 'Failed to fetch location: $e';
    } finally {
      _isRequesting = false;
      notifyListeners();
    }
  }

  /// Distance to a hotel from current origin, or null if no origin selected.
  double? distanceToHotel(Hotel hotel) {
    if (_currentOrigin == null) return null;
    return _locationService.distanceToHotel(_currentOrigin!, hotel);
  }

  /// Formatted distance string (e.g., "1.2 km", "< 1 km") or null if no origin.
  String? formatDistanceToHotel(Hotel hotel) {
    final dist = distanceToHotel(hotel);
    if (dist == null) return null;
    return _locationService.formatDistanceKm(dist);
  }

  /// Formatted origin subtitle for UI cards and headers.
  String getOriginDescription() {
    if (_currentOrigin == null) return 'No location selected';
    if (_currentOrigin!.isDevice) return 'Near your current location (approximate)';
    return 'Near ${_currentOrigin!.label} center';
  }

  /// Sorts hotels by distance from current origin. If no origin, returns unchanged copy.
  List<Hotel> sortHotelsByDistance(List<Hotel> hotels) {
    if (_currentOrigin == null) return List<Hotel>.from(hotels);
    return _locationService.sortHotelsByDistance(hotels, _currentOrigin!);
  }
}
