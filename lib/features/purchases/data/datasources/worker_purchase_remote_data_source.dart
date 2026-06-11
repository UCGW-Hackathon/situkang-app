import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../models/purchase_model.dart';

abstract class WorkerPurchaseRemoteDataSource {
  Future<PurchaseModel> addPurchase({
    required String orderId,
    required String itemName,
    required String category,
    required int quantity,
    required String unit,
    required int unitPrice,
    required int totalPrice,
    String? reason,
    String? receiptPhotoPath,
  });

  Future<List<PurchaseModel>> processAiInput(String orderId, String rawText);

  Future<List<PurchaseModel>> scanReceipt(String orderId, String photoPath);

  Future<PurchaseModel> submitForApproval(String orderId, String purchaseId);

  Future<void> deleteDraft(String orderId, String purchaseId);

  Future<PurchaseModel> respondToClarification({
    required String orderId,
    required String purchaseId,
    required String responseText,
    String? updatedItemName,
    String? updatedReason,
  });
}

@LazySingleton(as: WorkerPurchaseRemoteDataSource)
class WorkerPurchaseRemoteDataSourceImpl
    implements WorkerPurchaseRemoteDataSource {
  const WorkerPurchaseRemoteDataSourceImpl(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<PurchaseModel> addPurchase({
    required String orderId,
    required String itemName,
    required String category,
    required int quantity,
    required String unit,
    required int unitPrice,
    required int totalPrice,
    String? reason,
    String? receiptPhotoPath,
  }) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.workerOrderPurchases(orderId),
      data: <String, dynamic>{
        'item_name': itemName,
        'category': category,
        'quantity': quantity,
        'unit': unit,
        'unit_price': unitPrice,
        'total_price': totalPrice,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );

    final apiResponse = ApiResponse<PurchaseModel>.fromJson(
      response.data!,
      fromJsonT: (json) => PurchaseModel.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }

  @override
  Future<List<PurchaseModel>> processAiInput(
    String orderId,
    String rawText,
  ) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.workerPurchaseAiProcess(orderId),
      data: {'raw_input': rawText},
    );

    final apiResponse = ApiResponse<List<PurchaseModel>>.fromJson(
      response.data!,
      fromJsonT: (json) => (json as List)
          .map((e) => PurchaseModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiResponse.data!;
  }

  @override
  Future<List<PurchaseModel>> scanReceipt(
    String orderId,
    String photoPath,
  ) async {
    final formData = FormData.fromMap({
      'receipt': await MultipartFile.fromFile(photoPath),
    });

    final response = await apiClient.upload<Map<String, dynamic>>(
      ApiEndpoints.workerPurchaseReceiptScan(orderId),
      data: formData,
    );

    final apiResponse = ApiResponse<List<PurchaseModel>>.fromJson(
      response.data!,
      fromJsonT: (json) => (json as List)
          .map((e) => PurchaseModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiResponse.data!;
  }

  @override
  Future<PurchaseModel> submitForApproval(
    String orderId,
    String purchaseId,
  ) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.workerPurchaseSubmit(orderId, purchaseId),
    );

    final apiResponse = ApiResponse<PurchaseModel>.fromJson(
      response.data!,
      fromJsonT: (json) => PurchaseModel.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }

  @override
  Future<void> deleteDraft(String orderId, String purchaseId) async {
    await apiClient.delete<Map<String, dynamic>>(
      ApiEndpoints.workerPurchaseDetail(orderId, purchaseId),
    );
  }

  @override
  Future<PurchaseModel> respondToClarification({
    required String orderId,
    required String purchaseId,
    required String responseText,
    String? updatedItemName,
    String? updatedReason,
  }) async {
    final response = await apiClient.patch<Map<String, dynamic>>(
      ApiEndpoints.workerPurchaseClarifyResponse(orderId, purchaseId),
      data: {
        'response': responseText,
        'updated_item_name': ?updatedItemName,
        'updated_reason': ?updatedReason,
      },
    );

    final apiResponse = ApiResponse<PurchaseModel>.fromJson(
      response.data!,
      fromJsonT: (json) => PurchaseModel.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }
}
