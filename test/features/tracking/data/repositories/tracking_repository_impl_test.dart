import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:situkang_app/core/constants/enums.dart';
import 'package:situkang_app/core/error/failures.dart';
import 'package:situkang_app/core/network/connectivity_manager.dart';
import 'package:situkang_app/core/network/websocket_manager.dart'
    show ConnectionState, WebSocketManager;
import 'package:situkang_app/core/storage/token_storage.dart';
import 'package:situkang_app/features/tracking/data/datasources/tracking_remote_data_source.dart';
import 'package:situkang_app/features/tracking/data/datasources/tracking_websocket_data_source.dart';
import 'package:situkang_app/features/tracking/data/models/timeline_entry_model.dart';
import 'package:situkang_app/features/tracking/data/models/worker_location_model.dart';
import 'package:situkang_app/features/tracking/data/repositories/tracking_repository_impl.dart';
import 'package:situkang_app/features/tracking/domain/entities/worker_location.dart';

// Mocks
class MockTrackingRemoteDataSource extends Mock
    implements TrackingRemoteDataSource {}

class MockTrackingWebSocketDataSource extends Mock
    implements TrackingWebSocketDataSource {}

class MockWebSocketManager extends Mock implements WebSocketManager {}

class MockTokenStorage extends Mock implements TokenStorage {}

class MockConnectivityManager extends Mock implements ConnectivityManager {}

