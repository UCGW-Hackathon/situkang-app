import 'package:glados/glados.dart';
import 'package:situkang_app/features/workers/domain/entities/worker_profile.dart';
import 'package:situkang_app/features/workers/domain/entities/worker_service.dart';
import 'package:situkang_app/features/workers/domain/utils/worker_list_utils.dart';

/// Property-based tests for worker search filter correctness.
///
/// **Property 9: Worker Search Filter Correctness**
/// For any search keyword and list of workers, all workers in the filtered
/// result SHALL contain the keyword as a case-insensitive substring in at
/// least one of: full name, specialization, or service type. No worker
/// matching the keyword SHALL be excluded from results.
///
/// **Validates: Requirements 5.5**

/// Sample names, specializations, and service types for generating workers.
const _sampleNames = [
  'Ahmad Listrik',
  'Budi Pipa',
  'Cahyo Tukang',
  'Dewi Kayu',
  'Eko Atap',
  'Fajar Cat',
  'Gita Kebun',
  'Hadi AC',
  'Indra Kunci',
  'Joko Bangunan',
  'Kartini Elektrik',
  'Lukman Plumber',
];

const _sampleSpecializations = [
  'Tukang Listrik',
  'Tukang Pipa',
  'Tukang Kayu',
  'Tukang Cat',
  'Tukang Atap',
  'Tukang Kebun',
  'Teknisi AC',
  'Tukang Kunci',
  'Tukang Bangunan',
  null,
];

const _sampleServiceNames = [
  'Instalasi Listrik',
  'Perbaikan Pipa',
  'Pembuatan Furniture',
  'Pengecatan Rumah',
  'Perbaikan Atap',
  'Perawatan Taman',
  'Service AC',
  'Duplikat Kunci',
  'Renovasi Rumah',
  'Plumbing',
];

const _sampleKeywords = [
  'listrik',
  'pipa',
  'kayu',
  'cat',
  'atap',
  'kebun',
  'ac',
  'kunci',
  'tukang',
  'instalasi',
  'perbaikan',
  'service',
  'Ahmad',
  'Budi',
  'Elektrik',
  'Plumber',
  'Renovasi',
  'xyz_no_match',
  'zzz',
  '',
];

/// Custom generators for worker search property tests.
extension WorkerSearchGenerators on Any {
  /// Generates a WorkerProfile with random name, specialization, and services.
  Generator<WorkerProfile> get searchableWorkerProfile {
    return any.combine4(
      any.intInRange(0, 1000),
      any.choose(_sampleNames),
      any.choose(_sampleSpecializations),
      any.listWithLengthInRange(0, 3, any.choose(_sampleServiceNames)),
      (index, name, specialization, serviceNames) {
        final services = serviceNames
            .asMap()
            .entries
            .map((e) => WorkerService(
                  id: 'svc_${index}_${e.key}',
                  name: e.value,
                ))
            .toList();

        return WorkerProfile(
          id: 'worker_$index',
          userId: 'user_$index',
          fullName: name,
          specialization: specialization,
          ratingAvg: 4.0,
          totalReviews: 10,
          completedJobs: 50,
          isAvailable: true,
          services: services,
        );
      },
    );
  }

  /// Generates a list of searchable WorkerProfiles.
  Generator<List<WorkerProfile>> searchableWorkerList({
    int minLength = 0,
    int maxLength = 20,
  }) {
    return any.listWithLengthInRange(
        minLength, maxLength, any.searchableWorkerProfile);
  }
}

/// Helper: checks if a worker matches a keyword (case-insensitive).
bool _workerMatchesKeyword(WorkerProfile worker, String keyword) {
  final lowerKeyword = keyword.toLowerCase();

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
}

void main() {
  // ─── Property 9: Worker Search Filter Correctness ──────────────────────────
  // **Validates: Requirements 5.5**
  group('Property 9: Worker Search Filter Correctness', () {
    Glados2(
      any.searchableWorkerList(maxLength: 15),
      any.choose(_sampleKeywords),
    ).test(
      'all matching workers are included in results (no false exclusions)',
      (workers, keyword) {
        final results = WorkerListUtils.filterBySearch(workers, keyword);

        if (keyword.isEmpty) {
          // Empty keyword returns all workers
          expect(results.length, equals(workers.length),
              reason: 'Empty keyword should return all workers');
          return;
        }

        // Every worker that matches the keyword must be in results
        for (final worker in workers) {
          if (_workerMatchesKeyword(worker, keyword)) {
            expect(results.contains(worker), isTrue,
                reason:
                    'Worker "${worker.fullName}" matches keyword "$keyword" '
                    'but was excluded from results');
          }
        }
      },
    );

    Glados2(
      any.searchableWorkerList(maxLength: 15),
      any.choose(_sampleKeywords),
    ).test(
      'no non-matching workers are included in results (no false inclusions)',
      (workers, keyword) {
        final results = WorkerListUtils.filterBySearch(workers, keyword);

        if (keyword.isEmpty) {
          // Empty keyword returns all workers
          expect(results.length, equals(workers.length),
              reason: 'Empty keyword should return all workers');
          return;
        }

        // Every worker in results must match the keyword
        for (final worker in results) {
          expect(_workerMatchesKeyword(worker, keyword), isTrue,
              reason:
                  'Worker "${worker.fullName}" (specialization: ${worker.specialization}, '
                  'services: ${worker.services.map((s) => s.name).toList()}) '
                  'does not match keyword "$keyword" but was included in results');
        }
      },
    );

    Glados2(
      any.searchableWorkerList(maxLength: 15),
      any.choose(_sampleKeywords),
    ).test(
      'result count equals number of matching workers in input',
      (workers, keyword) {
        final results = WorkerListUtils.filterBySearch(workers, keyword);

        if (keyword.isEmpty) {
          expect(results.length, equals(workers.length));
          return;
        }

        final expectedCount =
            workers.where((w) => _workerMatchesKeyword(w, keyword)).length;
        expect(results.length, equals(expectedCount),
            reason:
                'Expected $expectedCount matching workers for keyword "$keyword", '
                'got ${results.length}');
      },
    );

    Glados(any.searchableWorkerList(maxLength: 15)).test(
      'search is case-insensitive (uppercase keyword matches lowercase content)',
      (workers) {
        // Pick a keyword that exists in some worker's data
        if (workers.isEmpty) return;

        final worker = workers.first;
        final keyword = worker.fullName;

        // Search with original case
        final resultsOriginal =
            WorkerListUtils.filterBySearch(workers, keyword);
        // Search with uppercase
        final resultsUpper =
            WorkerListUtils.filterBySearch(workers, keyword.toUpperCase());
        // Search with lowercase
        final resultsLower =
            WorkerListUtils.filterBySearch(workers, keyword.toLowerCase());

        // All should return the same results
        expect(resultsOriginal.length, equals(resultsUpper.length),
            reason: 'Case-insensitive: original vs uppercase should match');
        expect(resultsOriginal.length, equals(resultsLower.length),
            reason: 'Case-insensitive: original vs lowercase should match');
      },
    );

    Glados(any.searchableWorkerList(maxLength: 15)).test(
      'null or empty keyword returns all workers unchanged',
      (workers) {
        final resultsNull = WorkerListUtils.filterBySearch(workers, null);
        final resultsEmpty = WorkerListUtils.filterBySearch(workers, '');

        expect(resultsNull.length, equals(workers.length),
            reason: 'Null keyword should return all workers');
        expect(resultsEmpty.length, equals(workers.length),
            reason: 'Empty keyword should return all workers');
      },
    );
  });
}
