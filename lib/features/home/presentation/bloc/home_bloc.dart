import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/repositories/home_repository.dart';
import 'home_event.dart';
import 'home_state.dart';

/// BLoC for managing the user home screen state.
///
/// Handles fetching and refreshing aggregated home data including
/// greeting, active order banner, promos, categories, featured workers,
/// and articles.
@injectable
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({required this.homeRepository}) : super(const HomeInitial()) {
    on<FetchHomeData>(_onFetchHomeData);
    on<RefreshHomeData>(_onRefreshHomeData);
  }

  /// The home repository for data operations.
  final HomeRepository homeRepository;

  Future<void> _onFetchHomeData(
    FetchHomeData event,
    Emitter<HomeState> emit,
  ) async {
    final cachedResult = await homeRepository.getCachedHomeData();
    bool hasCachedData = false;
    cachedResult.fold(
      (_) {},
      (cachedData) {
        if (cachedData != null) {
          emit(HomeLoaded(homeData: cachedData));
          hasCachedData = true;
        }
      },
    );

    if (!hasCachedData) {
      emit(const HomeLoading());
    }

    final result = await homeRepository.getHomeData();

    result.fold(
      (failure) {
        if (!hasCachedData) {
          emit(HomeError(failure: failure));
        }
      },
      (homeData) => emit(HomeLoaded(homeData: homeData)),
    );
  }

  Future<void> _onRefreshHomeData(
    RefreshHomeData event,
    Emitter<HomeState> emit,
  ) async {
    // Don't show loading state on refresh to preserve current UI
    final result = await homeRepository.getHomeData();

    result.fold(
      (failure) {
        // On refresh failure, keep current data if available
        if (state is! HomeLoaded) {
          emit(HomeError(failure: failure));
        }
      },
      (homeData) => emit(HomeLoaded(homeData: homeData)),
    );
  }
}
