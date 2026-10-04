import 'package:flutter/foundation.dart';

import '../domain/hotel_exception.dart';
import '../domain/models/hotel_state.dart';
import '../domain/models/room.dart';
import '../domain/models/stay_date.dart';
import '../domain/repositories/hotel_repository.dart';
import '../domain/services/hotel_operations.dart';
import '../domain/services/hotel_rules.dart';

enum HotelLoadStatus { initial, loading, ready, failed }

final class HotelController extends ChangeNotifier {
  HotelController({required this._repository, HotelOperations? operations})
    : _operations = operations ?? HotelOperations();

  final HotelRepository _repository;
  final HotelOperations _operations;
  HotelState _state = HotelState();
  HotelLoadStatus _status = HotelLoadStatus.initial;
  HotelException? _loadError;
  String? _activeOperation;
  Future<void> _tail = Future.value();
  bool _disposed = false;
  Future<void>? _closeFuture;

  HotelState get state => _state;
  HotelLoadStatus get status => _status;
  HotelException? get loadError => _loadError;
  String? get activeOperation => _activeOperation;

  /// Initialization/retry errors are represented by [status] and [loadError].
  Future<void> load() => _enqueue(() async {
    _status = HotelLoadStatus.loading;
    _loadError = null;
    _notify();
    try {
      final candidate = await _repository.load();
      HotelRules.validateSnapshot(candidate);
      _state = candidate;
      _status = HotelLoadStatus.ready;
    } on HotelException catch (error) {
      _loadError = error;
      _status = HotelLoadStatus.failed;
    } catch (_) {
      _loadError = const HotelException(
        HotelErrorCode.storageRead,
        'Unable to load your records. Please try again.',
      );
      _status = HotelLoadStatus.failed;
    }
    _notify();
  });

  Future<void> saveRoom({
    String? id,
    required String number,
    required String type,
    required int nightlyRateMinor,
  }) => _mutate(
    'room:${id ?? 'new'}',
    (state) => _operations.saveRoom(
      state,
      id: id,
      number: number,
      type: type,
      nightlyRateMinor: nightlyRateMinor,
    ),
  );

  Future<void> deleteRoom(String id) =>
      _mutate('room:$id', (state) => _operations.deleteRoom(state, id));

  Future<void> saveGuest({
    String? id,
    required String name,
    required String phone,
    required String cnic,
    required String address,
  }) => _mutate(
    'guest:${id ?? 'new'}',
    (state) => _operations.saveGuest(
      state,
      id: id,
      name: name,
      phone: phone,
      cnic: cnic,
      address: address,
    ),
  );

  Future<void> deleteGuest(String id) =>
      _mutate('guest:$id', (state) => _operations.deleteGuest(state, id));

  Future<void> createBooking({
    required String roomId,
    required List<String> guestIds,
    required String primaryGuestId,
    required StayDate arrivalDate,
    required StayDate departureDate,
  }) {
    // Copy mutable caller input before it waits in the write queue.
    final selectedGuests = List<String>.unmodifiable(guestIds);
    return _mutate(
      'booking:new',
      (state) => _operations.createBooking(
        state,
        roomId: roomId,
        guestIds: selectedGuests,
        primaryGuestId: primaryGuestId,
        arrivalDate: arrivalDate,
        departureDate: departureDate,
      ),
    );
  }

  Future<void> checkIn(String id) =>
      _mutate('booking:$id', (state) => _operations.checkIn(state, id));
  Future<void> checkOut(String id) =>
      _mutate('booking:$id', (state) => _operations.checkOut(state, id));
  Future<void> cancelBooking(String id) =>
      _mutate('booking:$id', (state) => _operations.cancelBooking(state, id));

  Future<void> clearAllData() => _mutate('system:clear', (_) => HotelState());

  Future<void> seedDemoData(HotelState demoState) =>
      _mutate('system:seed', (_) => demoState);

  List<Room> availableRooms(StayDate arrival, StayDate departure) {
    _requireReady();
    final today = _operations.today;
    HotelRules.dateRange(arrival, departure, today: today);
    return List.unmodifiable(
      _state.rooms.where(
        (room) => HotelRules.roomAvailable(
          _state,
          room.id,
          arrival,
          departure,
          today: today,
        ),
      ),
    );
  }

  Future<void> _mutate(
    String operation,
    HotelState Function(HotelState) transform,
  ) => _enqueue(() async {
    _requireReady();
    _activeOperation = operation;
    _notify();
    try {
      final candidate = transform(_state);
      // The UI only sees the last committed aggregate until this completes.
      await _repository.save(candidate);
      _state = candidate;
    } on HotelException {
      rethrow;
    } catch (_) {
      throw const HotelException(
        HotelErrorCode.storageWrite,
        'Unable to save changes. Please try again.',
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
          'This workspace has been closed.',
        ),
      );
    }
    final next = _tail.then((_) => operation());
    // A failed write must not poison subsequent retries or operations.
    _tail = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }

  void _requireReady() {
    if (_status != HotelLoadStatus.ready || _disposed) {
      throw const HotelException(
        HotelErrorCode.notReady,
        'Load your records before making changes.',
      );
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Wait for queued writes before closing the store. Repeated calls share a future.
  Future<void> close() =>
      _closeFuture ??= _tail.then((_) => _repository.close());

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
