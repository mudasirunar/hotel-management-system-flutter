import '../../domain/services/location_service.dart';

/// Result of requesting foreground device location.
sealed class LocationResult {
  const LocationResult();
}

/// Device location successfully resolved.
final class LocationResultSuccess extends LocationResult {
  const LocationResultSuccess(this.coordinates);
  final GeoCoordinates coordinates;
}

/// User denied location permissions.
final class LocationResultPermissionDenied extends LocationResult {
  const LocationResultPermissionDenied({this.isPermanent = false});
  final bool isPermanent;
}

/// Location services (GPS) are turned off on the device.
final class LocationResultServicesDisabled extends LocationResult {
  const LocationResultServicesDisabled();
}

/// Device location could not be determined due to a timeout or sensor failure.
final class LocationResultError extends LocationResult {
  const LocationResultError(this.message);
  final String message;
}

/// Interface for foreground location providers.
abstract interface class LocationAdapter {
  Future<LocationResult> requestDeviceLocation();
}

/// Adaptable location adapter supporting configurable or simulated device locations.
///
/// Ensures tests, emulators, and local environments operate safely without crashing
/// or requiring heavy external platform packages.
class ConfigurableLocationAdapter implements LocationAdapter {
  ConfigurableLocationAdapter({
    this.initialResult,
  });

  LocationResult? initialResult;

  /// Default mock device location near Blue Area, Islamabad.
  static const GeoCoordinates defaultSampleDeviceCoordinates =
      GeoCoordinates(latitude: 33.7080, longitude: 73.0560);

  @override
  Future<LocationResult> requestDeviceLocation() async {
    return initialResult ??
        const LocationResultSuccess(defaultSampleDeviceCoordinates);
  }
}
