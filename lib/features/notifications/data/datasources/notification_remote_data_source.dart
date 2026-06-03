import 'package:injectable/injectable.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../models/notification_model.dart';

abstract class NotificationRemoteDataSource {
  Future<List<NotificationModel>> getNotifications({
    required int page,
    String? type,
  });
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
  Future<int> getUnreadCount();
}

@LazySingleton(as: NotificationRemoteDataSource)
class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  const NotificationRemoteDataSourceImpl(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<List<NotificationModel>> getNotifications({
    required int page,
    String? type,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      if (type != null && type != 'all') 'type': type,
    };

    final response = await apiClient.get<Map<String, dynamic>>(
      '/notifications',
      queryParams: queryParams,
    );

    final apiResponse = ApiResponse<List<NotificationModel>>.fromJson(response.data!, fromJsonT: (json) => (json as List)
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiResponse.data!;
  }

  @override
  Future<void> markAsRead(String id) async {
    await apiClient.post<Map<String, dynamic>>('/notifications/$id/read');
  }

  @override
  Future<void> markAllAsRead() async {
    await apiClient.post<Map<String, dynamic>>('/notifications/read-all');
  }

  @override
  Future<int> getUnreadCount() async {
    final response = await apiClient.get<Map<String, dynamic>>('/notifications/unread-count');
    // Assuming API returns { "status": "success", "data": { "count": 5 } }
    final data = response.data?['data'] as Map<String, dynamic>?;
    return (data?['count'] as num?)?.toInt() ?? 0;
  }
}
