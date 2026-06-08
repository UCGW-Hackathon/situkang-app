import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:situkang_app/core/error/failures.dart';
import 'package:situkang_app/features/home/data/datasources/home_local_data_source.dart';
import 'package:situkang_app/features/home/data/datasources/home_remote_data_source.dart';
import 'package:situkang_app/features/home/data/models/home_data_model.dart';
import 'package:situkang_app/features/home/data/repositories/home_repository_impl.dart';

class MockHomeRemoteDataSource extends Mock implements HomeRemoteDataSource {}

class MockHomeLocalDataSource extends Mock implements HomeLocalDataSource {}

void main() {
  late HomeRepositoryImpl repository;
  late MockHomeRemoteDataSource mockRemoteDataSource;
  late MockHomeLocalDataSource mockLocalDataSource;

  setUp(() {
    mockRemoteDataSource = MockHomeRemoteDataSource();
    mockLocalDataSource = MockHomeLocalDataSource();
    repository = HomeRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
    );
  });

  final tHomeDataModel = HomeDataModel.fromJson(const {
    'user_summary': {
      'full_name': 'Budi',
      'current_address': 'Jl. Merdeka No. 12',
      'avatar_url': 'https://example.com/avatar.jpg',
    },
    'active_order': {
      'order_id': 'ord-001',
      'status': 'in_progress',
      'worker_name': 'Ahmad',
      'service_name': 'Perbaikan Pipa',
      'eta_minutes': 8,
    },
    'promotions': [
      {
        'promo_id': 'promo-001',
        'title': 'Diskon 20%',
        'description': 'Berlaku hingga 31 Oktober',
        'image_url': 'https://example.com/promo.jpg',
        'cta_label': 'Klaim Sekarang',
      },
    ],
    'service_categories': [
      {
        'category_id': 'cat-01',
        'name': 'AC',
        'icon_url': 'https://example.com/ac.png',
        'slug': 'ac',
      },
    ],
    'featured_workers': [
      {
        'worker_id': 'w-001',
        'full_name': 'Ahmad Jaelani',
        'specialization': 'Spesialis AC',
        'avatar_url': 'https://example.com/ahmad.jpg',
        'rating': 4.9,
        'distance_km': 1.2,
        'completed_jobs': 150,
        'is_verified': true,
      },
    ],
    'articles': [
      {
        'article_id': 'art-001',
        'title': 'Tips Merawat Atap',
        'thumbnail_url': 'https://example.com/article.jpg',
      },
    ],
  });

  group('getHomeData', () {
    test('should return HomeData from remote when API call succeeds', () async {
      // Arrange
      when(() => mockRemoteDataSource.getHomeData())
          .thenAnswer((_) async => tHomeDataModel);
      when(() => mockLocalDataSource.cacheHomeData(tHomeDataModel))
          .thenAnswer((_) async {});

      // Act
      final result = await repository.getHomeData();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected Right but got Left: $failure'),
        (homeData) {
          expect(homeData.fullName, 'Budi');
          expect(homeData.currentAddress, 'Jl. Merdeka No. 12');
          expect(homeData.activeOrder, isNotNull);
          expect(homeData.activeOrder!.orderId, 'ord-001');
          expect(homeData.promos.length, 1);
          expect(homeData.categories.length, 1);
          expect(homeData.featuredWorkers.length, 1);
          expect(homeData.articles.length, 1);
        },
      );
      verify(() => mockRemoteDataSource.getHomeData()).called(1);
      verify(() => mockLocalDataSource.cacheHomeData(tHomeDataModel)).called(1);
    });

    test('should cache data after successful remote fetch', () async {
      // Arrange
      when(() => mockRemoteDataSource.getHomeData())
          .thenAnswer((_) async => tHomeDataModel);
      when(() => mockLocalDataSource.cacheHomeData(tHomeDataModel))
          .thenAnswer((_) async {});

      // Act
      await repository.getHomeData();

      // Assert
      verify(() => mockLocalDataSource.cacheHomeData(tHomeDataModel)).called(1);
    });

    test(
        'should return cached data when remote call fails with connection error',
        () async {
      // Arrange
      when(() => mockRemoteDataSource.getHomeData()).thenThrow(
        DioException(
          type: DioExceptionType.connectionError,
          requestOptions: RequestOptions(path: '/home'),
        ),
      );
      when(() => mockLocalDataSource.getCachedHomeData())
          .thenAnswer((_) async => tHomeDataModel);

      // Act
      final result = await repository.getHomeData();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected Right but got Left: $failure'),
        (homeData) {
          expect(homeData.fullName, 'Budi');
        },
      );
    });

    test(
        'should return NetworkFailure when remote fails and no cached data',
        () async {
      // Arrange
      when(() => mockRemoteDataSource.getHomeData()).thenThrow(
        DioException(
          type: DioExceptionType.connectionError,
          requestOptions: RequestOptions(path: '/home'),
        ),
      );
      when(() => mockLocalDataSource.getCachedHomeData())
          .thenAnswer((_) async => null);

      // Act
      final result = await repository.getHomeData();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Expected Left but got Right'),
      );
    });

    test('should return TimeoutFailure on connection timeout', () async {
      // Arrange
      when(() => mockRemoteDataSource.getHomeData()).thenThrow(
        DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(path: '/home'),
        ),
      );
      when(() => mockLocalDataSource.getCachedHomeData())
          .thenAnswer((_) async => null);

      // Act
      final result = await repository.getHomeData();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<TimeoutFailure>()),
        (_) => fail('Expected Left but got Right'),
      );
    });

    test('should return ServerFailure on 500 error with no cache', () async {
      // Arrange
      when(() => mockRemoteDataSource.getHomeData()).thenThrow(
        DioException(
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 500,
            data: {'message': 'Internal Server Error'},
            requestOptions: RequestOptions(path: '/home'),
          ),
          requestOptions: RequestOptions(path: '/home'),
        ),
      );
      when(() => mockLocalDataSource.getCachedHomeData())
          .thenAnswer((_) async => null);

      // Act
      final result = await repository.getHomeData();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect((failure as ServerFailure).statusCode, 500);
        },
        (_) => fail('Expected Left but got Right'),
      );
    });

    test('should return AuthFailure on 401 error with no cache', () async {
      // Arrange
      when(() => mockRemoteDataSource.getHomeData()).thenThrow(
        DioException(
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 401,
            data: {'message': 'Unauthorized'},
            requestOptions: RequestOptions(path: '/home'),
          ),
          requestOptions: RequestOptions(path: '/home'),
        ),
      );
      when(() => mockLocalDataSource.getCachedHomeData())
          .thenAnswer((_) async => null);

      // Act
      final result = await repository.getHomeData();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<AuthFailure>()),
        (_) => fail('Expected Left but got Right'),
      );
    });

    test('should handle null active_order in response', () async {
      // Arrange
      final noActiveOrderModel = HomeDataModel.fromJson(const {
        'user_summary': {
          'full_name': 'Budi',
          'current_address': 'Jl. Merdeka No. 12',
        },
        'active_order': null,
        'promotions': [],
        'service_categories': [],
        'featured_workers': [],
        'articles': [],
      });

      when(() => mockRemoteDataSource.getHomeData())
          .thenAnswer((_) async => noActiveOrderModel);
      when(() => mockLocalDataSource.cacheHomeData(noActiveOrderModel))
          .thenAnswer((_) async {});

      // Act
      final result = await repository.getHomeData();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected Right but got Left: $failure'),
        (homeData) {
          expect(homeData.activeOrder, isNull);
          expect(homeData.promos, isEmpty);
          expect(homeData.categories, isEmpty);
          expect(homeData.featuredWorkers, isEmpty);
          expect(homeData.articles, isEmpty);
        },
      );
    });
  });
}
