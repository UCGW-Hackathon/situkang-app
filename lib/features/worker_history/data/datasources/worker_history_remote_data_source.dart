import 'package:injectable/injectable.dart';

import '../../../../core/constants/enums.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../../orders/data/models/order_model.dart';
import '../models/worker_statistics_model.dart';

abstract class WorkerHistoryRemoteDataSource {
  Future<List<OrderModel>> getHistory(OrderStatus? status, int page);
  Future<WorkerStatisticsModel> getStatistics(String timeRange);
}

const _historyPerPage = 10;

@LazySingleton(as: WorkerHistoryRemoteDataSource)
class WorkerHistoryRemoteDataSourceImpl
    implements WorkerHistoryRemoteDataSource {
  const WorkerHistoryRemoteDataSourceImpl(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<List<OrderModel>> getHistory(OrderStatus? status, int page) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': _historyPerPage,
    };
    if (status != null) {
      queryParams['status'] = status.value;
    }

    final response = await apiClient.get<Map<String, dynamic>>(
      '/worker/orders',
      queryParams: queryParams,
    );

    final ordersJson = _extractOrderList(response.data!);
    return ordersJson
        .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<WorkerStatisticsModel> getStatistics(String timeRange) async {
    final response = await apiClient.get<Map<String, dynamic>>(
      '/worker/statistics',
      queryParams: {'period': timeRange},
    );

    final apiResponse = ApiResponse<WorkerStatisticsModel>.fromJson(
      response.data!,
      fromJsonT: (json) =>
          WorkerStatisticsModel.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }

  List<dynamic> _extractOrderList(Map<String, dynamic> responseData) {
    final data = responseData['data'];

    if (data is List<dynamic>) return data;

    if (data is Map<String, dynamic>) {
      final nestedData = data['data'];
      if (nestedData is List<dynamic>) return nestedData;

      final items = data['items'];
      if (items is List<dynamic>) return items;

      final orders = data['orders'];
      if (orders is List<dynamic>) return orders;
    }

    final orders = responseData['orders'];
    if (orders is List<dynamic>) return orders;

    return const <dynamic>[];
  }
}
