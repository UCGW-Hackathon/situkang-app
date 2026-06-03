import 'package:injectable/injectable.dart';

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
      '/worker/dashboard',
    );
    final apiResponse = ApiResponse<WorkerDashboardModel>.fromJson(response.data!, fromJsonT: (json) => WorkerDashboardModel.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }

  @override
  Future<bool> toggleAvailability({required bool isAvailable}) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      '/worker/availability',
      data: {'is_available': isAvailable},
    );
    // Assuming backend returns { "data": { "is_available": true } }
    return response.data!['data']['is_available'] as bool;
  }
}
