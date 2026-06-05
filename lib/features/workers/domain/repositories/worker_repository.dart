import '../../../../core/error/result.dart';
import '../entities/worker_filter.dart';
import '../entities/worker_list_result.dart';
import '../entities/worker_profile.dart';
import '../entities/worker_review.dart';

/// Abstract repository interface for worker discovery and detail.
///
/// Defines the contract for fetching nearby workers with filters,
/// worker detail profiles, and worker reviews. Implementations should
/// use a cache-first strategy for detail views.
abstract class WorkerRepository {
  /// Fetches nearby workers with optional filters and pagination.
  ///
  /// Workers are filtered and sorted based on the provided [filter].
  /// Results are paginated with [page] and [perPage] parameters.
  /// Requires user location (latitude/longitude) to calculate distance.
  Future<Result<WorkerListResult>> getNearbyWorkers({
    WorkerFilter? filter,
    int page = 1,
    int perPage = 10,
  });

  /// Fetches the full detail profile of a specific worker.
  ///
  /// Returns the worker profile together with the embedded top_reviews
  /// (up to 3 recent reviews) that the API includes in the detail response.
  /// Returns cached data if available, then fetches fresh data from the API.
  Future<Result<(WorkerProfile, List<WorkerReview>)>> getWorkerDetail(
      String workerId);

  /// Fetches paginated reviews for a specific worker.
  ///
  /// Returns reviews sorted by creation date (newest first) by default.
  Future<Result<List<WorkerReview>>> getWorkerReviews(
    String workerId, {
    int page = 1,
    int perPage = 10,
  });
}
