import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/hotel_exception.dart';
import '../../domain/models/customer_state.dart';
import '../../domain/models/hotel_catalog.dart';
import '../../domain/repositories/customer_repository.dart';
import 'customer_snapshot_codec.dart';

final class HiveCustomerRepository implements CustomerRepository {
  HiveCustomerRepository({
    Future<String> Function()? directory,
    this.boxName = 'customer_booking_store',
    HiveInterface? hive,
    Future<String> Function(String)? assetLoader,
  }) : _directory = directory ?? _applicationDirectory,
       _hive = hive ?? Hive,
       _assetLoader = assetLoader ?? rootBundle.loadString;

  final Future<String> Function() _directory;
  final String boxName;
  final HiveInterface _hive;
  final Future<String> Function(String) _assetLoader;
  final _codec = const CustomerSnapshotCodec();

  static const snapshotKey = 'snapshot';
  static const catalogAssetKey = 'assets/data/hotel_catalog.json';

  Box<String>? _box;
  HotelCatalog? _cachedCatalog;
  bool _loaded = false;
  bool _closed = false;

  static Future<String> _applicationDirectory() async =>
      (await getApplicationSupportDirectory()).path;

  @override
  Future<HotelCatalog> loadCatalog() async {
    if (_cachedCatalog != null) return _cachedCatalog!;
    try {
      final jsonString = await _assetLoader(catalogAssetKey);
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      _cachedCatalog = HotelCatalog.fromJson(jsonMap);
      return _cachedCatalog!;
    } catch (_) {
      throw const HotelException(
        HotelErrorCode.storageRead,
        'Unable to load hotel catalog. Please check app assets.',
      );
    }
  }

  @override
  Future<CustomerState> loadState() async {
    if (_closed) {
      throw const HotelException(
        HotelErrorCode.notReady,
        'Storage has been closed.',
      );
    }
    _loaded = false;
    try {
      if (_box?.isOpen != true) {
        _box = await _hive.openBox<String>(
          boxName,
          path: await _directory(),
          crashRecovery: false,
        );
      }
      final raw = _box!.get(snapshotKey);
      CustomerState state;
      if (raw == null) {
        // Automatic idempotent first-use bootstrap
        state = CustomerState.initial().copyWith(isInitialized: true);
        await _box!.put(snapshotKey, _codec.encode(state));
      } else {
        state = _codec.decode(raw);
      }
      _loaded = true;
      return state;
    } on HotelException {
      rethrow;
    } catch (_) {
      throw const HotelException(
        HotelErrorCode.storageRead,
        'Unable to open customer records. Check device storage and try again.',
      );
    }
  }

  @override
  Future<void> saveState(CustomerState state) async {
    if (!_loaded || _closed) {
      throw const HotelException(
        HotelErrorCode.notReady,
        'Load customer records before making changes.',
      );
    }
    final encoded = _codec.encode(state);
    try {
      await _box!.put(snapshotKey, encoded);
    } catch (_) {
      throw const HotelException(
        HotelErrorCode.storageWrite,
        'Unable to save customer changes. Check device storage and try again.',
      );
    }
  }

  @override
  Future<void> close() async {
    _closed = true;
    _loaded = false;
    await _box?.close();
    _box = null;
  }
}
