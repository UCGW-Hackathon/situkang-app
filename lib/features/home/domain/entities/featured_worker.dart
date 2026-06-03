import 'package:equatable/equatable.dart';

/// Represents a featured nearby worker displayed on the home screen.
///
/// Up to 10 workers within a 10km radius, sorted by distance ascending.
/// Shows name, specialization, avatar, rating, distance, completed jobs,
/// and verification badge.
class FeaturedWorker extends Equatable {
  const FeaturedWorker({
    required this.id,
    required this.name,
    required this.specialization,
    required this.avatarUrl,
    required this.rating,
    required this.distance,
    required this.completedJobs,
    required this.isVerified,
  });

  /// Unique worker identifier.
  final String id;

  /// Worker's full name.
  final String name;

  /// Worker's specialization (e.g., "Spesialis AC & Listrik").
  final String specialization;

  /// URL to the worker's avatar image.
  final String avatarUrl;

  /// Worker's average rating (1.0–5.0).
  final double rating;

  /// Distance from the user in kilometers.
  final double distance;

  /// Total number of completed jobs.
  final int completedJobs;

  /// Whether the worker is verified.
  final bool isVerified;

  @override
  List<Object?> get props => [
        id,
        name,
        specialization,
        avatarUrl,
        rating,
        distance,
        completedJobs,
        isVerified,
      ];
}
