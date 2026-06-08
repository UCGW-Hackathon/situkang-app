import 'package:glados/glados.dart';
import 'package:situkang_app/features/workers/domain/entities/worker_filter.dart';
import 'package:situkang_app/features/workers/domain/entities/worker_profile.dart';
import 'package:situkang_app/features/workers/domain/utils/worker_list_utils.dart';

/// Property-based tests for worker list sort correctness.
///
/// **Property 8: Worker List Sort Correctness**
/// For any list of workers and any selected sort criterion (distance, rating,
/// price, completed_jobs), the resulting list SHALL be ordered correctly:
/// ascending for distance and price, descending for rating and completed_jobs.
///
/// **Validates: Requirements 5.4**

/// Custom generator for WorkerProfile with random numeric fields.
extension WorkerProfileGenerator on Any {
  Generator<WorkerProfile> get workerProfile {
    return any.combine5(
      any.positiveIntOrZero,
      any.doubleInRange(0.0, 100.0),
      any.doubleInRange(0.0, 5.0),
      any.intInRange(0, 10000),
      any.intInRange(0, 999999999),
      (index, distance, rating, completedJobs, basePrice) {
        return WorkerProfile(
          id: 'worker_$index',
          userId: 'user_$index',
          fullName: 'Worker $index',
          ratingAvg: rating,
          totalReviews: completedJobs ~/ 2,
          completedJobs: completedJobs,
          isAvailable: true,
          distance: distance,
          basePrice: basePrice,
        );
      },
    );
  }

  /// Generates a list of WorkerProfile with random values.
  Generator<List<WorkerProfile>> workerProfileList({
    int minLength = 0,
    int maxLength = 30,
  }) {
    return any.listWithLengthInRange(minLength, maxLength, any.workerProfile);
  }
}

void main() {
  // ─── Property 8: Worker List Sort Correctness ──────────────────────────────
  // **Validates: Requirements 5.4**
  group('Property 8: Worker List Sort Correctness', () {
    Glados(any.workerProfileList(maxLength: 20)).test(
      'sort by distance produces ascending order (smaller distance first)',
      (workers) {
        final sorted = WorkerListUtils.sortWorkers(
          workers,
          WorkerSortBy.distance,
        );

        // Verify ascending order for distance
        for (var i = 0; i < sorted.length - 1; i++) {
          final currentDistance = sorted[i].distance ?? double.infinity;
          final nextDistance = sorted[i + 1].distance ?? double.infinity;
          expect(
            currentDistance <= nextDistance,
            isTrue,
            reason:
                'Distance at index $i ($currentDistance) should be <= distance at index ${i + 1} ($nextDistance)',
          );
        }
      },
    );

    Glados(any.workerProfileList(maxLength: 20)).test(
      'sort by price produces ascending order (lower price first)',
      (workers) {
        final sorted = WorkerListUtils.sortWorkers(
          workers,
          WorkerSortBy.price,
        );

        // Verify ascending order for price
        for (var i = 0; i < sorted.length - 1; i++) {
          final currentPrice = sorted[i].basePrice ?? 0;
          final nextPrice = sorted[i + 1].basePrice ?? 0;
          expect(
            currentPrice <= nextPrice,
            isTrue,
            reason:
                'Price at index $i ($currentPrice) should be <= price at index ${i + 1} ($nextPrice)',
          );
        }
      },
    );

    Glados(any.workerProfileList(maxLength: 20)).test(
      'sort by rating produces descending order (higher rating first)',
      (workers) {
        final sorted = WorkerListUtils.sortWorkers(
          workers,
          WorkerSortBy.rating,
        );

        // Verify descending order for rating
        for (var i = 0; i < sorted.length - 1; i++) {
          final currentRating = sorted[i].ratingAvg;
          final nextRating = sorted[i + 1].ratingAvg;
          expect(
            currentRating >= nextRating,
            isTrue,
            reason:
                'Rating at index $i ($currentRating) should be >= rating at index ${i + 1} ($nextRating)',
          );
        }
      },
    );

    Glados(any.workerProfileList(maxLength: 20)).test(
      'sort by completedJobs produces descending order (more jobs first)',
      (workers) {
        final sorted = WorkerListUtils.sortWorkers(
          workers,
          WorkerSortBy.completedJobs,
        );

        // Verify descending order for completedJobs
        for (var i = 0; i < sorted.length - 1; i++) {
          final currentJobs = sorted[i].completedJobs;
          final nextJobs = sorted[i + 1].completedJobs;
          expect(
            currentJobs >= nextJobs,
            isTrue,
            reason:
                'CompletedJobs at index $i ($currentJobs) should be >= completedJobs at index ${i + 1} ($nextJobs)',
          );
        }
      },
    );

    Glados(any.workerProfileList(maxLength: 20)).test(
      'sort preserves all elements (no workers lost or duplicated)',
      (workers) {
        for (final sortBy in WorkerSortBy.values) {
          final sorted = WorkerListUtils.sortWorkers(workers, sortBy);
          expect(sorted.length, equals(workers.length),
              reason: 'Sorted list should have same length as input');

          // Every worker in the original list should be in the sorted list
          for (final worker in workers) {
            expect(sorted.contains(worker), isTrue,
                reason: 'Worker ${worker.id} should be in sorted list');
          }
        }
      },
    );
  });
}
