import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';

enum ConnectivityStatus {
  online,
  offline,
}

typedef NetworkProbe = Future<bool> Function();

/// Service providing debounced online/offline status and reconnect signals.
///
/// Failed images or transient network operations can listen to [reconnectTick]
/// to retry visible work once without spamming requests or resetting local state.
class ConnectivityService with WidgetsBindingObserver {
  ConnectivityService({
    NetworkProbe? networkProbe,
    this._debounceDuration = const Duration(milliseconds: 500),
    bool observeLifecycle = true,
  })  : _networkProbe = networkProbe ?? _defaultProbe {
    if (observeLifecycle) {
      WidgetsBinding.instance.addObserver(this);
    }
  }

  final NetworkProbe _networkProbe;
  final Duration _debounceDuration;

  ConnectivityStatus _status = ConnectivityStatus.online;
  final ValueNotifier<ConnectivityStatus> statusNotifier =
      ValueNotifier<ConnectivityStatus>(ConnectivityStatus.online);

  final ValueNotifier<int> reconnectTick = ValueNotifier<int>(0);

  Timer? _debounceTimer;
  bool _isDisposed = false;
  bool _isProbing = false;

  ConnectivityStatus get currentStatus => _status;
  bool get isOnline => _status == ConnectivityStatus.online;
  bool get isOffline => _status == ConnectivityStatus.offline;

  /// Default internet probe attempting to resolve a lightweight DNS record.
  static Future<bool> _defaultProbe() async {
    try {
      final result = await InternetAddress.lookup('example.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Checks network availability and updates status.
  /// If transitioning from offline to online, fires a debounced [reconnectTick].
  Future<bool> checkConnectivity() async {
    if (_isDisposed || _isProbing) return isOnline;
    _isProbing = true;

    try {
      final online = await _networkProbe();
      final newStatus =
          online ? ConnectivityStatus.online : ConnectivityStatus.offline;
      _updateStatus(newStatus);
      return online;
    } finally {
      _isProbing = false;
    }
  }

  /// Manually forces a status (useful for demo offline mode and testing).
  void setStatus(ConnectivityStatus newStatus) {
    _updateStatus(newStatus);
  }

  void _updateStatus(ConnectivityStatus newStatus) {
    if (_isDisposed) return;
    final previous = _status;
    _status = newStatus;

    if (previous != newStatus) {
      statusNotifier.value = newStatus;
    }

    // Trigger reconnect tick on offline -> online transition
    if (previous == ConnectivityStatus.offline &&
        newStatus == ConnectivityStatus.online) {
      _scheduleReconnectTick();
    }
  }

  void _scheduleReconnectTick() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      if (_isDisposed) return;
      reconnectTick.value = reconnectTick.value + 1;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isDisposed) {
      // Bounded check on app resume to allow visible retries if connection restored
      checkConnectivity().then((online) {
        if (online && !_isDisposed) {
          _scheduleReconnectTick();
        }
      });
    }
  }

  void dispose() {
    _isDisposed = true;
    _debounceTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    statusNotifier.dispose();
    reconnectTick.dispose();
  }
}
