import 'package:injectable/injectable.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../../orders/data/models/order_model.dart';
import '../models/worker_statistics_model.dart';

abstract class WorkerHistoryRemoteDataSource {
  Future<List<OrderModel>> getHistory(String filter, int page);
  Future<WorkerStatisticsModel> getStatistics(String timeRange);
}

@LazySingleton(as: WorkerHistoryRemoteDataSource)
class WorkerHistoryRemoteDataSourceImpl implements WorkerHistoryRemoteDataSource {
  const WorkerHistoryRemoteDataSourceImpl(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<List<OrderModel>> getHistory(String filter, int page) async {
    final response = await apiClient.get<Map<String, dynamic>>(
      '/worker/history',
      queryParams: {
        'filter': filter,
        'page': page,
      },
    );
    
    // Assuming the API returns a paginated list inside 'data' array
    final apiResponse = ApiResponse<List<OrderModel>>.fromJson(response.data!, fromJsonT: (json) => (json as List)
          .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
    return apiResponse.data!;
  }

  @override
  Future<WorkerStatisticsModel> getStatistics(String timeRange) async {
    final response = await apiClient.get<Map<String, dynamic>>(
      '/worker/statistics',
      queryParams: {
        'period': timeRange,
      },
    );
    
    final apiResponse = ApiResponse<WorkerStatisticsModel>.fromJson(response.data!, fromJsonT: (json) => WorkerStatisticsModel.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }
}
