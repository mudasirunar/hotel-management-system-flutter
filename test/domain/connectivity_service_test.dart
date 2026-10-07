import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_management_system/domain/services/connectivity_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConnectivityService', () {
    test('initializes with default online status', () {
      final service = ConnectivityService(
        networkProbe: () async => true,
        observeLifecycle: false,
      );

      expect(service.currentStatus, ConnectivityStatus.online);
      expect(service.isOnline, isTrue);
      expect(service.isOffline, isFalse);
      expect(service.reconnectTick.value, 0);

      service.dispose();
    });

    test('manual status change updates statusNotifier and properties', () {
      final service = ConnectivityService(
        networkProbe: () async => true,
        observeLifecycle: false,
      );

      service.setStatus(ConnectivityStatus.offline);

      expect(service.currentStatus, ConnectivityStatus.offline);
      expect(service.isOnline, isFalse);
      expect(service.isOffline, isTrue);
      expect(service.statusNotifier.value, ConnectivityStatus.offline);

      service.dispose();
    });

    test('offline to online transition triggers debounced reconnectTick', () async {
      final service = ConnectivityService(
        networkProbe: () async => true,
        debounceDuration: const Duration(milliseconds: 50),
        observeLifecycle: false,
      );

      // Start offline
      service.setStatus(ConnectivityStatus.offline);
      expect(service.reconnectTick.value, 0);

      // Transition to online
      service.setStatus(ConnectivityStatus.online);
      // Immediately after, tick has not fired yet because of debounce
      expect(service.reconnectTick.value, 0);

      // Wait for debounce timer
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(service.reconnectTick.value, 1);

      service.dispose();
    });

    test('repeated fast transitions debounce into a single reconnectTick', () async {
      final service = ConnectivityService(
        networkProbe: () async => true,
        debounceDuration: const Duration(milliseconds: 50),
        observeLifecycle: false,
      );

      service.setStatus(ConnectivityStatus.offline);
      service.setStatus(ConnectivityStatus.online);
      // Quickly flip offline and online again
      service.setStatus(ConnectivityStatus.offline);
      service.setStatus(ConnectivityStatus.online);

      // Tick still 0 immediately
      expect(service.reconnectTick.value, 0);

      await Future<void>.delayed(const Duration(milliseconds: 80));
      // Coalesced into a single tick
      expect(service.reconnectTick.value, 1);

      service.dispose();
    });

    test('checkConnectivity invokes probe and updates status', () async {
      var probeResult = false;
      final service = ConnectivityService(
        networkProbe: () async => probeResult,
        observeLifecycle: false,
      );

      final result1 = await service.checkConnectivity();
      expect(result1, isFalse);
      expect(service.isOffline, isTrue);

      probeResult = true;
      final result2 = await service.checkConnectivity();
      expect(result2, isTrue);
      expect(service.isOnline, isTrue);

      service.dispose();
    });
  });
}
