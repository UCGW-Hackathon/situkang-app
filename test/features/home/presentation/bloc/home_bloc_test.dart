import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:situkang_app/core/constants/enums.dart';
import 'package:situkang_app/core/error/failures.dart';
import 'package:situkang_app/features/home/domain/entities/active_order.dart';
import 'package:situkang_app/features/home/domain/entities/article_item.dart';
import 'package:situkang_app/features/home/domain/entities/category_item.dart';
import 'package:situkang_app/features/home/domain/entities/featured_worker.dart';
import 'package:situkang_app/features/home/domain/entities/home_data.dart';
import 'package:situkang_app/features/home/domain/entities/promo_banner.dart';
import 'package:situkang_app/features/home/domain/repositories/home_repository.dart';
import 'package:situkang_app/features/home/presentation/bloc/home_bloc.dart';
import 'package:situkang_app/features/home/presentation/bloc/home_event.dart';
import 'package:situkang_app/features/home/presentation/bloc/home_state.dart';

// Mocks
class MockHomeRepository extends Mock implements HomeRepository {}

void main() {
  late HomeBloc homeBloc;
  late MockHomeRepository mockHomeRepository;

  setUp(() {
    mockHomeRepository = MockHomeRepository();
    homeBloc = HomeBloc(homeRepository: mockHomeRepository);
  });

  tearDown(() {
    homeBloc.close();
  });

  // Test data
  const tActiveOrder = ActiveOrder(
    orderId: 'order-123',
    status: OrderStatus.onTheWay,
    workerName: 'Pak Budi',
    serviceName: 'Perbaikan AC',
    etaMinutes: 15,
  );

  const tPromos = [
    PromoBanner(
      id: 'promo-1',
      title: 'Diskon 20%',
      description: 'Untuk layanan AC',
      imageUrl: 'https://example.com/promo1.jpg',
      ctaLabel: 'Klaim Sekarang',
    ),
  ];

  const tCategories = [
    CategoryItem(id: 'cat-1', name: 'AC', icon: 'https://example.com/ac.png'),
    CategoryItem(
        id: 'cat-2', name: 'Pipa', icon: 'https://example.com/pipa.png'),
  ];

  const tFeaturedWorkers = [
    FeaturedWorker(
      id: 'worker-1',
      name: 'Pak Budi',
      specialization: 'Spesialis AC',
      avatarUrl: 'https://example.com/avatar1.jpg',
      rating: 4.8,
      distance: 2.5,
      completedJobs: 120,
      isVerified: true,
    ),
  ];

  const tArticles = [
    ArticleItem(
      id: 'article-1',
      title: 'Tips Merawat AC',
      thumbnailUrl: 'https://example.com/article1.jpg',
    ),
  ];

  const tHomeData = HomeData(
    fullName: 'John Doe',
    currentAddress: 'Jl. Sudirman No. 1, Jakarta',
    avatarUrl: 'https://example.com/avatar.jpg',
    activeOrder: tActiveOrder,
    promos: tPromos,
    categories: tCategories,
    featuredWorkers: tFeaturedWorkers,
    articles: tArticles,
  );

  const tHomeDataNoActiveOrder = HomeData(
    fullName: 'John Doe',
    currentAddress: 'Jl. Sudirman No. 1, Jakarta',
    promos: tPromos,
    categories: tCategories,
    featuredWorkers: tFeaturedWorkers,
    articles: tArticles,
  );

  group('HomeBloc', () {
    test('initial state is HomeInitial', () {
      expect(homeBloc.state, const HomeInitial());
    });

    group('FetchHomeData', () {
      blocTest<HomeBloc, HomeState>(
        'emits [HomeLoading, HomeLoaded] when getHomeData succeeds',
        build: () {
          when(() => mockHomeRepository.getHomeData())
              .thenAnswer((_) async => const Right(tHomeData));
          return homeBloc;
        },
        act: (bloc) => bloc.add(const FetchHomeData()),
        expect: () => [
          const HomeLoading(),
          const HomeLoaded(homeData: tHomeData),
        ],
        verify: (_) {
          verify(() => mockHomeRepository.getHomeData()).called(1);
        },
      );

      blocTest<HomeBloc, HomeState>(
        'emits [HomeLoading, HomeLoaded] with active order when user has active order',
        build: () {
          when(() => mockHomeRepository.getHomeData())
              .thenAnswer((_) async => const Right(tHomeData));
          return homeBloc;
        },
        act: (bloc) => bloc.add(const FetchHomeData()),
        expect: () => [
          const HomeLoading(),
          const HomeLoaded(homeData: tHomeData),
        ],
        verify: (_) {
          final state = homeBloc.state as HomeLoaded;
          expect(state.hasActiveOrder, isTrue);
          expect(state.homeData.activeOrder, equals(tActiveOrder));
        },
      );

      blocTest<HomeBloc, HomeState>(
        'emits [HomeLoading, HomeLoaded] without active order when user has no active order',
        build: () {
          when(() => mockHomeRepository.getHomeData())
              .thenAnswer((_) async => const Right(tHomeDataNoActiveOrder));
          return homeBloc;
        },
        act: (bloc) => bloc.add(const FetchHomeData()),
        expect: () => [
          const HomeLoading(),
          const HomeLoaded(homeData: tHomeDataNoActiveOrder),
        ],
        verify: (_) {
          final state = homeBloc.state as HomeLoaded;
          expect(state.hasActiveOrder, isFalse);
          expect(state.homeData.activeOrder, isNull);
        },
      );

      blocTest<HomeBloc, HomeState>(
        'emits [HomeLoading, HomeError] when getHomeData fails with network error',
        build: () {
          when(() => mockHomeRepository.getHomeData())
              .thenAnswer((_) async => const Left(NetworkFailure()));
          return homeBloc;
        },
        act: (bloc) => bloc.add(const FetchHomeData()),
        expect: () => [
          const HomeLoading(),
          const HomeError(failure: NetworkFailure()),
        ],
      );

      blocTest<HomeBloc, HomeState>(
        'emits [HomeLoading, HomeError] when getHomeData fails with server error',
        build: () {
          when(() => mockHomeRepository.getHomeData()).thenAnswer(
            (_) async => const Left(
              ServerFailure('Terjadi kesalahan pada server', statusCode: 500),
            ),
          );
          return homeBloc;
        },
        act: (bloc) => bloc.add(const FetchHomeData()),
        expect: () => [
          const HomeLoading(),
          const HomeError(
            failure:
                ServerFailure('Terjadi kesalahan pada server', statusCode: 500),
          ),
        ],
      );
    });

    group('RefreshHomeData', () {
      blocTest<HomeBloc, HomeState>(
        'emits [HomeLoaded] when refresh succeeds',
        build: () {
          when(() => mockHomeRepository.getHomeData())
              .thenAnswer((_) async => const Right(tHomeData));
          return homeBloc;
        },
        act: (bloc) => bloc.add(const RefreshHomeData()),
        expect: () => [
          const HomeLoaded(homeData: tHomeData),
        ],
      );

      blocTest<HomeBloc, HomeState>(
        'keeps current HomeLoaded state when refresh fails',
        build: () {
          when(() => mockHomeRepository.getHomeData())
              .thenAnswer((_) async => const Left(NetworkFailure()));
          return homeBloc;
        },
        seed: () => const HomeLoaded(homeData: tHomeData),
        act: (bloc) => bloc.add(const RefreshHomeData()),
        expect: () => <HomeState>[],
      );

      blocTest<HomeBloc, HomeState>(
        'emits [HomeError] when refresh fails and no previous data exists',
        build: () {
          when(() => mockHomeRepository.getHomeData())
              .thenAnswer((_) async => const Left(NetworkFailure()));
          return homeBloc;
        },
        act: (bloc) => bloc.add(const RefreshHomeData()),
        expect: () => [
          const HomeError(failure: NetworkFailure()),
        ],
      );
    });
  });
}
