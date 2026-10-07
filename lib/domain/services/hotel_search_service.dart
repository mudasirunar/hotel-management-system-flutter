import '../models/customer_booking.dart';
import '../models/hotel.dart';
import '../models/hotel_catalog.dart';
import '../models/inventory_block.dart';
import '../models/stay_date.dart';
import 'customer_availability_service.dart';
import 'location_service.dart';

enum HotelSortOption {
  recommended,
  priceLowToHigh,
  priceHighToLow,
  ratingHighToLow,
  nearest,
}

/// Filter criteria for hotel discovery.
final class HotelFilterCriteria {
  const HotelFilterCriteria({
    this.query = '',
    this.city,
    required this.arrival,
    required this.departure,
    this.partySize = 1,
    this.maxNightlyPricePKR,
    this.minRating,
    this.requiredAmenities = const {},
    this.onlyAvailableRooms = false,
    this.sortOption = HotelSortOption.recommended,
  });

  final String query;
  final String? city;
  final StayDate arrival;
  final StayDate departure;
  final int partySize;
  final int? maxNightlyPricePKR;
  final double? minRating;
  final Set<String> requiredAmenities;
  final bool onlyAvailableRooms;
  final HotelSortOption sortOption;

  HotelFilterCriteria copyWith({
    String? query,
    String? city,
    bool clearCity = false,
    StayDate? arrival,
    StayDate? departure,
    int? partySize,
    int? maxNightlyPricePKR,
    bool clearMaxPrice = false,
    double? minRating,
    bool clearMinRating = false,
    Set<String>? requiredAmenities,
    bool? onlyAvailableRooms,
    HotelSortOption? sortOption,
  }) =>
      HotelFilterCriteria(
        query: query ?? this.query,
        city: clearCity ? null : (city ?? this.city),
        arrival: arrival ?? this.arrival,
        departure: departure ?? this.departure,
        partySize: partySize ?? this.partySize,
        maxNightlyPricePKR:
            clearMaxPrice ? null : (maxNightlyPricePKR ?? this.maxNightlyPricePKR),
        minRating: clearMinRating ? null : (minRating ?? this.minRating),
        requiredAmenities: requiredAmenities ?? this.requiredAmenities,
        onlyAvailableRooms: onlyAvailableRooms ?? this.onlyAvailableRooms,
        sortOption: sortOption ?? this.sortOption,
      );

  bool get hasActiveFilters =>
      (city != null && city!.isNotEmpty && city != 'All Cities') ||
      query.trim().isNotEmpty ||
      maxNightlyPricePKR != null ||
      (minRating != null && minRating! > 0) ||
      requiredAmenities.isNotEmpty ||
      onlyAvailableRooms;
}

/// Decorated hotel search result with eligibility and distance calculations.
final class HotelSearchResult {
  const HotelSearchResult({
    required this.hotel,
    this.lowestNightlyRatePKR,
    this.distanceKm,
  });

  final Hotel hotel;
  final int? lowestNightlyRatePKR;
  final double? distanceKm;

  bool get hasAvailableRooms => lowestNightlyRatePKR != null;
}

/// Service providing multi-hotel discovery search, filtering, and sorting.
class HotelSearchService {
  const HotelSearchService({
    this.availabilityService = const CustomerAvailabilityService(),
    this.locationService = const LocationService(),
  });

  final CustomerAvailabilityService availabilityService;
  final LocationService locationService;

  /// Calculates the lowest eligible room rate in PKR for the selected dates and party size.
  ///
  /// Returns null if no room meets the capacity and availability requirements.
  int? calculateLowestEligibleRatePKR({
    required Hotel hotel,
    required StayDate arrival,
    required StayDate departure,
    required int partySize,
    required List<InventoryBlock> inventoryBlocks,
    required List<CustomerBooking> userBookings,
  }) {
    int? minRatePKR;

    for (final room in hotel.rooms) {
      if (room.capacity < partySize) continue;

      final status = availabilityService.checkRoomStatus(
        room: room,
        arrival: arrival,
        departure: departure,
        inventoryBlocks: inventoryBlocks,
        userBookings: userBookings,
      );

      if (status == RoomAvailabilityStatus.available) {
        final ratePKR = (room.nightlyRateMinor / 100).round();
        if (minRatePKR == null || ratePKR < minRatePKR) {
          minRatePKR = ratePKR;
        }
      }
    }

    return minRatePKR;
  }

