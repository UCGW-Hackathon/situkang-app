import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:situkang_app/core/error/failures.dart';
import 'package:situkang_app/core/network/api_response.dart';
import 'package:situkang_app/features/workers/domain/entities/worker_filter.dart';
import 'package:situkang_app/features/workers/domain/entities/worker_list_result.dart';
import 'package:situkang_app/features/workers/domain/entities/worker_profile.dart';
import 'package:situkang_app/features/workers/domain/repositories/worker_repository.dart';
import 'package:situkang_app/features/workers/presentation/bloc/worker_list_bloc.dart';

// Mocks
class MockWorkerRepository extends Mock implements WorkerRepository {}

void main() {
  late WorkerListBloc bloc;
  late MockWorkerRepository mockRepository;

  setUp(() {
    mockRepository = MockWorkerRepository();
    bloc = WorkerListBloc(workerRepository: mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  // Test data
  final tWorkers = List.generate(
    10,
    (i) => WorkerProfile(
      id: 'worker-$i',
      userId: 'user-$i',
      fullName: 'Worker $i',
      ratingAvg: 4.0 + (i * 0.1),
      totalReviews: 10 + i,
      completedJobs: 20 + i,
      isAvailable: true,
      specialization: 'Tukang Listrik',
      basePrice: 50000 + (i * 10000),
      distance: 1.0 + (i * 0.5),
    ),
  );

  final tWorkerListResult = WorkerListResult(
    workers: tWorkers,
    paginationMeta: const PaginationMeta(
      currentPage: 1,
      perPage: 10,
      total: 25,
      totalPages: 3,
    ),
  );

  final tWorkerListResultPage2 = WorkerListResult(
    workers: List.generate(
      10,
      (i) => WorkerProfile(
        id: 'worker-page2-$i',
        userId: 'user-page2-$i',
        fullName: 'Worker Page2 $i',
        ratingAvg: 3.5,
        totalReviews: 5,
        completedJobs: 10,
        isAvailable: true,
        distance: 5.0 + i,
      ),
    ),
    paginationMeta: const PaginationMeta(
      currentPage: 2,
      perPage: 10,
      total: 25,
      totalPages: 3,
    ),
  );

  const tEmptyResult = WorkerListResult(
    workers: [],
    paginationMeta: PaginationMeta(
      currentPage: 1,
      perPage: 10,
      total: 0,
      totalPages: 0,
    ),
  );

  final tLastPageResult = WorkerListResult(
    workers: tWorkers.sublist(0, 5),
    paginationMeta: const PaginationMeta(
      currentPage: 3,
      perPage: 10,
      total: 25,
      totalPages: 3,
    ),
  );

  // Register fallback values
  setUpAll(() {
    registerFallbackValue(const WorkerFilter());
  });

  group('WorkerListBloc', () {
    test('initial state is WorkerListInitial', () {
      expect(bloc.state, const WorkerListInitial());
    });

    group('FetchWorkers', () {
      blocTest<WorkerListBloc, WorkerListState>(
        'emits [WorkerListLoading, WorkerListLoaded] when fetch succeeds',
        build: () {
          when(() => mockRepository.getNearbyWorkers(
                filter: any(named: 'filter'),
                page: any(named: 'page'),
                perPage: any(named: 'perPage'),
              )).thenAnswer((_) async => Right(tWorkerListResult));
          return bloc;
        },
        act: (bloc) => bloc.add(const FetchWorkers()),
        expect: () => [
          const WorkerListLoading(),
          WorkerListLoaded(
            workers: tWorkers,
            filter: const WorkerFilter(),
            hasMore: true,
          ),
        ],
        verify: (_) {
          verify(() => mockRepository.getNearbyWorkers(
                filter: const WorkerFilter(),
              )).called(1);
        },
      );

      blocTest<WorkerListBloc, WorkerListState>(
        'emits [WorkerListLoading, WorkerListError] when fetch fails',
        build: () {
          when(() => mockRepository.getNearbyWorkers(
                filter: any(named: 'filter'),
                page: any(named: 'page'),
                perPage: any(named: 'perPage'),
              )).thenAnswer(
            (_) async => const Left(NetworkFailure()),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const FetchWorkers()),
        expect: () => [
          const WorkerListLoading(),
          const WorkerListError(failure: NetworkFailure()),
        ],
      );

      blocTest<WorkerListBloc, WorkerListState>(
        'emits [WorkerListLoading, WorkerListLoaded] with empty list when no workers found',
        build: () {
          when(() => mockRepository.getNearbyWorkers(
                filter: any(named: 'filter'),
                page: any(named: 'page'),
                perPage: any(named: 'perPage'),
              )).thenAnswer((_) async => const Right(tEmptyResult));
          return bloc;
        },
        act: (bloc) => bloc.add(const FetchWorkers()),
        expect: () => [
          const WorkerListLoading(),
          const WorkerListLoaded(
            workers: [],
            filter: WorkerFilter(),
            hasMore: false,
          ),
        ],
      );

      blocTest<WorkerListBloc, WorkerListState>(
        'emits [WorkerListLoading, WorkerListError] for location unavailable',
        build: () {
          when(() => mockRepository.getNearbyWorkers(
                filter: any(named: 'filter'),
                page: any(named: 'page'),
                perPage: any(named: 'perPage'),
              )).thenAnswer(
            (_) async => const Left(
              ServerFailure('Lokasi tidak tersedia', statusCode: 400),
            ),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const FetchWorkers()),
        expect: () => [
          const WorkerListLoading(),
          const WorkerListError(
            failure: ServerFailure('Lokasi tidak tersedia', statusCode: 400),
          ),
        ],
      );
    });

    group('ApplyFilter', () {
      blocTest<WorkerListBloc, WorkerListState>(
        'emits [WorkerListLoading, WorkerListLoaded] with category filter applied',
        build: () {
          when(() => mockRepository.getNearbyWorkers(
                filter: any(named: 'filter'),
                page: any(named: 'page'),
                perPage: any(named: 'perPage'),
              )).thenAnswer((_) async => Right(tWorkerListResult));
          return bloc;
        },
        act: (bloc) => bloc.add(
          const ApplyFilter(filter: WorkerFilter(categoryId: 'listrik')),
        ),
        expect: () => [
          const WorkerListLoading(),
          WorkerListLoaded(
            workers: tWorkers,
            filter: const WorkerFilter(categoryId: 'listrik'),
            hasMore: true,
          ),
        ],
        verify: (_) {
          verify(() => mockRepository.getNearbyWorkers(
                filter: const WorkerFilter(categoryId: 'listrik'),
              )).called(1);
        },
      );

      blocTest<WorkerListBloc, WorkerListState>(
        'emits [WorkerListLoading, WorkerListLoaded] with min rating filter applied',
        build: () {
          when(() => mockRepository.getNearbyWorkers(
                filter: any(named: 'filter'),
                page: any(named: 'page'),
                perPage: any(named: 'perPage'),
              )).thenAnswer((_) async => Right(tWorkerListResult));
          return bloc;
        },
        act: (bloc) => bloc.add(
          const ApplyFilter(filter: WorkerFilter(minRating: 4.0)),
        ),
        expect: () => [
          const WorkerListLoading(),
          WorkerListLoaded(
            workers: tWorkers,
            filter: const WorkerFilter(minRating: 4.0),
            hasMore: true,
          ),
        ],
      );
    });

    group('ChangeSort', () {
      blocTest<WorkerListBloc, WorkerListState>(
        'emits [WorkerListLoading, WorkerListLoaded] with rating sort',
        build: () {
          when(() => mockRepository.getNearbyWorkers(
                filter: any(named: 'filter'),
                page: any(named: 'page'),
                perPage: any(named: 'perPage'),
              )).thenAnswer((_) async => Right(tWorkerListResult));
          return bloc;
        },
        act: (bloc) => bloc.add(
          const ChangeSort(sortBy: WorkerSortBy.rating),
        ),
        expect: () => [
          const WorkerListLoading(),
          WorkerListLoaded(
            workers: tWorkers,
            filter: const WorkerFilter(sortBy: WorkerSortBy.rating),
            hasMore: true,
          ),
        ],
        verify: (_) {
          verify(() => mockRepository.getNearbyWorkers(
                filter: const WorkerFilter(sortBy: WorkerSortBy.rating),
              )).called(1);
        },
      );

      blocTest<WorkerListBloc, WorkerListState>(
        'emits [WorkerListLoading, WorkerListLoaded] with price sort',
        build: () {
          when(() => mockRepository.getNearbyWorkers(
                filter: any(named: 'filter'),
                page: any(named: 'page'),
                perPage: any(named: 'perPage'),
              )).thenAnswer((_) async => Right(tWorkerListResult));
          return bloc;
        },
        act: (bloc) => bloc.add(
          const ChangeSort(sortBy: WorkerSortBy.price),
        ),
        expect: () => [
          const WorkerListLoading(),
          WorkerListLoaded(
            workers: tWorkers,
            filter: const WorkerFilter(sortBy: WorkerSortBy.price),
            hasMore: true,
          ),
        ],
      );

      blocTest<WorkerListBloc, WorkerListState>(
        'emits [WorkerListLoading, WorkerListLoaded] with completedJobs sort',
        build: () {
          when(() => mockRepository.getNearbyWorkers(
                filter: any(named: 'filter'),
                page: any(named: 'page'),
                perPage: any(named: 'perPage'),
              )).thenAnswer((_) async => Right(tWorkerListResult));
          return bloc;
        },
        act: (bloc) => bloc.add(
          const ChangeSort(sortBy: WorkerSortBy.completedJobs),
        ),
        expect: () => [
          const WorkerListLoading(),
          WorkerListLoaded(
            workers: tWorkers,
            filter: const WorkerFilter(sortBy: WorkerSortBy.completedJobs),
            hasMore: true,
          ),
        ],
      );
    });

    group('SearchWorkers', () {
      blocTest<WorkerListBloc, WorkerListState>(
        'emits [WorkerListLoading, WorkerListLoaded] with search keyword',
        build: () {
          when(() => mockRepository.getNearbyWorkers(
                filter: any(named: 'filter'),
                page: any(named: 'page'),
                perPage: any(named: 'perPage'),
              )).thenAnswer((_) async => Right(tWorkerListResult));
          return bloc;
        },
        act: (bloc) => bloc.add(
          const SearchWorkers(keyword: 'listrik'),
        ),
        expect: () => [
          const WorkerListLoading(),
          WorkerListLoaded(
            workers: tWorkers,
            filter: const WorkerFilter(searchKeyword: 'listrik'),
            hasMore: true,
          ),
        ],
        verify: (_) {
          verify(() => mockRepository.getNearbyWorkers(
                filter: const WorkerFilter(searchKeyword: 'listrik'),
              )).called(1);
        },
      );

      blocTest<WorkerListBloc, WorkerListState>(
        'clears search keyword when empty string is provided',
        build: () {
          when(() => mockRepository.getNearbyWorkers(
                filter: any(named: 'filter'),
                page: any(named: 'page'),
                perPage: any(named: 'perPage'),
              )).thenAnswer((_) async => Right(tWorkerListResult));
          return bloc;
        },
        act: (bloc) => bloc.add(
          const SearchWorkers(keyword: ''),
        ),
        expect: () => [
          const WorkerListLoading(),
          WorkerListLoaded(
            workers: tWorkers,
            filter: const WorkerFilter(),
            hasMore: true,
          ),
        ],
      );
    });

    group('LoadMore', () {
      blocTest<WorkerListBloc, WorkerListState>(
        'appends next page workers to existing list',
        build: () {
          when(() => mockRepository.getNearbyWorkers(
                filter: any(named: 'filter'),
              )).thenAnswer((_) async => Right(tWorkerListResult));
          when(() => mockRepository.getNearbyWorkers(
                filter: any(named: 'filter'),
                page: 2,
              )).thenAnswer((_) async => Right(tWorkerListResultPage2));
          return bloc;
        },
        seed: () => WorkerListLoaded(
          workers: tWorkers,
          filter: const WorkerFilter(),
          hasMore: true,
        ),
        act: (bloc) => bloc.add(const LoadMore()),
        expect: () => [
          WorkerListLoaded(
            workers: tWorkers,
            filter: const WorkerFilter(),
            hasMore: true,
            isLoadingMore: true,
          ),
          WorkerListLoaded(
            workers: [...tWorkers, ...tWorkerListResultPage2.workers],
            filter: const WorkerFilter(),
            hasMore: true,
            currentPage: 2,
          ),
        ],
      );

      blocTest<WorkerListBloc, WorkerListState>(
        'does nothing when hasMore is false',
        build: () => bloc,
        seed: () => WorkerListLoaded(
          workers: tWorkers,
          filter: const WorkerFilter(),
          hasMore: false,
          currentPage: 3,
        ),
        act: (bloc) => bloc.add(const LoadMore()),
        expect: () => <WorkerListState>[],
      );

      blocTest<WorkerListBloc, WorkerListState>(
        'does nothing when already loading more',
        build: () => bloc,
        seed: () => WorkerListLoaded(
          workers: tWorkers,
          filter: const WorkerFilter(),
          hasMore: true,
          isLoadingMore: true,
        ),
        act: (bloc) => bloc.add(const LoadMore()),
        expect: () => <WorkerListState>[],
      );

      blocTest<WorkerListBloc, WorkerListState>(
        'does nothing when state is not WorkerListLoaded',
        build: () => bloc,
        act: (bloc) => bloc.add(const LoadMore()),
        expect: () => <WorkerListState>[],
      );

      blocTest<WorkerListBloc, WorkerListState>(
        'reverts isLoadingMore on failure without losing existing data',
        build: () {
          when(() => mockRepository.getNearbyWorkers(
                filter: any(named: 'filter'),
                page: 2,
              )).thenAnswer(
            (_) async => const Left(NetworkFailure()),
          );
          return bloc;
        },
        seed: () => WorkerListLoaded(
          workers: tWorkers,
          filter: const WorkerFilter(),
          hasMore: true,
        ),
        act: (bloc) => bloc.add(const LoadMore()),
        expect: () => [
          WorkerListLoaded(
            workers: tWorkers,
            filter: const WorkerFilter(),
            hasMore: true,
            isLoadingMore: true,
          ),
          WorkerListLoaded(
            workers: tWorkers,
            filter: const WorkerFilter(),
            hasMore: true,
          ),
        ],
      );

      blocTest<WorkerListBloc, WorkerListState>(
        'sets hasMore to false when last page is loaded',
        build: () {
          when(() => mockRepository.getNearbyWorkers(
                filter: any(named: 'filter'),
                page: 3,
              )).thenAnswer((_) async => Right(tLastPageResult));
          return bloc;
        },
        seed: () => WorkerListLoaded(
          workers: [...tWorkers, ...tWorkerListResultPage2.workers],
          filter: const WorkerFilter(),
          hasMore: true,
          currentPage: 2,
        ),
        act: (bloc) => bloc.add(const LoadMore()),
        expect: () => [
          WorkerListLoaded(
            workers: [...tWorkers, ...tWorkerListResultPage2.workers],
            filter: const WorkerFilter(),
            hasMore: true,
            isLoadingMore: true,
            currentPage: 2,
          ),
          WorkerListLoaded(
            workers: [
              ...tWorkers,
              ...tWorkerListResultPage2.workers,
              ...tLastPageResult.workers,
            ],
            filter: const WorkerFilter(),
            hasMore: false,
            currentPage: 3,
          ),
        ],
      );
    });
  });
}
