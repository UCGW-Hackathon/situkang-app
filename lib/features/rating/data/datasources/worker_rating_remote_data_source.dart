import 'package:injectable/injectable.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../models/rating_model.dart';

abstract class WorkerRatingRemoteDataSource {
  Future<void> submitCustomerRating({
    required String orderId,
    required double rating,
    String? comment,
    List<String> tags = const [],
  });

  Future<RatingModel?> getCustomerRating(String orderId);
}

@LazySingleton(as: WorkerRatingRemoteDataSource)
class WorkerRatingRemoteDataSourceImpl implements WorkerRatingRemoteDataSource {
  const WorkerRatingRemoteDataSourceImpl(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<void> submitCustomerRating({
    required String orderId,
    required double rating,
    String? comment,
    List<String> tags = const [],
  }) async {
    await apiClient.post<Map<String, dynamic>>(
      '/worker/orders/$orderId/rating',
      data: {
        'rating': rating,
        'comment': ?comment,
        'tags': tags,
      },
    );
  }

  @override
  Future<RatingModel?> getCustomerRating(String orderId) async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        '/worker/orders/$orderId/rating',
      );
      
      // If there's no rating yet, API might return 404 which is handled by catching it,
      // or it might return null data.
      if (response.data == null || response.data!.isEmpty) {
        return null;
      }

      final apiResponse = ApiResponse<RatingModel>.fromJson(response.data!, fromJsonT: (json) => RatingModel.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data!;
    } catch (e) {
      // Assuming 404 means no rating exists yet
      return null;
    }
  }
}
