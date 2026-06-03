import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:situkang_app/core/constants/app_constants.dart';
import 'package:situkang_app/core/network/api_client.dart';
import 'package:situkang_app/core/network/connectivity_manager.dart';
import 'package:situkang_app/core/network/offline_action_queue.dart';

// ─── Mocks ─────────────────────────────────────────────────────────────────────

class MockApiClient extends Mock implements ApiClient {}

class MockConnectivityManager extends Mock implements ConnectivityManager {}

// ─── Helpers ───────────────────────────────────────────────────────────────────

QueuedAction _createAction({
  String? id,
  String method = 'POST',
  String path = '/test',
  dynamic data,
  DateTime? createdAt,
  int retryCount = 0,
}) {
  return QueuedAction(
    id: id ?? DateTime.now().microsecondsSinceEpoch.toString(),
    method: method,
    path: path,
    data: data,
    createdAt: createdAt ?? DateTime.now(),
    retryCount: retryCount,
  );
}

void main() {
  late MockApiClient mockApiClient;
  late MockConnectivityManager mockConnectivityManager;
  late StreamController<ConnectivityStatus> connectivityController;
  late Box<Map<dynamic, dynamic>> box;
  late HiveOfflineActionQueueImpl queue;
  late List<QueuedAction> permanentFailures;

  setUpAll(() async {
    Hive.init('.test_hive_offline_queue');
  });

  setUp(() async {
    mockApiClient = MockApiClient();
    mockConnectivityManager = MockConnectivityManager();
    connectivityController = StreamController<ConnectivityStatus>.broadcast();
    permanentFailures = [];

    when(() => mockConnectivityManager.statusStream)
        .thenAnswer((_) => connectivityController.stream);
    when(() => mockConnectivityManager.isOnline).thenReturn(true);
    when(() => mockConnectivityManager.currentStatus)
        .thenReturn(ConnectivityStatus.online);

    // Open a fresh box for each test
    final boxName =
        'test_offline_queue_${DateTime.now().microsecondsSinceEpoch}';
    box = await Hive.openBox<Map<dynamic, dynamic>>(boxName);

    queue = HiveOfflineActionQueueImpl(
      apiClient: mockApiClient,
      connectivityManager: mockConnectivityManager,
      onPermanentFailure: (action) => permanentFailures.add(action),
      box: box,
    );
  });

  tearDown(() async {
    queue.dispose();
    await box.clear();
    await box.close();
    connectivityController.close();
  });

  tearDownAll(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
  });

  group('QueuedAction', () {
    test('serializes and deserializes correctly', () {
      final action = QueuedAction(
        id: 'test-1',
        method: 'POST',
        path: '/orders',
        data: {'title': 'Fix pipe'},
        createdAt: DateTime(2024, 1, 15, 10, 30),
        retryCount: 2,
      );

      final map = action.toMap();
      final restored = QueuedAction.fromMap(map);

      expect(restored.id, equals('test-1'));
      expect(restored.method, equals('POST'));
      expect(restored.path, equals('/orders'));
      expect(restored.data, equals({'title': 'Fix pipe'}));
      expect(restored.createdAt, equals(DateTime(2024, 1, 15, 10, 30)));
      expect(restored.retryCount, equals(2));
    });

    test('hasExhaustedRetries returns true when retryCount >= max', () {
      final action = _createAction(retryCount: 3);
      expect(action.hasExhaustedRetries, isTrue);
    });

    test('hasExhaustedRetries returns false when retryCount < max', () {
      final action = _createAction(retryCount: 2);
      expect(action.hasExhaustedRetries, isFalse);
    });

    test('copyWithIncrementedRetry increments retry count', () {
      final action = _createAction(retryCount: 1);
      final updated = action.copyWithIncrementedRetry();

      expect(updated.retryCount, equals(2));
      expect(updated.id, equals(action.id));
      expect(updated.method, equals(action.method));
      expect(updated.path, equals(action.path));
    });

    test('equality is based on id', () {
      final action1 = _createAction(id: 'same-id', method: 'POST');
      final action2 = _createAction(id: 'same-id', method: 'GET');

      expect(action1, equals(action2));
    });
  });

  group('OfflineActionQueue - enqueue', () {
    test('adds action to the queue', () async {
      final action = _createAction(id: 'action-1');

      await queue.enqueue(action);

      expect(queue.pendingCount, equals(1));
      final pending = await queue.getPendingActions();
      expect(pending.first.id, equals('action-1'));
    });

    test('multiple actions are stored', () async {
      await queue.enqueue(_createAction(id: 'a1'));
      await queue.enqueue(_createAction(id: 'a2'));
      await queue.enqueue(_createAction(id: 'a3'));

      expect(queue.pendingCount, equals(3));
    });

    test('evicts oldest action when at capacity (FIFO eviction)', () async {
      // Fill the queue to capacity
      for (var i = 0; i < AppConstants.maxOfflineQueueSize; i++) {
        await queue.enqueue(_createAction(
          id: 'action-$i',
          createdAt: DateTime(2024, 1, 1, 0, i),
        ));
      }

      expect(queue.pendingCount, equals(AppConstants.maxOfflineQueueSize));

      // Add one more — should evict the oldest (action-0)
      await queue.enqueue(_createAction(
        id: 'action-new',
        createdAt: DateTime(2024, 1, 1, 1, 0),
      ));

      expect(queue.pendingCount, equals(AppConstants.maxOfflineQueueSize));

      final pending = await queue.getPendingActions();
      final ids = pending.map((a) => a.id).toList();

      // The oldest (action-0) should be gone
      expect(ids, isNot(contains('action-0')));
      // The new one should be present
      expect(ids, contains('action-new'));
    });

    test('queue never exceeds max capacity', () async {
      // Add more than max
      for (var i = 0; i < AppConstants.maxOfflineQueueSize + 10; i++) {
        await queue.enqueue(_createAction(
          id: 'action-$i',
          createdAt: DateTime(2024, 1, 1, 0, 0, i),
        ));
      }

      expect(queue.pendingCount, lessThanOrEqualTo(AppConstants.maxOfflineQueueSize));
    });
  });

  group('OfflineActionQueue - getPendingActions', () {
    test('returns empty list when queue is empty', () async {
      final pending = await queue.getPendingActions();
      expect(pending, isEmpty);
    });

    test('returns actions in FIFO order (oldest first)', () async {
      await queue.enqueue(_createAction(
        id: 'oldest',
        createdAt: DateTime(2024, 1, 1),
      ));
      await queue.enqueue(_createAction(
        id: 'middle',
        createdAt: DateTime(2024, 1, 2),
      ));
      await queue.enqueue(_createAction(
        id: 'newest',
        createdAt: DateTime(2024, 1, 3),
      ));

      final pending = await queue.getPendingActions();

      expect(pending[0].id, equals('oldest'));
      expect(pending[1].id, equals('middle'));
      expect(pending[2].id, equals('newest'));
    });
  });

  group('OfflineActionQueue - processQueue', () {
    test('processes actions in FIFO order', () async {
      final executionOrder = <String>[];

      when(() => mockApiClient.post<dynamic>('/path-1', data: null))
          .thenAnswer((_) async {
        executionOrder.add('action-1');
        return Response(
          requestOptions: RequestOptions(path: '/path-1'),
          statusCode: 200,
        );
      });
      when(() => mockApiClient.post<dynamic>('/path-2', data: null))
          .thenAnswer((_) async {
        executionOrder.add('action-2');
        return Response(
          requestOptions: RequestOptions(path: '/path-2'),
          statusCode: 200,
        );
      });
      when(() => mockApiClient.post<dynamic>('/path-3', data: null))
          .thenAnswer((_) async {
        executionOrder.add('action-3');
        return Response(
          requestOptions: RequestOptions(path: '/path-3'),
          statusCode: 200,
        );
      });

      await queue.enqueue(_createAction(
        id: 'action-1',
        path: '/path-1',
        createdAt: DateTime(2024, 1, 1),
      ));
      await queue.enqueue(_createAction(
        id: 'action-2',
        path: '/path-2',
        createdAt: DateTime(2024, 1, 2),
      ));
      await queue.enqueue(_createAction(
        id: 'action-3',
        path: '/path-3',
        createdAt: DateTime(2024, 1, 3),
      ));

      await queue.processQueue();

      expect(executionOrder, equals(['action-1', 'action-2', 'action-3']));
      expect(queue.pendingCount, equals(0));
    });

    test('removes action on successful execution', () async {
      when(() => mockApiClient.get<dynamic>('/test'))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/test'),
                statusCode: 200,
              ));

      await queue.enqueue(_createAction(id: 'success-action', method: 'GET', path: '/test'));
      await queue.processQueue();

      expect(queue.pendingCount, equals(0));
    });

    test('increments retry count on failure', () async {
      when(() => mockApiClient.post<dynamic>('/fail', data: null))
          .thenThrow(DioException(
        requestOptions: RequestOptions(path: '/fail'),
        type: DioExceptionType.connectionTimeout,
      ));

      await queue.enqueue(_createAction(
        id: 'fail-action',
        path: '/fail',
        retryCount: 0,
      ));

      await queue.processQueue();

      // Action should still be in queue with incremented retry
      expect(queue.pendingCount, equals(1));
      final pending = await queue.getPendingActions();
      expect(pending.first.retryCount, equals(1));
    });

    test('removes action and notifies on permanent failure (3 retries exhausted)', () async {
      when(() => mockApiClient.post<dynamic>('/fail', data: null))
          .thenThrow(DioException(
        requestOptions: RequestOptions(path: '/fail'),
        type: DioExceptionType.connectionTimeout,
      ));

      // Action already at max retries - 1 (will be incremented to max)
      await queue.enqueue(_createAction(
        id: 'permanent-fail',
        path: '/fail',
        retryCount: AppConstants.maxOfflineActionRetries - 1,
      ));

      await queue.processQueue();

      // Action should be removed
      expect(queue.pendingCount, equals(0));
      // Permanent failure callback should have been called
      expect(permanentFailures, hasLength(1));
      expect(permanentFailures.first.id, equals('permanent-fail'));
    });

    test('stops processing when connectivity is lost mid-queue', () async {
      var callCount = 0;

      when(() => mockApiClient.post<dynamic>('/path-1', data: null))
          .thenAnswer((_) async {
        callCount++;
        // Simulate connectivity loss after first action
        when(() => mockConnectivityManager.isOnline).thenReturn(false);
        return Response(
          requestOptions: RequestOptions(path: '/path-1'),
          statusCode: 200,
        );
      });

      await queue.enqueue(_createAction(
        id: 'a1',
        path: '/path-1',
        createdAt: DateTime(2024, 1, 1),
      ));
      await queue.enqueue(_createAction(
        id: 'a2',
        path: '/path-2',
        createdAt: DateTime(2024, 1, 2),
      ));

      await queue.processQueue();

      // Only the first action should have been processed
      expect(callCount, equals(1));
      // Second action should still be in queue
      expect(queue.pendingCount, equals(1));
    });

    test('executes correct HTTP method for each action type', () async {
      when(() => mockApiClient.get<dynamic>('/get-path'))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/get-path'),
                statusCode: 200,
              ));
      when(() => mockApiClient.put<dynamic>('/put-path', data: {'key': 'val'}))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/put-path'),
                statusCode: 200,
              ));
      when(() => mockApiClient.patch<dynamic>('/patch-path', data: null))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/patch-path'),
                statusCode: 200,
              ));
      when(() => mockApiClient.delete<dynamic>('/delete-path'))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/delete-path'),
                statusCode: 200,
              ));

      await queue.enqueue(_createAction(
        id: 'get-1',
        method: 'GET',
        path: '/get-path',
        createdAt: DateTime(2024, 1, 1),
      ));
      await queue.enqueue(_createAction(
        id: 'put-1',
        method: 'PUT',
        path: '/put-path',
        data: {'key': 'val'},
        createdAt: DateTime(2024, 1, 2),
      ));
      await queue.enqueue(_createAction(
        id: 'patch-1',
        method: 'PATCH',
        path: '/patch-path',
        createdAt: DateTime(2024, 1, 3),
      ));
      await queue.enqueue(_createAction(
        id: 'delete-1',
        method: 'DELETE',
        path: '/delete-path',
        createdAt: DateTime(2024, 1, 4),
      ));

      await queue.processQueue();

      verify(() => mockApiClient.get<dynamic>('/get-path')).called(1);
      verify(() => mockApiClient.put<dynamic>('/put-path', data: {'key': 'val'})).called(1);
      verify(() => mockApiClient.patch<dynamic>('/patch-path', data: null)).called(1);
      verify(() => mockApiClient.delete<dynamic>('/delete-path')).called(1);
      expect(queue.pendingCount, equals(0));
    });

    test('does not process concurrently (re-entrant guard)', () async {
      final completer = Completer<Response<dynamic>>();

      when(() => mockApiClient.post<dynamic>('/slow', data: null))
          .thenAnswer((_) => completer.future);

      await queue.enqueue(_createAction(id: 'slow-action', path: '/slow'));

      // Start processing (will block on the completer)
      final firstProcess = queue.processQueue();
      // Try to process again immediately
      final secondProcess = queue.processQueue();

      // Complete the action
      completer.complete(Response(
        requestOptions: RequestOptions(path: '/slow'),
        statusCode: 200,
      ));

      await firstProcess;
      await secondProcess;

      // Should only have been called once
      verify(() => mockApiClient.post<dynamic>('/slow', data: null)).called(1);
    });
  });

  group('OfflineActionQueue - removeAction', () {
    test('removes a specific action by id', () async {
      await queue.enqueue(_createAction(id: 'keep'));
      await queue.enqueue(_createAction(id: 'remove'));
      await queue.enqueue(_createAction(id: 'also-keep'));

      await queue.removeAction('remove');

      expect(queue.pendingCount, equals(2));
      final pending = await queue.getPendingActions();
      final ids = pending.map((a) => a.id).toList();
      expect(ids, contains('keep'));
      expect(ids, contains('also-keep'));
      expect(ids, isNot(contains('remove')));
    });

    test('does nothing when action id does not exist', () async {
      await queue.enqueue(_createAction(id: 'existing'));

      await queue.removeAction('non-existent');

      expect(queue.pendingCount, equals(1));
    });
  });

  group('OfflineActionQueue - pendingCount', () {
    test('returns 0 for empty queue', () {
      expect(queue.pendingCount, equals(0));
    });

    test('returns correct count after enqueue', () async {
      await queue.enqueue(_createAction(id: 'a1'));
      await queue.enqueue(_createAction(id: 'a2'));

      expect(queue.pendingCount, equals(2));
    });

    test('returns correct count after removal', () async {
      await queue.enqueue(_createAction(id: 'a1'));
      await queue.enqueue(_createAction(id: 'a2'));
      await queue.removeAction('a1');

      expect(queue.pendingCount, equals(1));
    });
  });

  group('OfflineActionQueue - connectivity listener', () {
    test('processes queue when connectivity is restored', () async {
      when(() => mockApiClient.post<dynamic>('/auto', data: null))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/auto'),
                statusCode: 200,
              ));

      await queue.enqueue(_createAction(id: 'auto-process', path: '/auto'));

      // Simulate connectivity restored
      connectivityController.add(ConnectivityStatus.online);

      // Give the async listener time to process
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(queue.pendingCount, equals(0));
    });

    test('does not process when going offline', () async {
      await queue.enqueue(_createAction(id: 'stay-put'));

      // Simulate going offline
      connectivityController.add(ConnectivityStatus.offline);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Action should still be in queue
      expect(queue.pendingCount, equals(1));
    });

    test('does not process when queue is empty on reconnection', () async {
      // Simulate connectivity restored with empty queue
      connectivityController.add(ConnectivityStatus.online);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      // No errors should occur
      verifyNever(() => mockApiClient.post<dynamic>(any(), data: any(named: 'data')));
    });
  });

  group('OfflineActionQueue - persistence', () {
    test('actions survive queue recreation (Hive persistence)', () async {
      // Enqueue actions
      await queue.enqueue(_createAction(
        id: 'persistent-1',
        createdAt: DateTime(2024, 1, 1),
      ));
      await queue.enqueue(_createAction(
        id: 'persistent-2',
        createdAt: DateTime(2024, 1, 2),
      ));

      // Dispose the queue (simulating app restart)
      queue.dispose();

      // Create a new queue instance with the same box
      final newQueue = HiveOfflineActionQueueImpl(
        apiClient: mockApiClient,
        connectivityManager: mockConnectivityManager,
        box: box,
      );

      // Actions should still be there
      expect(newQueue.pendingCount, equals(2));
      final pending = await newQueue.getPendingActions();
      expect(pending[0].id, equals('persistent-1'));
      expect(pending[1].id, equals('persistent-2'));

      newQueue.dispose();
    });
  });
}
