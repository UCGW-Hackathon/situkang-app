import '../../domain/entities/worker_review.dart';

/// Data model for a worker review, mapping API JSON to domain entity.
class WorkerReviewModel {
  const WorkerReviewModel({
    required this.reviewId,
    required this.userName,
    required this.rating,
    required this.createdAt,
    this.orderId,
    this.userAvatarUrl,
    this.userLocation,
    this.comment,
    this.tags = const [],
  });

  /// Creates a [WorkerReviewModel] from a JSON map.
  factory WorkerReviewModel.fromJson(Map<String, dynamic> json) {
    return WorkerReviewModel(
      reviewId: json['review_id'] as String? ?? '',
      orderId: json['order_id'] as String?,
      userName: json['user_name'] as String? ?? '',
      userAvatarUrl: json['user_avatar_url'] as String?,
      userLocation: json['user_location'] as String?,
      rating: json['rating'] as int? ?? 0,
      comment: json['comment'] as String?,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((t) => t.toString())
              .toList() ??
          [],
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  final String reviewId;
  final String? orderId;
  final String userName;
  final String? userAvatarUrl;
  final String? userLocation;
  final int rating;
  final String? comment;
  final List<String> tags;
  final DateTime createdAt;

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() => {
        'review_id': reviewId,
        'order_id': orderId,
        'user_name': userName,
        'user_avatar_url': userAvatarUrl,
        'user_location': userLocation,
        'rating': rating,
        'comment': comment,
        'tags': tags,
        'created_at': createdAt.toIso8601String(),
      };

  /// Converts this model to a domain [WorkerReview] entity.
  WorkerReview toEntity() => WorkerReview(
        id: reviewId,
        orderId: orderId,
        reviewerName: userName,
        reviewerAvatarUrl: userAvatarUrl,
        reviewerLocation: userLocation,
        rating: rating,
        comment: comment,
        tags: tags,
        date: createdAt,
      );
}
