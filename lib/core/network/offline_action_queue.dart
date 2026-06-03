/// Offline action queue for the SITUKANG app.
///
/// Queues failed or offline API actions for later replay when connectivity
/// is restored. Persists actions using Hive so the queue survives app restarts.
///
/// Requirements: 26.1, 26.2, 26.3, 26.7
library;

import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';

import '../constants/app_constants.dart';
import 'api_client.dart';
import 'connectivity_manager.dart';

/// Represents a single queued offline action to be replayed later.
///
/// Each action captures the HTTP method, path, and optional data payload
/// needed to replay the request when connectivity is restored.
class QueuedAction {
  /// Creates a [QueuedAction].
  QueuedAction({
    required this.id,
    required this.method,
    required this.path,
    this.data,
    required this.createdAt,
    this.retryCount = 0,
  });

  /// Creates a [QueuedAction] from a Hive-stored Map.
  factory QueuedAction.fromMap(Map<dynamic, dynamic> map) {
    return QueuedAction(
      id: map['id'] as String,
      method: map['method'] as String,
      path: map['path'] as String,
      data: map['data'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      retryCount: map['retryCount'] as int? ?? 0,
    );
  }

  /// Unique identifier for this action.
  final String id;

  /// HTTP method: GET, POST, PUT, PATCH, DELETE.
  final String method;

  /// API path (relative to base URL).
  final String path;

  /// Optional request body data.
  final dynamic data;

  /// Timestamp when this action was enqueued.
  final DateTime createdAt;

  /// Number of times this action has been retried.
  /// Max retries defined by [AppConstants.maxOfflineActionRetries].
  final int retryCount;

  /// Whether this action has exhausted all retry attempts.
  bool get hasExhaustedRetries =>
      retryCount >= AppConstants.maxOfflineActionRetries;

  /// Creates a copy with an incremented retry count.
  QueuedAction copyWithIncrementedRetry() {
    return QueuedAction(
      id: id,
      method: method,
      path: path,
      data: data,
      createdAt: createdAt,
      retryCount: retryCount + 1,
    );
  }

  /// Serializes this action to a Map for Hive storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'method': method,
      'path': path,
      'data': data,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'retryCount': retryCount,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueuedAction &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'QueuedAction(id: $id, method: $method, path: $path, retryCount: $retryCount)';
}

/// Callback type for notifying about permanent action failures.
///
/// Called when an action has exhausted all retries and is removed from the queue.
typedef OnActionPermanentFailure = void Function(QueuedAction action);

/// Abstract interface for the offline action queue.
///
/// Manages a FIFO queue of API actions that failed due to connectivity issues.
/// Actions are persisted to survive app restarts and replayed in order when
/// connectivity is restored.
///
/// Capacity is limited to [AppConstants.maxOfflineQueueSize] (50) items.
/// When at capacity, the oldest action is evicted (FIFO eviction).
///
/// Each action is retried up to [AppConstants.maxOfflineActionRetries] (3) times.
/// On permanent failure (retries exhausted), the action is removed and the
/// user is notified via [OnActionPermanentFailure] callback.
abstract class OfflineActionQueue {
  /// Adds an action to the queue.
  ///
  /// If the queue is at capacity ([AppConstants.maxOfflineQueueSize]),
  /// the oldest action is evicted before the new one is added.
  Future<void> enqueue(QueuedAction action);

  /// Returns all pending actions in FIFO order (oldest first).
  Future<List<QueuedAction>> getPendingActions();

  /// Processes all pending actions in FIFO order.
  ///
  /// Each action is executed via the API client. On success, the action
  /// is removed. On failure, the retry count is incremented. If retries
  /// are exhausted, the action is removed and the failure callback is invoked.
  ///
  /// Processing stops if connectivity is lost mid-queue.
  Future<void> processQueue();

  /// Removes a specific action from the queue by its [actionId].
  Future<void> removeAction(String actionId);

  /// The number of pending actions currently in the queue.
  ///
  /// Always between 0 and [AppConstants.maxOfflineQueueSize] (50).
  int get pendingCount;