void main() {
  late TrackingRepositoryImpl repository;
  late MockTrackingRemoteDataSource mockRemoteDataSource;
  late MockTrackingWebSocketDataSource mockWebSocketDataSource;
  late MockWebSocketManager mockWebSocketManager;
  late MockTokenStorage mockTokenStorage;
  late MockConnectivityManager mockConnectivityManager;

  late StreamController<WorkerLocation> wsLocationController;
  late StreamController<OrderStatus> wsStatusController;
  late StreamController<ConnectionState> connectionStateController;

  setUp(() {
    mockRemoteDataSource = MockTrackingRemoteDataSource();
    mockWebSocketDataSource = MockTrackingWebSocketDataSource();
    mockWebSocketManager = MockWebSocketManager();
    mockTokenStorage = MockTokenStorage();
    mockConnectivityManager = MockConnectivityManager();

    wsLocationController = StreamController<WorkerLocation>.broadcast();
    wsStatusController = StreamController<OrderStatus>.broadcast();
    connectionStateController = StreamController<ConnectionState>.broadcast();

    when(() => mockWebSocketDataSource.locationStream)
        .thenAnswer((_) => wsLocationController.stream);
    when(() => mockWebSocketDataSource.statusStream)
        .thenAnswer((_) => wsStatusController.stream);
    when(() => mockWebSocketManager.connectionStateStream)
        .thenAnswer((_) => connectionStateController.stream);

    repository = TrackingRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      webSocketDataSource: mockWebSocketDataSource,
      webSocketManager: mockWebSocketManager,
      tokenStorage: mockTokenStorage,
      connectivityManager: mockConnectivityManager,
    );
  });

  tearDown(() async {
    await wsLocationController.close();
    await wsStatusController.close();
    await connectionStateController.close();
    await repository.dispose();
  });

  // Test data
  const tOrderId = 'order-123';
  const tToken = 'access-token-abc';

  const tWorkerLocationModel = WorkerLocationModel(
    latitude: -6.2088,
    longitude: 106.8456,
    heading: 90.0,
    speed: 5.5,
    accuracy: 10.0,
    eta: 8,
  );

  final tTimelineEntryModels = [
    TimelineEntryModel(
      status: OrderStatus.accepted,
      title: 'Diterima',
      description: 'Pesanan diterima oleh tukang',
      timestamp: DateTime(2024, 1, 1, 10, 0),
      isCompleted: true,
    ),
    const TimelineEntryModel(
      status: OrderStatus.onTheWay,
      title: 'Dalam Perjalanan',
      description: 'Tukang sedang menuju lokasi Anda',
      isCompleted: false,
    ),
  ];

  group('startTracking', () {
    test('should connect WebSocket and return success when token is available',
        () async {
      // Arrange
      when(() => mockTokenStorage.getAccessToken())
          .thenAnswer((_) async => tToken);
      when(() => mockWebSocketDataSource.connect(any(), any()))
          .thenAnswer((_) async {});

      // Act
      final result = await repository.startTracking(tOrderId);

      // Assert
      expect(result.isRight(), true);
      verify(() => mockTokenStorage.getAccessToken()).called(1);
      verify(() => mockWebSocketDataSource.connect(tOrderId, tToken)).called(1);
    });

    test('should return AuthFailure when no access token is available',
        () async {
      // Arrange
      when(() => mockTokenStorage.getAccessToken())
          .thenAnswer((_) async => null);

      // Act
      final result = await repository.startTracking(tOrderId);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<AuthFailure>());
          expect((failure as AuthFailure).errorCode, 'NO_ACCESS_TOKEN');
        },
        (_) => fail('Should be Left'),
      );
      verifyNever(() => mockWebSocketDataSource.connect(any(), any()));
    });

    test('should return WebSocketFailure and start polling when connection fails',
        () async {
      // Arrange
      when(() => mockTokenStorage.getAccessToken())
          .thenAnswer((_) async => tToken);
      when(() => mockWebSocketDataSource.connect(any(), any()))
          .thenThrow(Exception('Connection refused'));
      when(() => mockRemoteDataSource.getWorkerLocation(any()))
          .thenAnswer((_) async => tWorkerLocationModel);

      // Act
      final result = await repository.startTracking(tOrderId);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<WebSocketFailure>()),
        (_) => fail('Should be Left'),
      );
    });
  });

  group('stopTracking', () {
    test('should disconnect WebSocket and return success', () async {
      // Arrange
      when(() => mockWebSocketDataSource.disconnect())
          .thenAnswer((_) async {});

      // Act
      final result = await repository.stopTracking(tOrderId);

      // Assert
      expect(result.isRight(), true);
      verify(() => mockWebSocketDataSource.disconnect()).called(1);
    });
  });

  group('getLocationFallback', () {
    test('should return WorkerLocation on success', () async {
      // Arrange
      when(() => mockRemoteDataSource.getWorkerLocation(any()))
          .thenAnswer((_) async => tWorkerLocationModel);

      // Act
      final result = await repository.getLocationFallback(tOrderId);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should be Right'),
        (location) {
          expect(location.latitude, -6.2088);
          expect(location.longitude, 106.8456);
          expect(location.heading, 90.0);
          expect(location.speed, 5.5);
          expect(location.accuracy, 10.0);
          expect(location.eta, 8);
        },
      );
    });

    test('should return NetworkFailure on connection error', () async {
      // Arrange
      when(() => mockRemoteDataSource.getWorkerLocation(any()))
          .thenThrow(DioException(
        requestOptions: RequestOptions(path: '/orders/order-123/tracking/location'),
        type: DioExceptionType.connectionError,
      ));

      // Act
      final result = await repository.getLocationFallback(tOrderId);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Should be Left'),
      );
    });

    test('should return TimeoutFailure on timeout', () async {
      // Arrange
      when(() => mockRemoteDataSource.getWorkerLocation(any()))
          .thenThrow(DioException(
        requestOptions: RequestOptions(path: '/orders/order-123/tracking/location'),
        type: DioExceptionType.connectionTimeout,
      ));

      // Act
      final result = await repository.getLocationFallback(tOrderId);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<TimeoutFailure>()),
        (_) => fail('Should be Left'),
      );
    });

    test('should return ServerFailure on bad response', () async {
      // Arrange
      when(() => mockRemoteDataSource.getWorkerLocation(any()))
          .thenThrow(DioException(
        requestOptions: RequestOptions(path: '/orders/order-123/tracking/location'),
        response: Response(
          requestOptions: RequestOptions(path: '/orders/order-123/tracking/location'),
          statusCode: 404,
          data: {'message': 'Order not found'},
        ),
        type: DioExceptionType.badResponse,
      ));

      // Act
      final result = await repository.getLocationFallback(tOrderId);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect((failure as ServerFailure).statusCode, 404);
        },
        (_) => fail('Should be Left'),
      );
    });
  });

  group('getTrackingTimeline', () {
    test('should return list of TimelineEntry on success', () async {
      // Arrange
      when(() => mockRemoteDataSource.getTrackingTimeline(any()))
          .thenAnswer((_) async => tTimelineEntryModels);

      // Act
      final result = await repository.getTrackingTimeline(tOrderId);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should be Right'),
        (entries) {
          expect(entries.length, 2);
          expect(entries[0].status, OrderStatus.accepted);
          expect(entries[0].title, 'Diterima');
          expect(entries[0].isCompleted, true);
          expect(entries[1].status, OrderStatus.onTheWay);
          expect(entries[1].isCompleted, false);
        },
      );
    });

    test('should return NetworkFailure on connection error', () async {
      // Arrange
      when(() => mockRemoteDataSource.getTrackingTimeline(any()))
          .thenThrow(DioException(
        requestOptions: RequestOptions(path: '/orders/order-123/tracking'),
        type: DioExceptionType.connectionError,
      ));

      // Act
      final result = await repository.getTrackingTimeline(tOrderId);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Should be Left'),
      );
    });
  });

  group('locationStream', () {
    test('should emit WorkerLocation when WebSocket sends location update',
        () async {
      // Arrange
      when(() => mockTokenStorage.getAccessToken())
          .thenAnswer((_) async => tToken);
      when(() => mockWebSocketDataSource.connect(any(), any()))
          .thenAnswer((_) async {});

      await repository.startTracking(tOrderId);

      const tLocation = WorkerLocation(
        latitude: -6.2088,
        longitude: 106.8456,
        heading: 45.0,
        eta: 5,
      );

      // Act & Assert
      expectLater(
        repository.locationStream,
        emits(tLocation),
      );

      wsLocationController.add(tLocation);
    });
  });

  group('statusStream', () {
    test('should emit OrderStatus when WebSocket sends status change',
        () async {
      // Arrange
      when(() => mockTokenStorage.getAccessToken())
          .thenAnswer((_) async => tToken);
      when(() => mockWebSocketDataSource.connect(any(), any()))
          .thenAnswer((_) async {});

      await repository.startTracking(tOrderId);

      // Act & Assert
      expectLater(
        repository.statusStream,
        emits(OrderStatus.arrived),
      );

      wsStatusController.add(OrderStatus.arrived);
    });
  });
}
