import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../invoice/data/models/invoice_model.dart';
import '../../domain/entities/invoice_material_input.dart';
import '../models/worker_order_detail_model.dart';

abstract class WorkerOrderRemoteDataSource {
  Future<WorkerOrderDetailModel> getOrderDetail(String orderId);

  Future<void> acceptOrder(String orderId, int? estimatedArrivalMinutes);

  Future<void> updateOrderStatus(String orderId, String status);

  Future<void> uploadProgressPhoto(
    String orderId,
    String filePath,
    String? caption,
  );

  Future<void> addWorkItem({
    required String orderId,
    required String itemName,
    required int cost,
    String? description,
  });

  Future<InvoiceModel> completeOrder({
    required String orderId,
    String? workerNotes,
    List<InvoiceMaterialInput> materials,
  });
}

@LazySingleton(as: WorkerOrderRemoteDataSource)
class WorkerOrderRemoteDataSourceImpl implements WorkerOrderRemoteDataSource {
  const WorkerOrderRemoteDataSourceImpl(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<WorkerOrderDetailModel> getOrderDetail(String orderId) async {
    final response = await apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.workerOrderDetail(orderId),
    );

    final responseData = response.data!;
    final rawData = responseData['data'];
    final detailJson = rawData is Map<String, dynamic>
        ? rawData
        : rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : responseData;

    return WorkerOrderDetailModel.fromJson(detailJson);
  }

  @override
  Future<void> acceptOrder(String orderId, int? estimatedArrivalMinutes) async {
    await apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.workerOrderAccept(orderId),
      data: {'estimated_arrival_minutes': ?estimatedArrivalMinutes},
    );
  }

  @override
  Future<void> updateOrderStatus(String orderId, String status) async {
    await apiClient.patch<Map<String, dynamic>>(
      ApiEndpoints.workerOrderStatus(orderId),
      data: {'status': status},
    );
  }

  @override
  Future<void> uploadProgressPhoto(
    String orderId,
    String filePath,
    String? caption,
  ) async {
    final formData = FormData.fromMap({
      'photo': await MultipartFile.fromFile(filePath),
      'caption': ?caption,
    });

    await apiClient.upload<Map<String, dynamic>>(
      '/worker/orders/$orderId/photos',
      data: formData,
    );
  }

  @override
  Future<void> addWorkItem({
    required String orderId,
    required String itemName,
    required int cost,
    String? description,
  }) async {
    await apiClient.post<Map<String, dynamic>>(
      '/worker/orders/$orderId/items',
      data: {'item_name': itemName, 'cost': cost, 'description': ?description},
    );
  }

  @override
  Future<InvoiceModel> completeOrder({
    required String orderId,
    String? workerNotes,
    List<InvoiceMaterialInput> materials = const [],
  }) async {
    final invoiceResponse = await apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.workerOrderGenerateInvoice(orderId),
      data: _buildGenerateInvoicePayload(
        workerNotes: workerNotes,
        materials: materials,
      ),
    );

    await apiClient.patch<Map<String, dynamic>>(
      ApiEndpoints.workerOrderStatus(orderId),
      data: {'status': 'completed'},
    );

    final responseData = invoiceResponse.data!;
    final rawData = responseData['data'];
    final invoiceJson = rawData is Map<String, dynamic>
        ? rawData
        : rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : responseData;

    return InvoiceModel.fromJson(_normalizeInvoiceJson(invoiceJson, orderId));
  }

  Map<String, dynamic> _buildGenerateInvoicePayload({
    required String? workerNotes,
    required List<InvoiceMaterialInput> materials,
  }) {
    final purchases = materials.map((material) => material.toJson()).toList();
    final totalMaterialCost = materials.fold<int>(
      0,
      (total, material) => total + material.totalPrice,
    );

    return {
      'purchases': purchases,
      'total_material_cost': totalMaterialCost,
      if (workerNotes != null && workerNotes.trim().isNotEmpty)
        'worker_notes': workerNotes.trim(),
    };
  }

  Map<String, dynamic> _normalizeInvoiceJson(
    Map<String, dynamic> json,
    String orderId,
  ) {
    final createdAt =
        json['created_at'] as String? ?? DateTime.now().toIso8601String();
    final rawItems =
        json['items'] ?? json['line_items'] ?? json['invoice_line_items'];

    return {
      'id': json['invoice_id'] ?? json['id'] ?? '',
      'order_id': json['order_id'] ?? orderId,
      'invoice_number': json['invoice_number'] ?? '',
      'base_service_fee': _asInt(json['base_service_fee']),
      'booking_fee': _asInt(json['booking_fee']),
      'platform_fee': _asInt(json['platform_fee']),
      'materials_total': _asInt(
        json['materials_total'] ?? json['total_material_cost'],
      ),
      'additional_cost_total': _asInt(
        json['additional_cost_total'] ?? json['total_additional_cost'],
      ),
      'discount': _asInt(json['discount'] ?? json['discount_amount']),
      'grand_total': _asInt(json['grand_total']),
      'status': json['status'] ?? json['payment_status'] ?? 'pending',
      'payment_method': json['payment_method'],
      'items': rawItems is List
          ? rawItems.map(_normalizeInvoiceItemJson).toList()
          : <Map<String, dynamic>>[],
      'created_at': createdAt,
      'due_date': json['due_date'] ?? createdAt,
      'paid_at': json['paid_at'],
      'ai_summary': json['ai_summary'] ?? json['ai_work_summary'],
      'worker_notes': json['worker_notes'],
    };
  }

  Map<String, dynamic> _normalizeInvoiceItemJson(dynamic rawItem) {
    final item = rawItem is Map<String, dynamic>
        ? rawItem
        : rawItem is Map
        ? Map<String, dynamic>.from(rawItem)
        : <String, dynamic>{};

    return {
      'id': item['id'] ?? item['purchase_id'] ?? '',
      'name': item['name'] ?? item['label'] ?? item['item_name'] ?? '',
      'quantity': (item['quantity'] as num?)?.toDouble() ?? 1.0,
      'unit_price': _asInt(item['unit_price']),
      'total_price': _asInt(item['total_price'] ?? item['amount']),
      'type': item['type'] ?? item['category'] ?? 'material',
    };
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