  /// Disposes resources (stream subscriptions, etc.).
  void dispose();
}

/// Hive-based implementation of [OfflineActionQueue].
///
/// Persists queued actions in a Hive box so they survive app restarts.
/// Listens to [ConnectivityManager.statusStream] to automatically process
/// the queue when connectivity is restored.
@LazySingleton(as: OfflineActionQueue)
class HiveOfflineActionQueueImpl implements OfflineActionQueue {
  /// Creates a [HiveOfflineActionQueueImpl].
  ///
  /// [apiClient] is used to replay queued actions.
  /// [connectivityManager] is used to detect when to process the queue.
  /// [onPermanentFailure] is called when an action exhausts all retries.
  HiveOfflineActionQueueImpl({
    required ApiClient apiClient,
    required ConnectivityManager connectivityManager,
    this.onPermanentFailure,
    Box<Map<dynamic, dynamic>>? box,
  })  : _apiClient = apiClient,
        _connectivityManager = connectivityManager,
        _box = box {
    _listenToConnectivity();
  }

  @factoryMethod
  static HiveOfflineActionQueueImpl create(
    ApiClient apiClient,
    ConnectivityManager connectivityManager,
  ) {
    return HiveOfflineActionQueueImpl(
      apiClient: apiClient,
      connectivityManager: connectivityManager,
    );
  }

  final ApiClient _apiClient;
  final ConnectivityManager _connectivityManager;
  Box<Map<dynamic, dynamic>>? _box;
  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;
  bool _isProcessing = false;

  /// Callback invoked when an action permanently fails (retries exhausted).
  final OnActionPermanentFailure? onPermanentFailure;

  /// Hive box name for the offline action queue.
  static const String boxName = 'offline_action_queue';

  /// Initializes the Hive box for the queue.
  ///
  /// Must be called before using any queue operations unless a box
  /// was provided in the constructor (for testing).
  Future<void> init() async {
    _box ??= await Hive.openBox<Map<dynamic, dynamic>>(boxName);
  }

  /// Returns the Hive box, throwing if not initialized.
  Box<Map<dynamic, dynamic>> get _safeBox {
    final box = _box;
    if (box == null) {
      throw StateError(
        'OfflineActionQueue not initialized. Call init() first.',
      );
    }
    return box;
  }

  @override
  Future<void> enqueue(QueuedAction action) async {
    final box = _safeBox;

    // If at capacity, evict the oldest action (FIFO eviction)
    if (box.length >= AppConstants.maxOfflineQueueSize) {
      // Keys are ordered by insertion, so the first key is the oldest
      final oldestKey = box.keys.first;
      await box.delete(oldestKey);
    }

    await box.put(action.id, action.toMap());
  }

  @override
  Future<List<QueuedAction>> getPendingActions() async {
    final box = _safeBox;
    final actions = <QueuedAction>[];

    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw != null) {
        actions.add(QueuedAction.fromMap(raw));
      }
    }

    // Sort by createdAt to ensure FIFO order
    actions.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return actions;
  }

  @override
  Future<void> processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final actions = await getPendingActions();

      for (final action in actions) {
        // Stop processing if connectivity is lost
        if (!_connectivityManager.isOnline) break;

        try {
          await _executeAction(action);
          // Success — remove from queue
          await removeAction(action.id);
        } catch (_) {
          // Failure — increment retry count
          final updated = action.copyWithIncrementedRetry();

          if (updated.hasExhaustedRetries) {
            // Permanent failure — remove and notify
            await removeAction(action.id);
            onPermanentFailure?.call(updated);
          } else {
            // Update the action with incremented retry count
            await _safeBox.put(action.id, updated.toMap());
          }
        }
      }
    } finally {
      _isProcessing = false;
    }
  }

  @override
  Future<void> removeAction(String actionId) async {
    await _safeBox.delete(actionId);
  }

  @override
  int get pendingCount => _safeBox.length;

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  /// Executes a single queued action via the API client.
  Future<void> _executeAction(QueuedAction action) async {
    switch (action.method.toUpperCase()) {
      case 'GET':
        await _apiClient.get<dynamic>(action.path);
      case 'POST':
        await _apiClient.post<dynamic>(action.path, data: action.data);
      case 'PUT':
        await _apiClient.put<dynamic>(action.path, data: action.data);
      case 'PATCH':
        await _apiClient.patch<dynamic>(action.path, data: action.data);
      case 'DELETE':
        await _apiClient.delete<dynamic>(action.path);
      default:
        throw ArgumentError('Unsupported HTTP method: ${action.method}');
    }
  }

  /// Listens to connectivity changes and processes the queue on reconnection.
  void _listenToConnectivity() {
    _connectivitySubscription =
        _connectivityManager.statusStream.listen((status) {
      if (status == ConnectivityStatus.online && pendingCount > 0) {
        processQueue();
      }
    });
  }
}
