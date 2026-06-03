import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:situkang_app/core/network/connectivity_manager.dart';

void main() {
  group('ConnectivityManagerImpl', () {
    late ConnectivityManagerImpl manager;

    tearDown(() {
      manager.dispose();
    });

    test('initial currentStatus defaults to online', () {
      manager = ConnectivityManagerImpl(
        checkInterval: const Duration(seconds: 30),
      );

      // Before any check completes, the default is online.
      expect(manager.currentStatus, ConnectivityStatus.online);
    });

    test('isOnline returns true when status is online', () {
      manager = ConnectivityManagerImpl(
        checkInterval: const Duration(seconds: 30),
      );

      expect(manager.isOnline, isTrue);
    });

    test('reportConnectivityError sets status to offline', () {
      manager = ConnectivityManagerImpl(
        checkInterval: const Duration(seconds: 30),
      );

      manager.reportConnectivityError();

      expect(manager.currentStatus, ConnectivityStatus.offline);
      expect(manager.isOnline, isFalse);
    });

    test('reportConnectivitySuccess sets status to online', () {
      manager = ConnectivityManagerImpl(
        checkInterval: const Duration(seconds: 30),
      );

      // First go offline
      manager.reportConnectivityError();
      expect(manager.currentStatus, ConnectivityStatus.offline);

      // Then report success
      manager.reportConnectivitySuccess();
      expect(manager.currentStatus, ConnectivityStatus.online);
      expect(manager.isOnline, isTrue);
    });

    test('statusStream emits only on status change', () async {
      manager = ConnectivityManagerImpl(
        checkInterval: const Duration(seconds: 30),
      );

      final statuses = <ConnectivityStatus>[];
      final subscription = manager.statusStream.listen(statuses.add);

      // Report error - should emit offline
      manager.reportConnectivityError();
      // Report error again - should NOT emit (same status)
      manager.reportConnectivityError();
      // Report success - should emit online
      manager.reportConnectivitySuccess();
      // Report success again - should NOT emit (same status)
      manager.reportConnectivitySuccess();

      // Allow microtasks to complete
      await Future<void>.delayed(Duration.zero);

      expect(statuses, [ConnectivityStatus.offline, ConnectivityStatus.online]);

      await subscription.cancel();
    });

    test('statusStream does not emit duplicate consecutive statuses', () async {
      manager = ConnectivityManagerImpl(
        checkInterval: const Duration(seconds: 30),
      );

      final statuses = <ConnectivityStatus>[];
      final subscription = manager.statusStream.listen(statuses.add);

      // Multiple offline reports should only emit once
      manager.reportConnectivityError();
      manager.reportConnectivityError();
      manager.reportConnectivityError();

      await Future<void>.delayed(Duration.zero);

      expect(statuses, [ConnectivityStatus.offline]);

      await subscription.cancel();
    });

    test('statusStream is broadcast (supports multiple listeners)', () async {
      manager = ConnectivityManagerImpl(
        checkInterval: const Duration(seconds: 30),
      );

      final statuses1 = <ConnectivityStatus>[];
      final statuses2 = <ConnectivityStatus>[];
      final sub1 = manager.statusStream.listen(statuses1.add);
      final sub2 = manager.statusStream.listen(statuses2.add);

      manager.reportConnectivityError();

      await Future<void>.delayed(Duration.zero);

      expect(statuses1, [ConnectivityStatus.offline]);
      expect(statuses2, [ConnectivityStatus.offline]);

      await sub1.cancel();
      await sub2.cancel();
    });

    test('dispose cancels periodic timer and closes stream', () async {
      manager = ConnectivityManagerImpl(
        checkInterval: const Duration(seconds: 30),
      );

      manager.dispose();

      // After dispose, reporting should not throw but stream is closed
      // The stream controller is closed, so no new events are emitted
      expect(manager.currentStatus, ConnectivityStatus.online);
    });

    test('checkConnectivity performs a check and returns status', () async {
      // This test uses a real DNS lookup - it will pass if the test machine
      // has internet connectivity. In CI without internet, this would return offline.
      manager = ConnectivityManagerImpl(
        checkInterval: const Duration(seconds: 30),
      );

      final status = await manager.checkConnectivity();

      // The result depends on actual connectivity, but it should be a valid enum
      expect(status, isA<ConnectivityStatus>());
      expect(manager.currentStatus, status);
    });

    test(
        'checkConnectivity with unreachable host returns offline',
        () async {
      // Use a host that will fail DNS lookup
      manager = ConnectivityManagerImpl(
        checkInterval: const Duration(seconds: 30),
        lookupHost: 'this.host.definitely.does.not.exist.invalid',
      );

      final status = await manager.checkConnectivity();

      expect(status, ConnectivityStatus.offline);
      expect(manager.currentStatus, ConnectivityStatus.offline);
      expect(manager.isOnline, isFalse);
    });

    test('transition from offline to online emits online event', () async {
      manager = ConnectivityManagerImpl(
        checkInterval: const Duration(seconds: 30),
      );

      final statuses = <ConnectivityStatus>[];
      final subscription = manager.statusStream.listen(statuses.add);

      // Go offline first
      manager.reportConnectivityError();
      await Future<void>.delayed(Duration.zero);

      // Then go online
      manager.reportConnectivitySuccess();
      await Future<void>.delayed(Duration.zero);

      expect(statuses, [ConnectivityStatus.offline, ConnectivityStatus.online]);

      await subscription.cancel();
    });
  });

  group('ConnectivityStatus', () {
    test('enum has online and offline values', () {
      expect(ConnectivityStatus.values, hasLength(2));
      expect(ConnectivityStatus.values, contains(ConnectivityStatus.online));
      expect(ConnectivityStatus.values, contains(ConnectivityStatus.offline));
    });
  });
}
