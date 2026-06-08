import 'package:injectable/injectable.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../../orders/data/models/order_model.dart';

abstract class IncomingOrderRemoteDataSource {
  Future<List<OrderModel>> getIncomingOrders();
  Future<void> acceptOrder(String orderId, int? estimatedArrivalMinutes);
  Future<void> rejectOrder(String orderId, String reasonCode);
}

@LazySingleton(as: IncomingOrderRemoteDataSource)
class IncomingOrderRemoteDataSourceImpl implements IncomingOrderRemoteDataSource {
  const IncomingOrderRemoteDataSourceImpl(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<List<OrderModel>> getIncomingOrders() async {
    final response = await apiClient.get<Map<String, dynamic>>(
      '/worker/orders/incoming',
    );
    final apiResponse = ApiResponse<List<OrderModel>>.fromJson(response.data!, fromJsonT: (json) => (json as List)
          .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
    return apiResponse.data!;
  }

  @override
  Future<void> acceptOrder(String orderId, int? estimatedArrivalMinutes) async {
    final data = <String, dynamic>{};
    if (estimatedArrivalMinutes != null) {
      data['estimated_arrival_minutes'] = estimatedArrivalMinutes;
    }

    await apiClient.post<Map<String, dynamic>>(
      '/worker/orders/$orderId/accept',
      data: data,
    );
  }

  @override
  Future<void> rejectOrder(String orderId, String reasonCode) async {
    await apiClient.post<Map<String, dynamic>>(
      '/worker/orders/$orderId/reject',
      data: {'reject_reason': reasonCode},
    );
  }
}
