import 'package:hive_ce/hive_ce.dart';
import 'package:path_provider/path_provider.dart';

class HotelProfile {
  const HotelProfile({
    required this.name,
    required this.phone,
    required this.address,
    required this.checkInTime,
    required this.checkOutTime,
  });

  final String name;
  final String phone;
  final String address;
  final String checkInTime;
  final String checkOutTime;

  static const defaultProfile = HotelProfile(
    name: 'Grand Horizon Hotel',
    phone: '+92 51 111 222 333',
    address: 'Club Road, Karachi, Pakistan',
    checkInTime: '14:00',
    checkOutTime: '12:00',
  );
}

class HotelProfilePreferences {
  HotelProfilePreferences({String? path}) : _customPath = path;

  final String? _customPath;
  Box<String>? _box;

  Future<Box<String>> _open() async {
    if (_box?.isOpen != true) {
      final p = _customPath ?? (await getApplicationSupportDirectory()).path;
      _box = await Hive.openBox<String>(
        'hotel_profile_preferences',
        path: p,
        crashRecovery: false,
      );
    }
    return _box!;
  }

  Future<HotelProfile> load() async {
    try {
      final box = await _open();
      return HotelProfile(
        name: box.get('name') ?? HotelProfile.defaultProfile.name,
        phone: box.get('phone') ?? HotelProfile.defaultProfile.phone,
        address: box.get('address') ?? HotelProfile.defaultProfile.address,
        checkInTime:
            box.get('checkInTime') ?? HotelProfile.defaultProfile.checkInTime,
        checkOutTime:
            box.get('checkOutTime') ?? HotelProfile.defaultProfile.checkOutTime,
      );
    } catch (_) {
      return HotelProfile.defaultProfile;
    }
  }

  Future<void> save(HotelProfile profile) async {
    final box = await _open();
    await box.put('name', profile.name);
    await box.put('phone', profile.phone);
    await box.put('address', profile.address);
    await box.put('checkInTime', profile.checkInTime);
    await box.put('checkOutTime', profile.checkOutTime);
  }

  Future<void> close() async => _box?.close();
}
