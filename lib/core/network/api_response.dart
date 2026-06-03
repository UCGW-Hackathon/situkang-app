import 'package:equatable/equatable.dart';

/// Generic API response wrapper matching the backend response format.
///
/// The backend returns responses in the shape:
/// ```json
/// {
///   "status": "success" | "error",
///   "message": "...",
///   "data": { ... },
///   "meta": { "current_page": 1, "per_page": 10, "total": 50, "total_pages": 5 }
/// }
/// ```
class ApiResponse<T> extends Equatable {
  /// Creates an [ApiResponse] with the given fields.
  const ApiResponse({
    required this.status,
    this.message,
    this.data,
    this.meta,
  });

  /// Creates an [ApiResponse] from a JSON map with an optional data parser.
  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(dynamic json)? fromJsonT,
  }) {
    return ApiResponse<T>(
      status: json['status'] as String? ?? 'error',
      message: json['message'] as String?,
      data: fromJsonT != null && json['data'] != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      meta: json['meta'] != null
          ? PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>)
          : null,
    );
  }

  /// The response status: "success" or "error".
  final String status;

  /// An optional message from the server (e.g., success confirmation or error description).
  final String? message;

  /// The response payload, typed generically.
  final T? data;

  /// Pagination metadata, present for paginated list responses.
  final PaginationMeta? meta;

  /// Returns true if the response status is "success".
  bool get isSuccess => status == 'success';

  @override
  List<Object?> get props => [status, message, data, meta];
}

/// Pagination metadata for paginated API responses.
class PaginationMeta extends Equatable {
  /// Creates a [PaginationMeta] with the given fields.
  const PaginationMeta({
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.totalPages,
  });

  /// Creates a [PaginationMeta] from a JSON map.
  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      currentPage: json['current_page'] as int? ?? 1,
      perPage: json['per_page'] as int? ?? 10,
      total: json['total'] as int? ?? 0,
      totalPages: json['total_pages'] as int? ?? 1,
    );
  }

  /// The current page number (1-indexed).
  final int currentPage;

  /// The number of items per page.
  final int perPage;

  /// The total number of items across all pages.
  final int total;

  /// The total number of pages.
  final int totalPages;

  /// Returns true if there are more pages after the current one.
  bool get hasNextPage => currentPage < totalPages;

  /// Converts this [PaginationMeta] to a JSON map.
  Map<String, dynamic> toJson() => {
        'current_page': currentPage,
        'per_page': perPage,
        'total': total,
        'total_pages': totalPages,
      };

  @override
  List<Object?> get props => [currentPage, perPage, total, totalPages];
}
