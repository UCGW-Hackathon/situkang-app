import 'package:situkang_app/core/error/result.dart';

import '../entities/rating.dart';

abstract class WorkerRatingRepository {
  Future<Result<void>> submitCustomerRating({
    required String orderId,
    required double rating,
    String? comment,
    List<String> tags = const [],
  });

  Future<Result<Rating?>> getCustomerRating(String orderId);
}
