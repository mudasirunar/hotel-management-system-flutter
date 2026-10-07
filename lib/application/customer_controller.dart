import 'dart:math';

import 'package:flutter/foundation.dart';

import '../domain/hotel_exception.dart';
import '../domain/models/customer_booking.dart';
import '../domain/models/customer_state.dart';
import '../domain/models/hotel.dart';
import '../domain/models/hotel_catalog.dart';
import '../domain/models/hotel_room.dart';
import '../domain/models/stay_date.dart';
import '../domain/models/traveler_profile.dart';
import '../domain/repositories/customer_repository.dart';
import '../domain/services/customer_availability_service.dart';

enum CustomerLoadStatus { initial, loading, ready, failed }

final class CustomerController extends ChangeNotifier {
  CustomerController({
    required this._repository,
    CustomerAvailabilityService? availabilityService,
  }) : _availabilityService = availabilityService ?? const CustomerAvailabilityService();

  final CustomerRepository _repository;
  final CustomerAvailabilityService _availabilityService;

  CustomerState _state = CustomerState.initial();
  HotelCatalog _catalog = const HotelCatalog();
  CustomerLoadStatus _status = CustomerLoadStatus.initial;
  HotelException? _loadError;
  String? _activeOperation;
  Future<void> _tail = Future.value();
  bool _disposed = false;
  Future<void>? _closeFuture;

  CustomerState get state => _state;
  HotelCatalog get catalog => _catalog;
  CustomerLoadStatus get status => _status;
  HotelException? get loadError => _loadError;
  String? get activeOperation => _activeOperation;

  /// Loads both the bundled catalog and the committed customer state.
  Future<void> load() => _enqueue(() async {
    _status = CustomerLoadStatus.loading;
    _loadError = null;
    _notify();
    try {
      final loadedCatalog = await _repository.loadCatalog();
      final loadedState = await _repository.loadState();
      _catalog = loadedCatalog;
      _state = loadedState;
      _status = CustomerLoadStatus.ready;
    } on HotelException catch (error) {
      _loadError = error;
      _status = CustomerLoadStatus.failed;
    } catch (_) {
      _loadError = const HotelException(
        HotelErrorCode.storageRead,
        'Unable to load your customer data. Please try again.',
      );
      _status = CustomerLoadStatus.failed;
    }
    _notify();
  });

  /// Evaluates room status for the given dates.
  RoomAvailabilityStatus checkRoomStatus({
    required HotelRoom room,
    required StayDate arrival,
    required StayDate departure,
  }) => _availabilityService.checkRoomStatus(
    room: room,
    arrival: arrival,
    departure: departure,
    inventoryBlocks: _catalog.inventoryBlocks,
    userBookings: _state.bookings,
  );

  /// Places a new local reservation and commits it atomically.
  Future<CustomerBooking> createBooking({
    required Hotel hotel,
    required HotelRoom room,
    required StayDate arrival,
    required StayDate departure,
    required int partySize,
    required String travelerName,
    required String travelerPhone,
    String? travelerEmail,
  }) async {
    _requireReady();

    final earliest = _state.anchorDate;
    final eligibilityError = _availabilityService.validateBookingEligibility(
      room: room,
      arrival: arrival,
      departure: departure,
      partySize: partySize,
      earliestAllowedArrival: earliest,
      catalog: _catalog,
      userBookings: _state.bookings,
    );

    if (eligibilityError != null) {
      throw HotelException(
        HotelErrorCode.bookingConflict,
        eligibilityError,
      );
    }

    if (travelerName.trim().isEmpty) {
      throw const HotelException(
        HotelErrorCode.validation,
        'Please enter traveler full name.',
        field: 'name',
      );
    }
    if (travelerPhone.trim().isEmpty) {
      throw const HotelException(
        HotelErrorCode.validation,
        'Please enter a valid phone number.',
        field: 'phone',
      );
    }

    final total = _availabilityService.calculateTotalAmount(
      room: room,
      arrival: arrival,
      departure: departure,
    );

    final bookingId = _generateBookingReference();
    final newBooking = CustomerBooking(
      id: bookingId,
      ownerId: _state.profile?.id ?? 'user_local',
      hotelId: hotel.id,
      roomId: room.id,
      arrivalDate: arrival,
      departureDate: departure,
      partySize: partySize,
      travelerName: travelerName.trim(),
      travelerPhone: travelerPhone.trim(),
      travelerEmail: travelerEmail?.trim(),
      hotelName: hotel.name,
      hotelAddress: hotel.address,
      roomType: room.type,
      roomNumber: room.number,
      nightlyRateMinor: room.nightlyRateMinor,
      totalAmountMinor: total,
      currency: room.currency,
      cancellationPolicy: hotel.cancellationPolicy,
      createdAt: DateTime.now(),
    );

    await _mutate('createBooking', (current) {
      // Re-verify eligibility on committed snapshot immediately before write
      final recheck = _availabilityService.validateBookingEligibility(
        room: room,
        arrival: arrival,
        departure: departure,
        partySize: partySize,
        earliestAllowedArrival: earliest,
        catalog: _catalog,
        userBookings: current.bookings,
      );
      if (recheck != null) {
        throw HotelException(
          HotelErrorCode.bookingConflict,
          recheck,
        );
      }

      return current.copyWith(
        bookings: [...current.bookings, newBooking],
      );
    });

    return newBooking;
  }

