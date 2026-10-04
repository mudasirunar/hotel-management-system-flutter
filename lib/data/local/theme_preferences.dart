import 'package:hive_ce/hive_ce.dart';
import 'package:path_provider/path_provider.dart';

/// UI preferences live separately from hotel records and their schema.
class ThemePreferences {
  Box<String>? _box;

  Future<Box<String>> _open() async {
    if (_box?.isOpen != true) {
      _box = await Hive.openBox<String>(
        'appearance_preferences',
        path: (await getApplicationSupportDirectory()).path,
        crashRecovery: false,
      );
    }
    return _box!;
  }

  Future<String?> load() async => (await _open()).get('theme_mode');
  Future<void> save(String mode) async =>
      (await _open()).put('theme_mode', mode);
  Future<void> close() async => _box?.close();
}
