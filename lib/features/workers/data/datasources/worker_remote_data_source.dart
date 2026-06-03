import 'package:injectable/injectable.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../domain/entities/worker_filter.dart';
import '../models/worker_profile_model.dart';
import '../models/worker_review_model.dart';

/// Remote data source for worker discovery and detail operations.
///
/// Makes API calls to the workers endpoints for fetching nearby workers,
/// worker detail profiles, and worker reviews.
abstract class WorkerRemoteDataSource {
  /// Fetches nearby workers with optional filters and pagination.
  ///
  /// Calls `GET /workers/nearby` with query parameters.
  /// Returns a list of worker models and pagination metadata.
  Future<(List<WorkerProfileModel>, PaginationMeta)> getNearbyWorkers({
    required double latitude,
    required double longitude,
    WorkerFilter? filter,
    int page = 1,
    int perPage = 10,
  });

  /// Fetches the full detail profile of a specific worker.
  ///
  /// Calls `GET /workers/{workerId}`.
  Future<WorkerProfileModel> getWorkerDetail(String workerId);

  /// Fetches paginated reviews for a specific worker.
  ///
  /// Calls `GET /workers/{workerId}/reviews`.
  /// Returns a list of review models and pagination metadata.
  Future<(List<WorkerReviewModel>, PaginationMeta)> getWorkerReviews(
    String workerId, {
    int page = 1,
    int perPage = 10,
  });
}

/// Implementation of [WorkerRemoteDataSource] using [ApiClient].
@LazySingleton(as: WorkerRemoteDataSource)
class WorkerRemoteDataSourceImpl implements WorkerRemoteDataSource {
  const WorkerRemoteDataSourceImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<(List<WorkerProfileModel>, PaginationMeta)> getNearbyWorkers({
    required double latitude,
    required double longitude,
    WorkerFilter? filter,
    int page = 1,
    int perPage = 10,
  }) async {
    final queryParams = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      'page': page,
      'per_page': perPage,
    };

    if (filter != null) {
      if (filter.categoryId != null) {
        queryParams['category_id'] = filter.categoryId;
      }
      if (filter.serviceId != null) {
        queryParams['service_id'] = filter.serviceId;
      }
      if (filter.minRating != null) {
        queryParams['min_rating'] = filter.minRating;
      }
      if (filter.maxDistance != null) {
        queryParams['radius_km'] = filter.maxDistance;
      }
      queryParams['sort_by'] = filter.sortBy.value;
      queryParams['sort_order'] = filter.sortBy.defaultSortOrder;
    }

    // Use search endpoint if keyword is provided
    final String endpoint;
    if (filter?.searchKeyword != null && filter!.searchKeyword!.isNotEmpty) {
      endpoint = ApiEndpoints.workersSearch;
      queryParams['q'] = filter.searchKeyword;
    } else {
      endpoint = ApiEndpoints.workersNearby;
    }

    final response = await apiClient.get<Map<String, dynamic>>(
      endpoint,
      queryParams: queryParams,
    );

    final data = response.data!;
    final workersJson = data['data'] as List<dynamic>? ?? [];
    final workers = workersJson
        .map((json) =>
            WorkerProfileModel.fromJson(json as Map<String, dynamic>))
        .toList();

    final meta = data['meta'] != null
        ? PaginationMeta.fromJson(data['meta'] as Map<String, dynamic>)
        : PaginationMeta(
            currentPage: page,
            perPage: perPage,
            total: workers.length,
            totalPages: 1,
          );

    return (workers, meta);
  }

  @override
  Future<WorkerProfileModel> getWorkerDetail(String workerId) async {
    final response = await apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.workerDetail(workerId),
    );

    final data = response.data!;
    final workerJson = data['data'] as Map<String, dynamic>;
    return WorkerProfileModel.fromJson(workerJson);
  }

  @override
  Future<(List<WorkerReviewModel>, PaginationMeta)> getWorkerReviews(
    String workerId, {
    int page = 1,
    int perPage = 10,
  }) async {
    final response = await apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.workerReviews(workerId),
      queryParams: {
        'page': page,
        'per_page': perPage,
      },
    );

    final data = response.data!;
    final reviewsJson = data['data'] as List<dynamic>? ?? [];
    final reviews = reviewsJson
        .map((json) =>
            WorkerReviewModel.fromJson(json as Map<String, dynamic>))
        .toList();

    final meta = data['meta'] != null
        ? PaginationMeta.fromJson(data['meta'] as Map<String, dynamic>)
        : PaginationMeta(
            currentPage: page,
            perPage: perPage,
            total: reviews.length,
            totalPages: 1,
          );

    return (reviews, meta);
  }
}
