import 'dart:async';

import 'package:hotel_management_system/domain/hotel_exception.dart';
import 'package:hotel_management_system/domain/models/hotel_state.dart';
import 'package:hotel_management_system/domain/repositories/hotel_repository.dart';

final class FakeRepository implements HotelRepository {
  FakeRepository([HotelState? initial]) : saved = initial ?? HotelState();
  HotelState saved;
  bool failRead = false;
  bool failWrite = false;
  bool closed = false;
  int writes = 0;
  Completer<void>? readGate;
  Completer<void>? writeGate;

  @override
  Future<HotelState> load() async {
    await readGate?.future;
    if (failRead) {
      throw const HotelException(
        HotelErrorCode.storageRead,
        'Unable to load records.',
      );
    }
    return saved;
  }

  @override
  Future<void> save(HotelState state) async {
    writes++;
    await writeGate?.future;
    if (failWrite) {
      throw const HotelException(
        HotelErrorCode.storageWrite,
        'Unable to save changes.',
      );
    }
    saved = state;
  }

  @override
  Future<void> close() async {
    closed = true;
  }
}
