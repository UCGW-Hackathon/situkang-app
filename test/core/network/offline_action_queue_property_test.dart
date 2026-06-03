import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect, group, setUp, setUpAll, tearDown, tearDownAll, test;
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart' hide any;
import 'package:situkang_app/core/constants/app_constants.dart';
import 'package:situkang_app/core/network/api_client.dart';
import 'package:situkang_app/core/network/connectivity_manager.dart';
import 'package:situkang_app/core/network/offline_action_queue.dart';

// ─── Mocks ─────────────────────────────────────────────────────────────────────

class MockApiClient extends Mock implements ApiClient {}

class MockConnectivityManager extends Mock implements ConnectivityManager {}

// ─── Helpers ───────────────────────────────────────────────────────────────────

/// Creates a QueuedAction with a unique id based on index.
QueuedAction _createAction({
  required int index,
  String method = 'POST',
  String path = '/test',
  dynamic data,
  int retryCount = 0,
}) {
  return QueuedAction(
    id: 'action-$index',
    method: method,
    path: path,
    data: data,
    createdAt: DateTime(2024, 1, 1, 0, 0, index),
    retryCount: retryCount,
  );
}

/// Creates a mock connectivity manager that reports online status.
MockConnectivityManager _createOnlineConnectivityManager() {
  final mock = MockConnectivityManager();
  final controller = StreamController<ConnectivityStatus>.broadcast();
  when(() => mock.statusStream).thenAnswer((_) => controller.stream);
  when(() => mock.isOnline).thenReturn(true);
  when(() => mock.currentStatus).thenReturn(ConnectivityStatus.online);
  return mock;
}

