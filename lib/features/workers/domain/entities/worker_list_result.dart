import 'package:equatable/equatable.dart';

import '../../../../core/network/api_response.dart';
import 'worker_profile.dart';

/// Represents a paginated result of nearby workers.
///
/// Contains the list of workers for the current page along with
/// pagination metadata for infinite scroll support.
class WorkerListResult extends Equatable {
  const WorkerListResult({
    required this.workers,
    required this.paginationMeta,
  });

  /// The list of workers for the current page.
  final List<WorkerProfile> workers;

  /// Pagination metadata (current page, total pages, etc.).
  final PaginationMeta paginationMeta;

  /// Whether there are more pages to load.
  bool get hasNextPage => paginationMeta.hasNextPage;

  @override
  List<Object?> get props => [workers, paginationMeta];
}
