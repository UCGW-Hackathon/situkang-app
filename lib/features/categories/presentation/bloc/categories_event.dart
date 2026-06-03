part of 'categories_bloc.dart';

/// Sealed class representing all category browsing events.
///
/// Events are dispatched from the UI layer to trigger state changes
/// in the [CategoriesBloc].
sealed class CategoriesEvent extends Equatable {
  const CategoriesEvent();

  @override
  List<Object?> get props => [];
}

/// Event dispatched to fetch all active categories.
///
/// Validates: Requirement 4.2 (full category listing sorted by display order).
class FetchCategories extends CategoriesEvent {
  const FetchCategories();
}

/// Event dispatched to fetch services within a specific category.
///
/// Validates: Requirement 4.1 (services sorted alphabetically by name).
class FetchCategoryServices extends CategoriesEvent {
  /// Creates a [FetchCategoryServices] event with the given [categoryId].
  const FetchCategoryServices({required this.categoryId});

  /// The ID of the category to fetch services for.
  final String categoryId;

  @override
  List<Object?> get props => [categoryId];
}