  /// Cancels an active reservation and releases its calendar block.
  Future<void> cancelBooking(String bookingId) => _mutate('cancelBooking', (current) {
    final index = current.bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) {
      throw const HotelException(
        HotelErrorCode.notFound,
        'Reservation not found.',
      );
    }
    final existing = current.bookings[index];
    if (existing.isCancelled) {
      return current; // already cancelled
    }

    final updated = existing.cancel(at: DateTime.now());
    final newBookings = List<CustomerBooking>.from(current.bookings);
    newBookings[index] = updated;

    return current.copyWith(bookings: newBookings);
  });

  /// Updates the traveler contact profile.
  Future<void> updateProfile({
    required String name,
    required String phone,
    String? email,
  }) => _mutate('updateProfile', (current) {
    if (name.trim().isEmpty) {
      throw const HotelException(
        HotelErrorCode.validation,
        'Name cannot be empty.',
        field: 'name',
      );
    }
    if (phone.trim().isEmpty) {
      throw const HotelException(
        HotelErrorCode.validation,
        'Phone number cannot be empty.',
        field: 'phone',
      );
    }

    final newProfile = (current.profile ?? const TravelerProfile(id: 'user_local', name: '', phone: '')).copyWith(
      name: name.trim(),
      phone: phone.trim(),
      email: email?.trim(),
    );

    return current.copyWith(profile: newProfile);
  });

  /// Toggles saved status for a given hotel.
  Future<void> toggleSavedHotel(String hotelId) => _mutate('toggleSavedHotel', (current) {
    final saved = Set<String>.from(current.savedHotelIds);
    if (saved.contains(hotelId)) {
      saved.remove(hotelId);
    } else {
      saved.add(hotelId);
    }
    return current.copyWith(savedHotelIds: saved);
  });

  /// Sets or clears preferred city filter.
  Future<void> setSelectedCity(String? city) => _mutate('setSelectedCity', (current) {
    return current.copyWith(
      selectedCity: city,
      clearCity: city == null,
    );
  });

  /// Resets traveler profile back to guest.
  Future<void> resetProfile() => _mutate('resetProfile', (current) {
    return current.copyWith(clearProfile: true);
  });

  /// Clears customer bookings and favorites on this device, keeping the catalog intact.
  Future<void> clearCustomerData() => _mutate('clearCustomerData', (current) {
    return current.copyWith(
      bookings: const [],
      savedHotelIds: const {},
      clearProfile: true,
      clearCity: true,
    );
  });

  Future<void> _mutate(
    String operation,
    CustomerState Function(CustomerState current) transform,
  ) => _enqueue(() async {
    _requireReady();
    _activeOperation = operation;
    _notify();
    try {
      final candidate = transform(_state);
      await _repository.saveState(candidate);
      _state = candidate;
    } on HotelException {
      rethrow;
    } catch (_) {
      throw const HotelException(
        HotelErrorCode.storageWrite,
        'Unable to save your changes. Please try again.',
      );
    } finally {
      _activeOperation = null;
      _notify();
    }
  });

  Future<void> _enqueue(Future<void> Function() operation) {
    if (_disposed || _closeFuture != null) {
      return Future.error(
        const HotelException(
          HotelErrorCode.notReady,
          'Customer workspace has been closed.',
        ),
      );
    }
    final next = _tail.then((_) => operation());
    _tail = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }

  void _requireReady() {
    if (_status != CustomerLoadStatus.ready || _disposed) {
      throw const HotelException(
        HotelErrorCode.notReady,
        'Catalog and customer data must be loaded first.',
      );
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  String _generateBookingReference() {
    final rand = Random();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final suffix = List.generate(4, (_) => chars[rand.nextInt(chars.length)]).join();
    return 'BK-$suffix';
  }

  Future<void> close() =>
      _closeFuture ??= _tail.then((_) => _repository.close());

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
