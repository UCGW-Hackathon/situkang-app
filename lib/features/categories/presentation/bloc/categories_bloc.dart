import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/service.dart';
import '../../domain/repositories/category_repository.dart';

part 'categories_event.dart';
part 'categories_state.dart';

/// BLoC responsible for managing category browsing state.
///
/// Handles fetching categories and services within a category.
/// Maps domain failures to appropriate UI states.
///
/// Validates:
/// - Requirement 4.1: Services sorted alphabetically by name
/// - Requirement 4.2: Full category listing sorted by display order
/// - Requirement 4.4: Empty state for no active services
/// - Requirement 4.5: Error for inactive/non-existent categories
@injectable
class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  /// Creates a [CategoriesBloc] with the required [categoryRepository].
  CategoriesBloc({required CategoryRepository categoryRepository})
      : _categoryRepository = categoryRepository,
        super(const CategoriesInitial()) {
    on<FetchCategories>(_onFetchCategories);
    on<FetchCategoryServices>(_onFetchCategoryServices);
  }

  final CategoryRepository _categoryRepository;

  /// Handles [FetchCategories] events.
  ///
  /// Emits [CategoriesLoading], then either [CategoriesLoaded] on success
  /// or [CategoriesError] on failure.
  Future<void> _onFetchCategories(
    FetchCategories event,
    Emitter<CategoriesState> emit,
  ) async {
    emit(const CategoriesLoading());

    final result = await _categoryRepository.getCategories();

    result.fold(
      (failure) => emit(CategoriesError(failure: failure)),
      (categories) => emit(CategoriesLoaded(categories: categories)),
    );
  }

  /// Handles [FetchCategoryServices] events.
  ///
  /// Emits [CategoriesLoading], then either [ServicesLoaded] on success
  /// or [CategoriesError] on failure.
  /// An empty services list triggers the empty state per Requirement 4.4.
  Future<void> _onFetchCategoryServices(
    FetchCategoryServices event,
    Emitter<CategoriesState> emit,
  ) async {
    emit(const CategoriesLoading());

    final result =
        await _categoryRepository.getCategoryServices(event.categoryId);

    result.fold(
      (failure) => emit(CategoriesError(failure: failure)),
      (services) => emit(ServicesLoaded(services: services)),
    );
  }
}