  /// Searches and filters catalog hotels according to [criteria].
  List<HotelSearchResult> searchHotels({
    required HotelCatalog catalog,
    required List<CustomerBooking> userBookings,
    required HotelFilterCriteria criteria,
    UserLocationOrigin? origin,
  }) {
    final cleanQuery = criteria.query.trim().toLowerCase();
    final cleanCity = criteria.city?.trim().toLowerCase();
    final isCityFilterActive = cleanCity != null &&
        cleanCity.isNotEmpty &&
        cleanCity != 'all' &&
        cleanCity != 'all cities';

    final results = <HotelSearchResult>[];

    for (final hotel in catalog.hotels) {
      // 1. City filter
      if (isCityFilterActive && hotel.city.toLowerCase() != cleanCity) {
        continue;
      }

      // 2. Query search across name, city, area, address
      if (cleanQuery.isNotEmpty) {
        final matchesName = hotel.name.toLowerCase().contains(cleanQuery);
        final matchesCity = hotel.city.toLowerCase().contains(cleanQuery);
        final matchesArea = hotel.area.toLowerCase().contains(cleanQuery);
        final matchesAddress = hotel.address.toLowerCase().contains(cleanQuery);
        if (!matchesName && !matchesCity && !matchesArea && !matchesAddress) {
          continue;
        }
      }

      // 3. Minimum rating filter
      if (criteria.minRating != null && hotel.rating < criteria.minRating!) {
        continue;
      }

      // 4. Required amenities filter
      if (criteria.requiredAmenities.isNotEmpty) {
        final hotelAmenitiesLower =
            hotel.amenities.map((a) => a.toLowerCase()).toSet();
        final hasAll = criteria.requiredAmenities.every(
          (req) => hotelAmenitiesLower.contains(req.toLowerCase()),
        );
        if (!hasAll) continue;
      }

      // 5. Calculate lowest eligible room rate for dates and party size
      final lowestRate = calculateLowestEligibleRatePKR(
        hotel: hotel,
        arrival: criteria.arrival,
        departure: criteria.departure,
        partySize: criteria.partySize,
        inventoryBlocks: catalog.inventoryBlocks,
        userBookings: userBookings,
      );

      // 6. Only available rooms filter
      if (criteria.onlyAvailableRooms && lowestRate == null) {
        continue;
      }

      // 7. Max budget filter (only applies if hotel has a price)
      if (criteria.maxNightlyPricePKR != null &&
          lowestRate != null &&
          lowestRate > criteria.maxNightlyPricePKR!) {
        continue;
      }

      // 8. Distance calculation if origin is provided
      final distance = origin != null
          ? locationService.distanceToHotel(origin, hotel)
          : null;

      results.add(
        HotelSearchResult(
          hotel: hotel,
          lowestNightlyRatePKR: lowestRate,
          distanceKm: distance,
        ),
      );
    }

    _sortResults(results, criteria.sortOption);
    return results;
  }

  void _sortResults(List<HotelSearchResult> results, HotelSortOption sort) {
    results.sort((a, b) {
      switch (sort) {
        case HotelSortOption.recommended:
          final ratingCmp = b.hotel.rating.compareTo(a.hotel.rating);
          if (ratingCmp != 0) return ratingCmp;
          final reviewsCmp = b.hotel.reviewCount.compareTo(a.hotel.reviewCount);
          if (reviewsCmp != 0) return reviewsCmp;
          return a.hotel.name.compareTo(b.hotel.name);

        case HotelSortOption.priceLowToHigh:
          if (a.lowestNightlyRatePKR == null && b.lowestNightlyRatePKR == null) {
            return a.hotel.name.compareTo(b.hotel.name);
          }
          if (a.lowestNightlyRatePKR == null) return 1;
          if (b.lowestNightlyRatePKR == null) return -1;
          final priceCmp = a.lowestNightlyRatePKR!.compareTo(b.lowestNightlyRatePKR!);
          if (priceCmp != 0) return priceCmp;
          return b.hotel.rating.compareTo(a.hotel.rating);

        case HotelSortOption.priceHighToLow:
          if (a.lowestNightlyRatePKR == null && b.lowestNightlyRatePKR == null) {
            return a.hotel.name.compareTo(b.hotel.name);
          }
          if (a.lowestNightlyRatePKR == null) return 1;
          if (b.lowestNightlyRatePKR == null) return -1;
          final priceCmp = b.lowestNightlyRatePKR!.compareTo(a.lowestNightlyRatePKR!);
          if (priceCmp != 0) return priceCmp;
          return b.hotel.rating.compareTo(a.hotel.rating);

        case HotelSortOption.ratingHighToLow:
          final ratingCmp = b.hotel.rating.compareTo(a.hotel.rating);
          if (ratingCmp != 0) return ratingCmp;
          return b.hotel.reviewCount.compareTo(a.hotel.reviewCount);

        case HotelSortOption.nearest:
          if (a.distanceKm == null && b.distanceKm == null) {
            return a.hotel.name.compareTo(b.hotel.name);
          }
          if (a.distanceKm == null) return 1;
          if (b.distanceKm == null) return -1;
          final distCmp = a.distanceKm!.compareTo(b.distanceKm!);
          if (distCmp != 0) return distCmp;
          return b.hotel.rating.compareTo(a.hotel.rating);
      }
    });
  }
}
