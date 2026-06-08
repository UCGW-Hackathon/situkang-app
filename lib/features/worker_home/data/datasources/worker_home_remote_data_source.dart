import 'package:injectable/injectable.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
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
    final response = await apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.workerHome,
    );
    final apiResponse = ApiResponse<WorkerDashboardModel>.fromJson(
      response.data!,
      fromJsonT: (json) {
        final data = json as Map<String, dynamic>;
        final summary = data['worker_summary'] as Map<String, dynamic>? ?? {};
        
        return WorkerDashboardModel.fromJson({
          'earnings_today': 0,
          'earnings_week': 0,
          'earnings_month': 0,
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
