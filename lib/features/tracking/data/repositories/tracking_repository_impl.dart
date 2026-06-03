import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import 'package:injectable/injectable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/connectivity_manager.dart';
import '../../../../core/network/websocket_manager.dart'
    show ConnectionState, WebSocketManager;
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/timeline_entry.dart';
import '../../domain/entities/worker_location.dart';
import '../../domain/repositories/tracking_repository.dart';
import '../datasources/tracking_remote_data_source.dart';
import '../datasources/tracking_websocket_data_source.dart';

/// Implementation of [TrackingRepository] combining WebSocket and REST.
///
/// Uses WebSocket as the primary data source for real-time location and
/// status updates. Falls back to REST polling every 10 seconds when the
/// WebSocket connection is lost.
///
/// Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.8
@LazySingleton(as: TrackingRepository)
class TrackingRepositoryImpl implements TrackingRepository {
  TrackingRepositoryImpl({
    required this.remoteDataSource,
    required this.webSocketDataSource,
    required this.webSocketManager,
    required this.tokenStorage,
    required this.connectivityManager,
  });

  final TrackingRemoteDataSource remoteDataSource;
  final TrackingWebSocketDataSource webSocketDataSource;
  final WebSocketManager webSocketManager;
  final TokenStorage tokenStorage;
  final ConnectivityManager connectivityManager;

  final StreamController<WorkerLocation> _locationController =
      StreamController<WorkerLocation>.broadcast();
  final StreamController<OrderStatus> _statusController =
      StreamController<OrderStatus>.broadcast();

  StreamSubscription<WorkerLocation>? _wsLocationSubscription;
  StreamSubscription<OrderStatus>? _wsStatusSubscription;
  StreamSubscription<ConnectionState>? _connectionStateSubscription;

  Timer? _pollingTimer;
  String? _currentOrderId;
  bool _isTracking = false;

  @override
  Stream<WorkerLocation> get locationStream => _locationController.stream;

  @override
  Stream<OrderStatus> get statusStream => _statusController.stream;

  @override
  Future<Result<void>> startTracking(String orderId) async {
    try {
      _currentOrderId = orderId;
      _isTracking = true;

      // Get token for WebSocket authentication
      final token = await tokenStorage.getAccessToken();
      if (token == null) {
        return const Left(AuthFailure(
          'Sesi telah berakhir, silakan login kembali',
          errorCode: 'NO_ACCESS_TOKEN',
        ));
      }

      // Connect WebSocket for real-time updates
      await webSocketDataSource.connect(orderId, token);

      // Subscribe to WebSocket location updates
      await _wsLocationSubscription?.cancel();
      _wsLocationSubscription =
          webSocketDataSource.locationStream.listen((location) {
        if (!_locationController.isClosed) {
          _locationController.add(location);
        }
      });

      // Subscribe to WebSocket status updates
      await _wsStatusSubscription?.cancel();
      _wsStatusSubscription =
          webSocketDataSource.statusStream.listen((status) {
        if (!_statusController.isClosed) {
          _statusController.add(status);
        }
      });

      // Monitor connection state for fallback polling
      await _connectionStateSubscription?.cancel();
      _connectionStateSubscription =
          webSocketManager.connectionStateStream.listen(_onConnectionStateChanged);

      return const Right(null);
    } on Exception catch (e) {
      // If WebSocket connection fails, start polling immediately
      _startPolling(orderId);
      return Left(WebSocketFailure(
        'Gagal terhubung ke tracking real-time: $e',
      ));
    }
  }

  @override
  Future<Result<void>> stopTracking(String orderId) async {
    try {
      _isTracking = false;
      _currentOrderId = null;

      // Stop polling
      _stopPolling();

      // Cancel subscriptions
      await _wsLocationSubscription?.cancel();
      _wsLocationSubscription = null;
      await _wsStatusSubscription?.cancel();
      _wsStatusSubscription = null;
      await _connectionStateSubscription?.cancel();
      _connectionStateSubscription = null;

      // Disconnect WebSocket
      await webSocketDataSource.disconnect();

      return const Right(null);
    } on Exception catch (e) {
      return Left(WebSocketFailure(
        'Gagal menghentikan tracking: $e',
      ));
    }
  }

  @override
  Future<Result<WorkerLocation>> getLocationFallback(String orderId) async {
    try {
      final locationModel =
          await remoteDataSource.getWorkerLocation(orderId);
      return Right(locationModel.toEntity());
    } on DioException catch (e) {
      return Left(_mapDioException(e));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Result<List<TimelineEntry>>> getTrackingTimeline(
      String orderId) async {
    try {
      final timelineModels =
          await remoteDataSource.getTrackingTimeline(orderId);
      final entries = timelineModels.map((m) => m.toEntity()).toList();
      return Right(entries);
    } on DioException catch (e) {
      return Left(_mapDioException(e));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString(), statusCode: 500));
    }
  }

  /// Handles WebSocket connection state changes.
  ///
  /// Starts polling when disconnected/reconnecting, stops when connected.
  void _onConnectionStateChanged(ConnectionState state) {
    if (!_isTracking || _currentOrderId == null) return;

    switch (state) {
      case ConnectionState.connected:
        // WebSocket reconnected, stop polling
        _stopPolling();
      case ConnectionState.disconnected:
      case ConnectionState.reconnecting:
        // WebSocket lost, start fallback polling
        _startPolling(_currentOrderId!);
      case ConnectionState.connecting:
        // Still connecting, do nothing
        break;
    }
  }

  /// Starts REST polling for location updates every 10 seconds.
  ///
  /// Requirement: 9.8 — Fall back to polling every 10 seconds on disconnect.
  void _startPolling(String orderId) {
    if (_pollingTimer?.isActive ?? false) return;

    _pollingTimer = Timer.periodic(
      AppConstants.trackingPollInterval,
      (_) => _pollLocation(orderId),
    );

    // Also poll immediately
    _pollLocation(orderId);
  }

  /// Stops the REST polling timer.
  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Polls the REST endpoint for the worker's current location.
  Future<void> _pollLocation(String orderId) async {
    if (!_isTracking) return;

    final result = await getLocationFallback(orderId);
    result.fold(
      (_) {}, // Silently ignore polling errors
      (location) {
        if (!_locationController.isClosed) {
          _locationController.add(location);
        }
      },
    );
  }

  /// Maps a [DioException] to the appropriate [Failure] type.
  Failure _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutFailure();
      case DioExceptionType.connectionError:
        return const NetworkFailure();
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode ?? 0;
        final data = e.response?.data as Map<String, dynamic>?;
        final message =
            data?['message'] as String? ?? 'Terjadi kesalahan';
        return ServerFailure(message, statusCode: statusCode);
      default:
        return const NetworkFailure();
    }
  }

  /// Releases all resources. Call when this repository is no longer needed.
  Future<void> dispose() async {
    _isTracking = false;
    _stopPolling();
    await _wsLocationSubscription?.cancel();
    await _wsStatusSubscription?.cancel();
    await _connectionStateSubscription?.cancel();
    await _locationController.close();
    await _statusController.close();
  }
}
