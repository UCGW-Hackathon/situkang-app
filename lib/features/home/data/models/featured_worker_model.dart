import '../../domain/entities/featured_worker.dart';

/// Data Transfer Object for featured worker API responses.
///
/// Maps snake_case JSON fields from the `/home` endpoint to the
/// domain [FeaturedWorker] entity.
class FeaturedWorkerModel {
  const FeaturedWorkerModel({
    required this.workerId,
    required this.fullName,
    required this.specialization,
    required this.avatarUrl,
    required this.rating,
    required this.distanceKm,
    required this.completedJobs,
    required this.isVerified,
  });

  /// Parses a [FeaturedWorkerModel] from a JSON map.
  factory FeaturedWorkerModel.fromJson(Map<String, dynamic> json) {
    return FeaturedWorkerModel(
      workerId: json['worker_id'] as String? ?? json['user_id'] as String? ?? json['id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? json['name'] as String? ?? '',
      specialization: json['specialization'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? (json['distance'] as num?)?.toDouble() ?? 0.0,
      completedJobs: json['completed_jobs'] as int? ?? 0,
      isVerified: json['is_verified'] as bool? ?? false,
    );
  }

  final String workerId;
  final String fullName;
  final String specialization;
  final String avatarUrl;
  final double rating;
  final double distanceKm;
  final int completedJobs;
  final bool isVerified;

  /// Converts this model to a JSON map for caching.
  Map<String, dynamic> toJson() {
    return {
      'worker_id': workerId,
      'full_name': fullName,
      'specialization': specialization,
      'avatar_url': avatarUrl,
      'rating': rating,
      'distance_km': distanceKm,
      'completed_jobs': completedJobs,
      'is_verified': isVerified,
    };
  }

  /// Converts this data model to the domain [FeaturedWorker] entity.
  FeaturedWorker toEntity() {
    return FeaturedWorker(
      id: workerId,
      name: fullName,
      specialization: specialization,
      avatarUrl: avatarUrl,
      rating: rating,
      distance: distanceKm,
      completedJobs: completedJobs,
      isVerified: isVerified,
    );
  }
}
