import 'package:hive_ce/hive_ce.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/hotel_exception.dart';
import '../../domain/models/hotel_state.dart';
import '../../domain/repositories/hotel_repository.dart';
import 'hotel_snapshot_codec.dart';

/// One box/key contains one consistent aggregate. Only the controller writes it.
final class HiveHotelRepository implements HotelRepository {
  HiveHotelRepository({
    Future<String> Function()? directory,
    this._boxName = 'hotel_records',
    HiveInterface? hive,
  }) : _directory = directory ?? _applicationDirectory,
       _hive = hive ?? Hive;

  final Future<String> Function() _directory;
  final String _boxName;
  final HiveInterface _hive;
  final _codec = HotelSnapshotCodec();
  Box<String>? _box;
  bool _loaded = false;
  bool _closed = false;
  static const snapshotKey = 'snapshot';

  static Future<String> _applicationDirectory() async =>
      (await getApplicationSupportDirectory()).path;

  @override
  Future<HotelState> load() async {
    if (_closed) {
      throw const HotelException(
        HotelErrorCode.notReady,
        'Storage has been closed.',
      );
    }
    _loaded = false;
    try {
      // Do not let automatic recovery truncate an unreadable database silently.
      if (_box?.isOpen != true) {
        _box = await _hive.openBox<String>(
          _boxName,
          path: await _directory(),
          crashRecovery: false,
        );
      }
      final raw = _box!.get(snapshotKey);
      final state = raw == null ? HotelState() : _codec.decode(raw);
      _loaded = true;
      return state;
    } on HotelException {
      rethrow;
    } catch (_) {
      throw const HotelException(
        HotelErrorCode.storageRead,
        'Unable to open saved records. Check device storage and try again.',
      );
    }
  }

  @override
  Future<void> save(HotelState state) async {
    if (!_loaded || _closed) {
      throw const HotelException(
        HotelErrorCode.notReady,
        'Load your records before making changes.',
      );
    }
    final encoded = _codec.encode(state);
    try {
      // Hive's write future completes after the backend write, not just its cache update.
      await _box!.put(snapshotKey, encoded);
    } catch (_) {
      throw const HotelException(
        HotelErrorCode.storageWrite,
        'Unable to save changes. Check device storage and try again.',
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
