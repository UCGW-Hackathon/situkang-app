import '../entities/worker_filter.dart';
import '../entities/worker_profile.dart';

/// Utility class for sorting and filtering worker lists.
///
/// Provides pure functions for local sorting and search filtering
/// of [WorkerProfile] lists based on [WorkerSortBy] criteria and
/// search keywords.
class WorkerListUtils {
  WorkerListUtils._();

  /// Sorts a list of [WorkerProfile] by the given [sortBy] criterion.
  ///
  /// - [WorkerSortBy.distance]: ascending (smaller distance first)
  /// - [WorkerSortBy.price]: ascending (lower price first)
  /// - [WorkerSortBy.rating]: descending (higher rating first)
  /// - [WorkerSortBy.completedJobs]: descending (more jobs first)
  ///
  /// Returns a new sorted list without modifying the original.
  static List<WorkerProfile> sortWorkers(
    List<WorkerProfile> workers,
    WorkerSortBy sortBy,
  ) {
    final sorted = List<WorkerProfile>.from(workers);
    sorted.sort((a, b) {
      switch (sortBy) {
        case WorkerSortBy.distance:
          final aDistance = a.distance ?? double.infinity;
          final bDistance = b.distance ?? double.infinity;
          return aDistance.compareTo(bDistance);
        case WorkerSortBy.price:
          final aPrice = a.basePrice ?? 0;
          final bPrice = b.basePrice ?? 0;
          return aPrice.compareTo(bPrice);
        case WorkerSortBy.rating:
          return b.ratingAvg.compareTo(a.ratingAvg);
        case WorkerSortBy.completedJobs:
          return b.completedJobs.compareTo(a.completedJobs);
      }
    });
    return sorted;
  }

  /// Filters workers by a search keyword.
  ///
  /// Returns workers whose [fullName], [specialization], or any service
  /// [name] contains the [keyword] as a case-insensitive substring.
  ///
  /// If [keyword] is null or empty, returns all workers unchanged.
  static List<WorkerProfile> filterBySearch(
    List<WorkerProfile> workers,
    String? keyword,
  ) {
    if (keyword == null || keyword.isEmpty) {
      return workers;
    }

    final lowerKeyword = keyword.toLowerCase();

    return workers.where((worker) {
      // Check full name
      if (worker.fullName.toLowerCase().contains(lowerKeyword)) {
        return true;
      }

      // Check specialization
      if (worker.specialization != null &&
          worker.specialization!.toLowerCase().contains(lowerKeyword)) {
        return true;
      }

      // Check service types
      for (final service in worker.services) {
        if (service.name.toLowerCase().contains(lowerKeyword)) {
          return true;
        }
      }

      return false;
    }).toList();
  }
}
