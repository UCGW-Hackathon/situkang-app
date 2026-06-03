import 'package:injectable/injectable.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/timeline_entry_model.dart';
import '../models/worker_location_model.dart';

/// Remote data source for tracking REST API calls.
///
/// Provides fallback polling endpoints when WebSocket is disconnected.
/// Used by [TrackingRepositoryImpl] as the secondary data source.
///
/// Requirements: 9.8 (fallback polling)
abstract class TrackingRemoteDataSource {
  /// Fetches the worker's current location via REST endpoint.
  ///
  /// Used as a fallback when WebSocket is disconnected, polled every 10 seconds.
  /// [orderId] is the order being tracked.
  Future<WorkerLocationModel> getWorkerLocation(String orderId);

  /// Fetches the order tracking timeline.
  ///
  /// Returns the list of timeline entries showing order progress steps.
  /// [orderId] is the order to get the timeline for.
  Future<List<TimelineEntryModel>> getTrackingTimeline(String orderId);
}

/// Implementation of [TrackingRemoteDataSource] using the [ApiClient].
@LazySingleton(as: TrackingRemoteDataSource)
class TrackingRemoteDataSourceImpl implements TrackingRemoteDataSource {
  const TrackingRemoteDataSourceImpl(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<WorkerLocationModel> getWorkerLocation(String orderId) async {
    final response = await apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.orderTrackingLocation(orderId),
    );

    final data = response.data;
    if (data == null) {
      throw Exception('No location data received');
    }

    // Handle wrapped response format: { "status": "success", "data": { ... } }
    final locationData = data['data'] as Map<String, dynamic>? ?? data;
    return WorkerLocationModel.fromJson(locationData);
  }

  @override
  Future<List<TimelineEntryModel>> getTrackingTimeline(String orderId) async {
    final response = await apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.orderTracking(orderId),
    );

    final data = response.data;
    if (data == null) {
      throw Exception('No tracking data received');
    }

    // Handle wrapped response format: { "status": "success", "data": { "timeline": [...] } }
    final responseData = data['data'] as Map<String, dynamic>? ?? data;
    final timelineList = responseData['timeline'] as List<dynamic>? ?? [];

    return timelineList
        .map((item) =>
            TimelineEntryModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
