import 'package:situkang_app/core/error/result.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/rating.dart';

/// Repository interface for rating and review operations.
abstract class RatingRepository {
  /// Submits a new rating and review for a completed order.
  Future<Result<Rating>> submitRating({
    required String orderId,
    required String workerId,
    required int score,
    String? comment,
    List<String> tags = const [],
  });

  /// Fetches an existing rating by its associated order ID.
  Future<Result<Rating?>> getRatingByOrder({required String orderId});

  /// Fetches paginated reviews for a specific worker.
  Future<Result<List<Rating>>> getWorkerReviews({
    required String workerId,
    int page = 1,
    int limit = 10,
    int? filterScore,
  });
}
