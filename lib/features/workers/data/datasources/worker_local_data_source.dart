import 'package:injectable/injectable.dart';
import '../../../../core/storage/cache_manager.dart';
import '../models/worker_profile_model.dart';
import '../models/worker_review_model.dart';

/// Local data source for caching worker data.
///
/// Uses [CacheManager] to store and retrieve worker profiles and reviews
/// for offline access and cache-first read strategy.
abstract class WorkerLocalDataSource {
  /// Retrieves the cached nearby workers list, or null if not cached or expired.
  Future<List<WorkerProfileModel>?> getCachedNearbyWorkers(String cacheKey);

  /// Caches the nearby workers list.
  Future<void> cacheNearbyWorkers(
      String cacheKey, List<WorkerProfileModel> workers);

  /// Retrieves the cached worker detail, or null if not cached or expired.
  Future<WorkerProfileModel?> getCachedWorkerDetail(String workerId);

  /// Caches a worker detail profile.
  Future<void> cacheWorkerDetail(WorkerProfileModel worker);

  /// Retrieves cached reviews for a worker, or null if not cached or expired.
  Future<List<WorkerReviewModel>?> getCachedWorkerReviews(
      String workerId, int page);

  /// Caches reviews for a worker.
  Future<void> cacheWorkerReviews(
      String workerId, int page, List<WorkerReviewModel> reviews);

  /// Clears all cached worker data.
  Future<void> clearCache();
}

/// Implementation of [WorkerLocalDataSource] using [CacheManager].
@LazySingleton(as: WorkerLocalDataSource)
class WorkerLocalDataSourceImpl implements WorkerLocalDataSource {
  const WorkerLocalDataSourceImpl({required this.cacheManager});

  final CacheManager cacheManager;

  static const String _nearbyWorkersPrefix = 'nearby_workers_';
  static const String _workerDetailPrefix = 'worker_detail_';
  static const String _workerReviewsPrefix = 'worker_reviews_';

  @override
  Future<List<WorkerProfileModel>?> getCachedNearbyWorkers(
      String cacheKey) async {
    final cachedData = await cacheManager.get<dynamic>(
      '$_nearbyWorkersPrefix$cacheKey',
    );

    if (cachedData == null) return null;
    try {
      final list = cachedData as List<dynamic>;
      return list
          .map((json) =>
              WorkerProfileModel.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> cacheNearbyWorkers(
      String cacheKey, List<WorkerProfileModel> workers) async {
    await cacheManager.put(
      '$_nearbyWorkersPrefix$cacheKey',
      workers.map((w) => w.toJson()).toList(),
      ttl: const Duration(minutes: 5), // Short TTL for location-based data
    );
  }

  @override
  Future<WorkerProfileModel?> getCachedWorkerDetail(String workerId) async {
    final cachedData = await cacheManager.get<dynamic>(
      '$_workerDetailPrefix$workerId',
    );

    if (cachedData == null) return null;
    try {
      final map = Map<String, dynamic>.from(cachedData as Map);
      return WorkerProfileModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> cacheWorkerDetail(WorkerProfileModel worker) async {
    await cacheManager.put(
      '$_workerDetailPrefix${worker.workerId}',
      worker.toJson(),
    );
  }

  @override
  Future<List<WorkerReviewModel>?> getCachedWorkerReviews(
      String workerId, int page) async {
    final cachedData = await cacheManager.get<List<dynamic>>(
      '$_workerReviewsPrefix${workerId}_page_$page',
    );

    if (cachedData == null) return null;
    return cachedData
        .map((json) =>
            WorkerReviewModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> cacheWorkerReviews(
      String workerId, int page, List<WorkerReviewModel> reviews) async {
    await cacheManager.put(
      '$_workerReviewsPrefix${workerId}_page_$page',
      reviews.map((r) => r.toJson()).toList(),
    );
  }

  @override
  Future<void> clearCache() async {
    // CacheManager doesn't support prefix-based clearing,
    // so we rely on TTL expiration for cleanup.
    // For a full clear, use cacheManager.clearAll() at the app level.
  }
}
