import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:hotel_management_system/data/local/hive_hotel_repository.dart';
import 'package:hotel_management_system/data/local/hotel_snapshot_codec.dart';
import 'package:hotel_management_system/domain/hotel_exception.dart';
import 'package:hotel_management_system/domain/models/hotel_state.dart';

import '../support/fixtures.dart';

void main() {
  late Directory directory;
  late HiveHotelRepository repository;
  var sequence = 0;
  late String boxName;
  HiveHotelRepository open() => HiveHotelRepository(
    directory: () async => directory.path,
    boxName: boxName,
  );

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('hotel_store_test_');
    boxName = 'hotel_test_${sequence++}';
    repository = open();
  });
  tearDown(() async {
    await repository.close();
    if (Hive.isBoxOpen(boxName)) await Hive.box<String>(boxName).close();
    await directory.delete(recursive: true);
  });

  test(
    'real file-backed store survives closing/reopening throughout a stay',
    () async {
      final first = await repository.load();
      expect(first.rooms, isEmpty);
      final f = HotelFixture()..reserve();
      await repository.save(f.state);
      await repository.close();
      repository = open();
      f.state = await repository.load();
      expect(f.state.bookings.single.guestIds, [f.guestId]);
      expect(f.state.metrics.activeBookings, 1);
      f.state = f.operations.checkIn(f.state, f.state.bookings.single.id);
      await repository.save(f.state);
      await repository.close();
      repository = open();
      f.state = await repository.load();
      expect(f.state.metrics.occupiedRooms, 1);
      f.state = f.operations.checkOut(f.state, f.state.bookings.single.id);
      await repository.save(f.state);
      await repository.close();
      repository = open();
      final completed = await repository.load();
      expect(completed.metrics.availableRooms, 1);
      expect(completed.metrics.activeBookings, 0);
      expect(completed.bookings.single.actualCheckOutAt, f.now.toUtc());
      expect(
        File('${directory.path}/$boxName.hive').lengthSync(),
        greaterThan(0),
      );
    },
  );

  test(
    'save before a successful load cannot overwrite unknown existing data',
    () async {
      await expectLater(
        repository.save(HotelState()),
        throwsA(hotelError(HotelErrorCode.notReady)),
      );
    },
  );

  test(
    'corrupt JSON is preserved and blocks saving until a successful retry',
    () async {
      final box = await Hive.openBox<String>(boxName, path: directory.path);
      const original = 'unreadable fictional content';
      await box.put(HiveHotelRepository.snapshotKey, original);
      await box.close();
      await expectLater(
        repository.load(),
        throwsA(hotelError(HotelErrorCode.corruptStorage)),
      );
      await expectLater(
        repository.save(HotelState()),
        throwsA(hotelError(HotelErrorCode.notReady)),
      );
      expect(
        Hive.box<String>(boxName).get(HiveHotelRepository.snapshotKey),
        original,
      );
      // Simulate external recovery, then exercise retry rather than automatic reset.
      await Hive.box<String>(boxName).put(
        HiveHotelRepository.snapshotKey,
        HotelSnapshotCodec().encode(HotelState()),
      );
      expect((await repository.load()).rooms, isEmpty);
      await repository.save(HotelFixture().state);
    },
  );

  test(
    'unsupported schema is preserved, not replaced with a fresh store',
    () async {
      final box = await Hive.openBox<String>(boxName, path: directory.path);
      const raw = '{"schemaVersion":999,"rooms":[],"guests":[],"bookings":[]}';
      await box.put(HiveHotelRepository.snapshotKey, raw);
      await box.close();
      await expectLater(
        repository.load(),
        throwsA(hotelError(HotelErrorCode.unsupportedSchema)),
      );
      expect(
        Hive.box<String>(boxName).get(HiveHotelRepository.snapshotKey),
        raw,
      );
    },
  );

  test('corrupt Hive file is not truncated by automatic recovery', () async {
    final file = File('${directory.path}/$boxName.hive');
    final original = List<int>.filled(32, 255);
    await file.writeAsBytes(original);
    await expectLater(
      repository.load(),
      throwsA(hotelError(HotelErrorCode.storageRead)),
    );
    expect(await file.readAsBytes(), original);
  });

  test(
    'directory failures allow retry and do not expose raw error text',
    () async {
      var fail = true;
      repository = HiveHotelRepository(
        boxName: boxName,
        directory: () async {
          if (fail) throw const FileSystemException('sensitive path');
          return directory.path;
        },
      );
      await expectLater(
        repository.load(),
        throwsA(hotelError(HotelErrorCode.storageRead)),
      );
      fail = false;
      expect((await repository.load()).rooms, isEmpty);
    },
  );

  test(
    'closed Hive backend maps write failure without overwriting saved state',
    () async {
      await repository.load();
      final f = HotelFixture();
      await repository.save(f.state);
      await Hive.box<String>(boxName).close();
      await expectLater(
        repository.save(HotelState()),
        throwsA(hotelError(HotelErrorCode.storageWrite)),
      );
      await repository.close();
      repository = open();
      expect((await repository.load()).rooms.single.number, '101');
    },
  );
  test('reload reopens an unexpectedly closed backend without losing saved records', () async {
    await repository.load();
    await repository.save(HotelFixture().state);
    await Hive.box<String>(boxName).close();
    final recovered = await repository.load();
    expect(recovered.rooms.single.number, '101');
    await repository.save(recovered);
  });
}
