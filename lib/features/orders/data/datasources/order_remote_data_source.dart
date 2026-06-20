import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

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

  /// Cancels an order with the given reason code and optional notes.
  ///
  /// Calls `POST /orders/{orderId}/cancel`.
  /// Returns the updated order model.
  Future<OrderModel> cancelOrder(
    String orderId, {
    required String cancelReason,
    String? notes,
  });
}

/// Implementation of [OrderRemoteDataSource] using [ApiClient].
@LazySingleton(as: OrderRemoteDataSource)
class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  const OrderRemoteDataSourceImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<OrderModel> createOrder(CreateOrderParams params) async {
    // Build request data as per openapi.yaml spec.
    // Only fields defined in the spec are sent:
    // worker_id, service_id, address, latitude, longitude, urgency,
    // problem_description, photos.
    // Map according to api-spec.md (Section 7.1 POST /orders)
    final requestData = <String, dynamic>{
      'worker_id': params.workerId,
      'service_id': params.serviceId,
      'title': params.title,
      'description': params.description,
      'location': {
        'latitude': params.latitude,
        'longitude': params.longitude,
        'address': params.address,
        if (params.addressDetail != null && params.addressDetail!.isNotEmpty)
          'address_detail': params.addressDetail,
      },
      if (params.preferredDate != null && params.preferredDate!.isNotEmpty)
        'preferred_date': params.preferredDate,
      if (params.preferredTimeStart != null &&
          params.preferredTimeStart!.isNotEmpty)
        'preferred_time_start': params.preferredTimeStart,
      if (params.preferredTimeEnd != null &&
          params.preferredTimeEnd!.isNotEmpty)
        'preferred_time_end': params.preferredTimeEnd,
      'urgency': params.urgency,
      if (params.notes != null && params.notes!.isNotEmpty)
        'notes': params.notes,
    };

    // Upload photos to POST /upload/damage_proof first and collect their URLs
    if (params.photos.isNotEmpty) {
      final photoUrls = <String>[];
      for (final photo in params.photos) {
        final fileName = photo.path.split('/').last;
        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            photo.path,
            filename: fileName,
          ),
        });

        final response = await apiClient.upload<Map<String, dynamic>>(
          '/upload/damage_proof',
          data: formData,
        );

        final responseData = response.data!;
        final fileData = responseData['data'] as Map<String, dynamic>;
        final url = fileData['url'] as String;
        photoUrls.add(url);
      }
      requestData['photos'] = photoUrls;
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
    // Per openapi.yaml, GET /orders only accepts: status, page, per_page.
    // sort_by and sort_order are not in the spec and cause "invalid field" errors.
    final queryParams = <String, dynamic>{'page': page, 'per_page': perPage};

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
  Future<OrderModel> cancelOrder(
    String orderId, {
    required String cancelReason,
    String? notes,
  }) async {
    final requestData = <String, dynamic>{
      'cancel_reason': cancelReason,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    };

    final response = await apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.orderCancel(orderId),
      data: requestData,
    );

    final data = response.data!;
    final orderJson = data['data'] as Map<String, dynamic>;
    return OrderModel.fromJson(orderJson);
  }
}
