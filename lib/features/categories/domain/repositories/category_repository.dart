import '../../../../core/error/result.dart';
import '../entities/category.dart';
import '../entities/service.dart';

/// Abstract repository defining category browsing operations.
///
/// This interface is implemented in the data layer and consumed by
/// the presentation layer (BLoC). All methods return [Result] to
/// handle errors functionally without exceptions.
///
/// Validates:
/// - Requirement 4.1: Display services within a category sorted alphabetically
/// - Requirement 4.2: Full category listing sorted by display order
/// - Requirement 4.4: Empty state for categories with no active services
/// - Requirement 4.5: Error for inactive/non-existent categories
abstract class CategoryRepository {
  /// Fetches all active categories sorted by display order (ascending).
  ///
  /// Returns a list of [Category] entities on success.
  /// Returns [ServerFailure] or [NetworkFailure] on error.
  Future<Result<List<Category>>> getCategories();

  /// Fetches active services within a specific category.
  ///
  /// The returned services are sorted alphabetically by name (case-insensitive)
  /// per Requirement 4.1.
  ///
  /// Returns a list of [Service] entities on success.
  /// Returns [ServerFailure] with 404 if category doesn't exist or is inactive.
  Future<Result<List<Service>>> getCategoryServices(String categoryId);
}
