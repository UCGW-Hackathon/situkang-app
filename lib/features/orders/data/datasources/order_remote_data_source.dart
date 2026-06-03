import 'package:injectable/injectable.dart';
import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../domain/entities/create_order_params.dart';
import '../../domain/entities/order_filter.dart';
import '../models/order_detail_model.dart';
import '../models/order_model.dart';

/// Remote data source for order management operations.
///
/// Makes API calls to the orders endpoints for creating orders,
/// fetching order lists, viewing order details, and cancelling orders.
abstract class OrderRemoteDataSource {
  /// Creates a new order with the given [params].
  ///
  /// Calls `POST /orders` with the order data.
  /// Returns the created order model.
  Future<OrderModel> createOrder(CreateOrderParams params);

  /// Fetches the user's order list with optional filters and pagination.
  ///
  /// Calls `GET /orders` with query parameters.
  /// Returns a list of order models and pagination metadata.
  Future<(List<OrderModel>, PaginationMeta)> getOrders({
    OrderFilter? filter,
    int page = 1,
    int perPage = 10,
  });

  /// Fetches the full detail of a specific order.
  ///
  /// Calls `GET /orders/{orderId}`.
  Future<OrderDetailModel> getOrderDetail(String orderId);

  /// Cancels an order with the given reason.
  ///
  /// Calls `POST /orders/{orderId}/cancel`.
  /// Returns the updated order model.
  Future<OrderModel> cancelOrder(String orderId, String reason);
}

/// Implementation of [OrderRemoteDataSource] using [ApiClient].
@LazySingleton(as: OrderRemoteDataSource)
class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  const OrderRemoteDataSourceImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<OrderModel> createOrder(CreateOrderParams params) async {
    // Build request data
    final requestData = <String, dynamic>{
      'worker_id': params.workerId,
      'service_id': params.serviceId,
      'title': params.title,
      'description': params.description,
      'location': {
        'latitude': params.latitude,
        'longitude': params.longitude,
        'address': params.address,
        if (params.addressDetail != null)
          'address_detail': params.addressDetail,
      },
      'urgency': params.urgency,
    };

    if (params.preferredDate != null) {
      requestData['preferred_date'] = params.preferredDate;
    }
    if (params.preferredTimeStart != null) {
      requestData['preferred_time_start'] = params.preferredTimeStart;
    }
    if (params.preferredTimeEnd != null) {
      requestData['preferred_time_end'] = params.preferredTimeEnd;
    }
    if (params.notes != null && params.notes!.isNotEmpty) {
      requestData['notes'] = params.notes;
    }

    // Handle photos upload
    if (params.photos.isNotEmpty) {
      final formData = FormData.fromMap(Map<String, dynamic>.from(requestData));
      for (var i = 0; i < params.photos.length; i++) {
        formData.files.add(MapEntry(
          'photos[$i]',
          await MultipartFile.fromFile(
            params.photos[i].path,
            filename: 'photo_$i.jpg',
          ),
        ));
      }

      final response = await apiClient.upload<Map<String, dynamic>>(
        ApiEndpoints.orders,
        data: formData,
      );

      final data = response.data!;
      final orderJson = data['data'] as Map<String, dynamic>;
      return OrderModel.fromJson(orderJson);
    }

    final response = await apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.orders,
      data: requestData,
    );

    final data = response.data!;
    final orderJson = data['data'] as Map<String, dynamic>;
    return OrderModel.fromJson(orderJson);
  }

  @override
  Future<(List<OrderModel>, PaginationMeta)> getOrders({
    OrderFilter? filter,
    int page = 1,
    int perPage = 10,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      'sort_by': 'created_at',
      'sort_order': 'desc',
    };

    if (filter?.status != null) {
      queryParams['status'] = filter!.status!.value;
    }

    final response = await apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.orders,
      queryParams: queryParams,
    );

    final data = response.data!;
    final ordersJson = data['data'] as List<dynamic>? ?? [];
    final orders = ordersJson
        .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
        .toList();

    final meta = data['meta'] != null
        ? PaginationMeta.fromJson(data['meta'] as Map<String, dynamic>)
        : PaginationMeta(
            currentPage: page,
            perPage: perPage,
            total: orders.length,
            totalPages: 1,
          );

    return (orders, meta);
  }

  @override
  Future<OrderDetailModel> getOrderDetail(String orderId) async {
    final response = await apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.orderDetail(orderId),
    );

    final data = response.data!;
    final orderJson = data['data'] as Map<String, dynamic>;
    return OrderDetailModel.fromJson(orderJson);
  }

  @override
  Future<OrderModel> cancelOrder(String orderId, String reason) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.orderCancel(orderId),
      data: {
        'reason': reason,
      },
    );

    final data = response.data!;
    final orderJson = data['data'] as Map<String, dynamic>;
    return OrderModel.fromJson(orderJson);
  }
}