/// Property-based tests for OfflineActionQueue.
///
/// These tests verify universal properties hold across all randomly generated
/// inputs using the glados property-based testing library.
void main() {
  late String hivePath;
  late Box<Map<dynamic, dynamic>> capacityBox;
  late Box<Map<dynamic, dynamic>> fifoBox;

  setUpAll(() async {
    hivePath = '.test_hive_pbt_oaq_${DateTime.now().millisecondsSinceEpoch}';
    Hive.init(hivePath);
    capacityBox = await Hive.openBox<Map<dynamic, dynamic>>('pbt_capacity');
    fifoBox = await Hive.openBox<Map<dynamic, dynamic>>('pbt_fifo');
  });

  tearDownAll(() async {
    if (capacityBox.isOpen) await capacityBox.close();
    if (fifoBox.isOpen) await fifoBox.close();
    await Hive.close();
    final dir = Directory(hivePath);
    if (await dir.exists()) {
      try {
        await dir.delete(recursive: true);
      } catch (_) {}
    }
  });

  // ─── Property 14: Offline Queue Capacity Invariant ─────────────────────────
  // **Validates: Requirements 26.1, 26.2**
  group('Property 14: Offline Queue Capacity Invariant', () {
    Glados<int>(any.intInRange(1, 150)).test(
      'queue size never exceeds 50 items for any number of enqueue operations',
      (numActions) async {
        await capacityBox.clear();

        final queue = HiveOfflineActionQueueImpl(
          apiClient: MockApiClient(),
          connectivityManager: _createOnlineConnectivityManager(),
          box: capacityBox,
        );

        // Enqueue numActions items, checking invariant after each
        for (var i = 0; i < numActions; i++) {
          await queue.enqueue(_createAction(index: i));

          // INVARIANT: queue size must NEVER exceed maxOfflineQueueSize
          expect(
            queue.pendingCount,
            lessThanOrEqualTo(AppConstants.maxOfflineQueueSize),
            reason:
                'After enqueue #${i + 1}, queue size (${queue.pendingCount}) '
                'must not exceed ${AppConstants.maxOfflineQueueSize}',
          );
        }

        // Final size should be min(numActions, maxSize)
        final expectedSize = numActions <= AppConstants.maxOfflineQueueSize
            ? numActions
            : AppConstants.maxOfflineQueueSize;
        expect(
          queue.pendingCount,
          equals(expectedSize),
          reason:
              'After enqueueing $numActions items, queue size should be '
              '$expectedSize',
        );

        queue.dispose();
      },
    );

    Glados<int>(any.intInRange(51, 200)).test(
      'when at capacity, enqueue evicts an item keeping size at 50',
      (numActions) async {
        await capacityBox.clear();

        final queue = HiveOfflineActionQueueImpl(
          apiClient: MockApiClient(),
          connectivityManager: _createOnlineConnectivityManager(),
          box: capacityBox,
        );

        // Enqueue numActions items (more than capacity)
        for (var i = 0; i < numActions; i++) {
          await queue.enqueue(_createAction(index: i));
        }

        // Queue should be exactly at max capacity
        expect(
          queue.pendingCount,
          equals(AppConstants.maxOfflineQueueSize),
          reason:
              'After enqueueing $numActions items (> capacity), queue should '
              'be exactly at max capacity ${AppConstants.maxOfflineQueueSize}',
        );

        // The most recently added item should always be present
        final pending = await queue.getPendingActions();
        final ids = pending.map((a) => a.id).toSet();
        expect(
          ids.contains('action-${numActions - 1}'),
          isTrue,
          reason:
              'The most recently enqueued item (action-${numActions - 1}) '
              'should always be present in the queue',
        );

        // The oldest items should have been evicted
        // At minimum, the very first item should be gone
        expect(
          ids.contains('action-0'),
          isFalse,
          reason:
              'The oldest item (action-0) should have been evicted '
              'when queue overflowed',
        );

        queue.dispose();
      },
    );
  });

  // ─── Property 15: Offline Queue FIFO Processing ────────────────────────────
  // **Validates: Requirements 26.3**
  group('Property 15: Offline Queue FIFO Processing', () {
    Glados<int>(any.intInRange(1, 50)).test(
      'actions are processed in exact enqueue order (FIFO)',
      (numActions) async {
        await fifoBox.clear();

        final mockApiClient = MockApiClient();
        final queue = HiveOfflineActionQueueImpl(
          apiClient: mockApiClient,
          connectivityManager: _createOnlineConnectivityManager(),
          box: fifoBox,
        );

        final executionOrder = <String>[];

        // Set up mock to record execution order for each action
        for (var i = 0; i < numActions; i++) {
          final path = '/path-$i';
          when(() => mockApiClient.post<dynamic>(path, data: null))
              .thenAnswer((_) async {
            executionOrder.add('action-$i');
            return Response(
              requestOptions: RequestOptions(path: path),
              statusCode: 200,
            );
          });
        }

        // Enqueue actions in order
        for (var i = 0; i < numActions; i++) {
          await queue.enqueue(QueuedAction(
            id: 'action-$i',
            method: 'POST',
            path: '/path-$i',
            data: null,
            createdAt: DateTime(2024, 1, 1, 0, 0, i),
            retryCount: 0,
          ));
        }

        // Process the queue
        await queue.processQueue();

        // Verify FIFO order: actions must be processed in the exact order
        // they were enqueued
        expect(
          executionOrder.length,
          equals(numActions),
          reason: 'All $numActions actions should have been processed',
        );

        for (var i = 0; i < numActions; i++) {
          expect(
            executionOrder[i],
            equals('action-$i'),
            reason:
                'Action at position $i should be action-$i but was '
                '${executionOrder[i]} — FIFO order violated',
          );
        }

        // Queue should be empty after processing
        expect(queue.pendingCount, equals(0));

        queue.dispose();
      },
    );

    Glados<int>(any.intInRange(2, 50)).test(
      'getPendingActions always returns items in FIFO order (sorted by createdAt)',
      (numActions) async {
        await fifoBox.clear();

        final queue = HiveOfflineActionQueueImpl(
          apiClient: MockApiClient(),
          connectivityManager: _createOnlineConnectivityManager(),
          box: fifoBox,
        );

        // Enqueue actions in order
        for (var i = 0; i < numActions; i++) {
          await queue.enqueue(_createAction(index: i));
        }

        final pending = await queue.getPendingActions();

        // Verify the list is in FIFO order (sorted by createdAt ascending)
        for (var i = 1; i < pending.length; i++) {
          expect(
            pending[i].createdAt.isAfter(pending[i - 1].createdAt) ||
                pending[i].createdAt.isAtSameMomentAs(pending[i - 1].createdAt),
            isTrue,
            reason:
                'Action at index $i (${pending[i].createdAt}) should not be '
                'before action at index ${i - 1} (${pending[i - 1].createdAt})',
          );
        }

        queue.dispose();
      },
    );

    Glados<int>(any.intInRange(1, 50)).test(
      'processing order matches getPendingActions order exactly',
      (numActions) async {
        await fifoBox.clear();

        final mockApiClient = MockApiClient();
        final queue = HiveOfflineActionQueueImpl(
          apiClient: mockApiClient,
          connectivityManager: _createOnlineConnectivityManager(),
          box: fifoBox,
        );

        final executionOrder = <String>[];

        // Set up mock to record execution order
        for (var i = 0; i < numActions; i++) {
          final path = '/path-$i';
          when(() => mockApiClient.post<dynamic>(path, data: null))
              .thenAnswer((_) async {
            executionOrder.add('action-$i');
            return Response(
              requestOptions: RequestOptions(path: path),
              statusCode: 200,
            );
          });
        }

        // Enqueue actions
        for (var i = 0; i < numActions; i++) {
          await queue.enqueue(QueuedAction(
            id: 'action-$i',
            method: 'POST',
            path: '/path-$i',
            data: null,
            createdAt: DateTime(2024, 1, 1, 0, 0, i),
            retryCount: 0,
          ));
        }

        // Get the expected order from getPendingActions
        final expectedOrder =
            (await queue.getPendingActions()).map((a) => a.id).toList();

        // Process the queue
        await queue.processQueue();

        // Processing order must match getPendingActions order exactly
        expect(
          executionOrder,
          equals(expectedOrder),
          reason:
              'Processing order must match getPendingActions order (FIFO)',
        );

        queue.dispose();
      },
    );
  });
}
