import 'package:injectable/injectable.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../../orders/data/models/order_model.dart';
import '../models/worker_dashboard_model.dart';

abstract class WorkerHomeRemoteDataSource {
  Future<WorkerDashboardModel> getDashboardData();
  Future<bool> toggleAvailability({required bool isAvailable});
}

@LazySingleton(as: WorkerHomeRemoteDataSource)
class WorkerHomeRemoteDataSourceImpl implements WorkerHomeRemoteDataSource {
  const WorkerHomeRemoteDataSourceImpl(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<WorkerDashboardModel> getDashboardData() async {
    final results = await Future.wait([
      apiClient.get<Map<String, dynamic>>(ApiEndpoints.workerHome),
      apiClient.get<Map<String, dynamic>>('/worker/orders', queryParams: {'per_page': 100}),
    ]);

    final homeResponse = results[0];
    final ordersResponse = results[1];

    final homeData = homeResponse.data!;
    final ordersData = ordersResponse.data!;

    // Extract worker orders
    final List<dynamic> ordersJson = _extractOrderList(ordersData);
    final List<OrderModel> orders = ordersJson
        .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
        .toList();

    // Compute dynamic earnings based on completed / paid orders
    int earningsToday = 0;
    int earningsWeek = 0;
    int earningsMonth = 0;

    final now = DateTime.now();
    final todayLimit = now.subtract(const Duration(days: 1));
    final weekLimit = now.subtract(const Duration(days: 7));
    final monthLimit = now.subtract(const Duration(days: 30));

    for (final order in orders) {
      if (order.status == OrderStatus.completed || order.status == OrderStatus.paid) {
        final completedAt = order.completedAt;
        if (completedAt != null) {
          final price = order.totalPrice ?? order.estimatedBasePrice ?? 0;
          if (completedAt.isAfter(todayLimit)) {
            earningsToday += price;
          }
          if (completedAt.isAfter(weekLimit)) {
            earningsWeek += price;
          }
          if (completedAt.isAfter(monthLimit)) {
            earningsMonth += price;
          }
        }
      }
    }

    final apiResponse = ApiResponse<WorkerDashboardModel>.fromJson(
      homeData,
      fromJsonT: (json) {
        final data = json as Map<String, dynamic>;
        final summary = data['worker_summary'] as Map<String, dynamic>? ?? {};
        
        return WorkerDashboardModel.fromJson({
          'earnings_today': earningsToday,
          'earnings_week': earningsWeek,
          'earnings_month': earningsMonth,
          'wallet_balance': summary['balance'] ?? 0,
          'acceptance_rate': 1.0,
          'average_rating': (summary['rating'] ?? 0).toDouble(),
          'jobs_completed': summary['completed_jobs'] ?? 0,
          'incoming_order_count': data['incoming_orders_count'] ?? 0,
          'is_available': summary['is_available'] ?? false,
          'active_order_id': null,
          'active_order_title': null,
          'active_order_status': null,
          'active_order_customer_name': null,
          'active_order_start_time': null,
        });
      },
    );
    return apiResponse.data!;
  }

  List<dynamic> _extractOrderList(Map<String, dynamic> responseData) {
    final data = responseData['data'];
    if (data is List<dynamic>) return data;

    if (data is Map<String, dynamic>) {
      final nestedData = data['data'] ?? data['items'] ?? data['orders'];
      if (nestedData is List<dynamic>) return nestedData;
    }

    final orders = responseData['orders'];
    if (orders is List<dynamic>) return orders;

    return const <dynamic>[];
  }

  @override
  Future<bool> toggleAvailability({required bool isAvailable}) async {
    final response = await apiClient.patch<Map<String, dynamic>>(
      ApiEndpoints.workerAvailability,
      data: {'is_available': isAvailable},
    );
    // Assuming backend returns { "data": { "is_available": true } }
    return response.data!['data']['is_available'] as bool;
  }
}
