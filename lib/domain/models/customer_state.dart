import 'customer_booking.dart';
import 'stay_date.dart';
import 'traveler_profile.dart';

/// The committed state for the local customer app.
final class CustomerState {
  const CustomerState({
    this.schemaVersion = 1,
    this.catalogVersion = 1,
    this.isInitialized = false,
    required this.anchorDate,
    this.profile,
    this.bookings = const [],
    this.savedHotelIds = const {},
    this.selectedCity,
  });

  factory CustomerState.initial({StayDate? anchorDate}) {
    final now = DateTime.now();
    final anchor = anchorDate ?? StayDate(now.year, now.month, now.day);
    return CustomerState(
      anchorDate: anchor,
      profile: const TravelerProfile(
        id: 'user_local',
        name: 'Mudasir Unar',
        phone: '03001234567',
        email: 'mudasir@example.com',
      ),
    );
  }

  factory CustomerState.fromJson(Map<String, dynamic> json) {
    final schemaVersion = json['schemaVersion'] as int? ?? 1;
    final catalogVersion = json['catalogVersion'] as int? ?? 1;
    final isInitialized = json['isInitialized'] as bool? ?? false;

    final anchorStr = json['anchorDate'] as String?;
    final anchorDate = anchorStr != null
        ? StayDate.parse(anchorStr)
        : StayDate.fromDateTime(DateTime.now());

    final profileJson = json['profile'] as Map<String, dynamic>?;
    final profile = profileJson != null ? TravelerProfile.fromJson(profileJson) : null;

    final bookingsRaw = json['bookings'] as List<dynamic>? ?? const [];
    final bookings = bookingsRaw
        .map((b) => CustomerBooking.fromJson(b as Map<String, dynamic>))
        .toList();

    final savedRaw = json['savedHotelIds'] as List<dynamic>? ?? const [];
    final savedHotelIds = savedRaw.map((s) => s.toString()).toSet();

    final selectedCity = json['selectedCity'] as String?;

    return CustomerState(
      schemaVersion: schemaVersion,
      catalogVersion: catalogVersion,
      isInitialized: isInitialized,
      anchorDate: anchorDate,
      profile: profile,
      bookings: List.unmodifiable(bookings),
      savedHotelIds: Set.unmodifiable(savedHotelIds),
      selectedCity: selectedCity,
    );
  }

  final int schemaVersion;
  final int catalogVersion;
  final bool isInitialized;
  final StayDate anchorDate;
  final TravelerProfile? profile;
  final List<CustomerBooking> bookings;
  final Set<String> savedHotelIds;
  final String? selectedCity;

  List<CustomerBooking> get activeBookings =>
      bookings.where((b) => b.isActive).toList();

  bool isHotelSaved(String hotelId) => savedHotelIds.contains(hotelId);

  CustomerState copyWith({
    int? schemaVersion,
    int? catalogVersion,
    bool? isInitialized,
    StayDate? anchorDate,
    TravelerProfile? profile,
    List<CustomerBooking>? bookings,
    Set<String>? savedHotelIds,
    String? selectedCity,
    bool clearCity = false,
  }) => CustomerState(
    schemaVersion: schemaVersion ?? this.schemaVersion,
    catalogVersion: catalogVersion ?? this.catalogVersion,
    isInitialized: isInitialized ?? this.isInitialized,
    anchorDate: anchorDate ?? this.anchorDate,
    profile: profile ?? this.profile,
    bookings: bookings ?? this.bookings,
    savedHotelIds: savedHotelIds ?? this.savedHotelIds,
    selectedCity: clearCity ? null : (selectedCity ?? this.selectedCity),
  );

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'catalogVersion': catalogVersion,
    'isInitialized': isInitialized,
    'anchorDate': anchorDate.toString(),
    if (profile != null) 'profile': profile!.toJson(),
    'bookings': bookings.map((b) => b.toJson()).toList(),
    'savedHotelIds': savedHotelIds.toList(),
    if (selectedCity != null) 'selectedCity': selectedCity,
  };
}
