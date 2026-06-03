import 'package:injectable/injectable.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../models/rating_model.dart';

abstract class RatingRemoteDataSource {
  Future<RatingModel> submitRating({
    required String orderId,
    required String workerId,
    required int score,
    String? comment,
    List<String> tags = const [],
  });

  Future<RatingModel?> getRatingByOrder(String orderId);

  Future<List<RatingModel>> getWorkerReviews(
    String workerId, {
    int page = 1,
    int limit = 10,
    int? filterScore,
  });
}

@LazySingleton(as: RatingRemoteDataSource)
class RatingRemoteDataSourceImpl implements RatingRemoteDataSource {
  const RatingRemoteDataSourceImpl(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<RatingModel> submitRating({
    required String orderId,
    required String workerId,
    required int score,
    String? comment,
    List<String> tags = const [],
  }) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      '/ratings',
      data: {
        'order_id': orderId,
        'worker_id': workerId,
        'score': score,
        if (comment != null) 'comment': comment,
        'tags': tags,
      },
    );

    final apiResponse = ApiResponse<RatingModel>.fromJson(response.data!, fromJsonT: (json) => RatingModel.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }

  @override
  Future<RatingModel?> getRatingByOrder(String orderId) async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        '/orders/$orderId/rating',
      );
      final apiResponse = ApiResponse<RatingModel>.fromJson(response.data!, fromJsonT: (json) => RatingModel.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data!;
    } catch (e) {
      // Return null if not found (404)
      if (e.toString().contains('404')) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<List<RatingModel>> getWorkerReviews(
    String workerId, {
    int page = 1,
    int limit = 10,
    int? filterScore,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (filterScore != null) {
      queryParams['score'] = filterScore;
    }

    final response = await apiClient.get<Map<String, dynamic>>(
      '/workers/$workerId/reviews',
      queryParams: queryParams,
    );

    final apiResponse = ApiResponse<List<RatingModel>>.fromJson(response.data!, fromJsonT: (json) => (json as List)
          .map((item) => RatingModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
    return apiResponse.data!;
  }
}
