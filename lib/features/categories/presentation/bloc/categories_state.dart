part of 'categories_bloc.dart';

/// Sealed class representing all category browsing states.
///
/// The [CategoriesBloc] emits these states in response to [CategoriesEvent]s,
/// driving the UI to display the appropriate content or feedback.
sealed class CategoriesState extends Equatable {
  const CategoriesState();

  @override
  List<Object?> get props => [];
}

/// The initial state before any category action has been taken.
class CategoriesInitial extends CategoriesState {
  const CategoriesInitial();
}

/// State emitted while a category operation is in progress.
///
/// The UI should display a loading indicator when in this state.
class CategoriesLoading extends CategoriesState {
  const CategoriesLoading();
}

/// State emitted when categories have been successfully loaded.
///
/// Contains the list of [Category] entities sorted by display order.
/// Validates: Requirement 4.2.
class CategoriesLoaded extends CategoriesState {
  /// Creates a [CategoriesLoaded] state with the given [categories].
  const CategoriesLoaded({required this.categories});

  /// The list of categories sorted by display order (ascending).
  final List<Category> categories;

  @override
  List<Object?> get props => [categories];
}

/// State emitted when services for a category have been successfully loaded.
///
/// Contains the list of [Service] entities sorted alphabetically by name.
/// An empty list indicates no active services (Requirement 4.4).
/// Validates: Requirement 4.1.
class ServicesLoaded extends CategoriesState {
  /// Creates a [ServicesLoaded] state with the given [services].
  const ServicesLoaded({required this.services});

  /// The list of services sorted alphabetically by name (case-insensitive).
  final List<Service> services;

  @override
  List<Object?> get props => [services];
}

/// State emitted when a category operation fails.
///
/// Contains the [Failure] describing what went wrong, enabling the UI
/// to display appropriate error messages.
///
/// Handles:
/// - Category not found or inactive (Requirement 4.5)
/// - Network errors, server errors, etc.
class CategoriesError extends CategoriesState {
  /// Creates a [CategoriesError] state with the given [failure].
  const CategoriesError({required this.failure});

  /// The failure describing what went wrong.
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
