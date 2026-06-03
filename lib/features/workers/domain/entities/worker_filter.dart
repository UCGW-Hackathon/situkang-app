import 'package:equatable/equatable.dart';

/// Sort criteria for the worker list.
enum WorkerSortBy {
  distance,
  rating,
  price,
  completedJobs;

  /// Returns the API string value.
  String get value {
    switch (this) {
      case WorkerSortBy.completedJobs:
        return 'completed_jobs';
      default:
        return name;
    }
  }

  /// Returns the default sort order for this criterion.
  ///
  /// Distance and price sort ascending; rating and completed jobs sort descending.
  String get defaultSortOrder {
    switch (this) {
      case WorkerSortBy.distance:
      case WorkerSortBy.price:
        return 'asc';
      case WorkerSortBy.rating:
      case WorkerSortBy.completedJobs:
        return 'desc';
    }
  }

  /// Parses an API string value into a [WorkerSortBy].
  static WorkerSortBy fromString(String value) {
    switch (value) {
      case 'completed_jobs':
        return WorkerSortBy.completedJobs;
      default:
        return WorkerSortBy.values.firstWhere(
          (e) => e.name == value,
          orElse: () => WorkerSortBy.distance,
        );
    }
  }
}

/// Filter parameters for the nearby workers search.
///
/// All fields are optional — when null, the filter is not applied.
class WorkerFilter extends Equatable {
  const WorkerFilter({
    this.categoryId,
    this.serviceId,
    this.minRating,
    this.maxDistance,
    this.sortBy = WorkerSortBy.distance,
    this.searchKeyword,
  });

  /// Filter by service category ID.
  final String? categoryId;

  /// Filter by specific service ID.
  final String? serviceId;

  /// Minimum average rating (1.0–5.0).
  final double? minRating;

  /// Maximum distance in kilometers.
  final double? maxDistance;

  /// Sort criterion for the results.
  final WorkerSortBy sortBy;

  /// Search keyword for name, specialization, or service type.
  final String? searchKeyword;

  /// Whether any filter is actively applied.
  bool get hasActiveFilters =>
      categoryId != null ||
      serviceId != null ||
      minRating != null ||
      maxDistance != null ||
      (searchKeyword != null && searchKeyword!.isNotEmpty);

  /// Creates a copy of this filter with the given fields replaced.
  WorkerFilter copyWith({
    String? categoryId,
    String? serviceId,
    double? minRating,
    double? maxDistance,
    WorkerSortBy? sortBy,
    String? searchKeyword,
  }) {
    return WorkerFilter(
      categoryId: categoryId ?? this.categoryId,
      serviceId: serviceId ?? this.serviceId,
      minRating: minRating ?? this.minRating,
      maxDistance: maxDistance ?? this.maxDistance,
      sortBy: sortBy ?? this.sortBy,
      searchKeyword: searchKeyword ?? this.searchKeyword,
    );
  }

  /// Creates a copy with the specified fields cleared (set to null).
  WorkerFilter clearFields({
    bool categoryId = false,
    bool serviceId = false,
    bool minRating = false,
    bool maxDistance = false,
    bool searchKeyword = false,
  }) {
    return WorkerFilter(
      categoryId: categoryId ? null : this.categoryId,
      serviceId: serviceId ? null : this.serviceId,
      minRating: minRating ? null : this.minRating,
      maxDistance: maxDistance ? null : this.maxDistance,
      sortBy: sortBy,
      searchKeyword: searchKeyword ? null : this.searchKeyword,
    );
  }

  @override
  List<Object?> get props => [
        categoryId,
        serviceId,
        minRating,
        maxDistance,
        sortBy,
        searchKeyword,
      ];
}
