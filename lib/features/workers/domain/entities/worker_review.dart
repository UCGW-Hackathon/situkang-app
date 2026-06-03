import 'package:equatable/equatable.dart';

/// Represents a review left for a worker by a customer.
class WorkerReview extends Equatable {
  const WorkerReview({
    required this.id,
    required this.reviewerName,
    required this.rating,
    required this.date,
    this.orderId,
    this.reviewerAvatarUrl,
    this.reviewerLocation,
    this.comment,
    this.tags = const [],
  });

  /// Unique review identifier.
  final String id;

  /// Associated order ID.
  final String? orderId;

  /// Name of the reviewer.
  final String reviewerName;

  /// Avatar URL of the reviewer.
  final String? reviewerAvatarUrl;

  /// Location of the reviewer (e.g., "Jakarta Selatan").
  final String? reviewerLocation;

  /// Rating given (1–5).
  final int rating;

  /// Optional review comment.
  final String? comment;

  /// Tags associated with the review (e.g., "cepat", "rapi").
  final List<String> tags;

  /// When the review was created.
  final DateTime date;

  @override
  List<Object?> get props => [
        id,
        orderId,
        reviewerName,
        reviewerAvatarUrl,
        reviewerLocation,
        rating,
        comment,
        tags,
        date,
      ];
}
