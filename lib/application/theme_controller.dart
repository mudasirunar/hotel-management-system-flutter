import 'package:flutter/material.dart';

import '../data/local/theme_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeController({ThemePreferences? preferences})
    : _preferences = preferences ?? ThemePreferences();

  final ThemePreferences _preferences;
  ThemeMode _mode = ThemeMode.system;
  bool _loading = true;
  bool _saving = false;
  bool _disposed = false;
  bool _closed = false;
  String? _error;
  Future<void>? _pending;

  ThemeMode get mode => _mode;
  bool get loading => _loading;
  bool get saving => _saving;
  String? get error => _error;

  Future<void> load() {
    if (_closed) return Future.value();
    if (_pending != null) return _pending!;
    return _pending = _load().whenComplete(() => _pending = null);
  }

  Future<void> _load() async {
    _loading = true;
    _error = null;
    _notify();
    try {
      final stored = await _preferences.load();
      _mode = switch (stored) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    } catch (_) {
      _error = 'Your appearance preference could not be loaded. Using the device theme for now. Try choosing a theme again.';
    } finally {
      _loading = false;
      _notify();
    }
  }

  Future<bool> select(ThemeMode mode) async {
    if (_closed || _loading || _saving) return false;
    _saving = true;
    _error = null;
    _notify();
    var saved = false;
    final operation = () async {
      try {
        await _preferences.save(mode.name);
        _mode = mode;
        saved = true;
      } catch (_) {
        _error = 'Unable to save your theme. Please try again. Your previous preference is unchanged.';
      } finally {
        _saving = false;
        _notify();
      }
    }();
    _pending = operation;
    await operation;
    _pending = null;
    return saved;
  }

  Future<void> close() async {
    _closed = true;
    await _pending;
    await _preferences.close();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
