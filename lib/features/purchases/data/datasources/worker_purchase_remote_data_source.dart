import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

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
class WorkerPurchaseRemoteDataSourceImpl implements WorkerPurchaseRemoteDataSource {
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
    final formDataMap = <String, dynamic>{
      'item_name': itemName,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      if (reason != null) 'reason': reason,
    };

    if (receiptPhotoPath != null) {
      formDataMap['receipt_photo'] = await MultipartFile.fromFile(receiptPhotoPath);
    }

    final response = await apiClient.upload<Map<String, dynamic>>(
      '/worker/orders/$orderId/purchases',
      data: FormData.fromMap(formDataMap),
    );

    final apiResponse = ApiResponse<PurchaseModel>.fromJson(response.data!, fromJsonT: (json) => PurchaseModel.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }

  @override
  Future<List<PurchaseModel>> processAiInput(String orderId, String rawText) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      '/worker/orders/$orderId/purchases/ai-process',
      data: {'raw_text': rawText},
    );

    final apiResponse = ApiResponse<List<PurchaseModel>>.fromJson(response.data!, fromJsonT: (json) => (json as List)
          .map((e) => PurchaseModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiResponse.data!;
  }

  @override
  Future<List<PurchaseModel>> scanReceipt(String orderId, String photoPath) async {
    final formData = FormData.fromMap({
      'receipt_photo': await MultipartFile.fromFile(photoPath),
    });

    final response = await apiClient.upload<Map<String, dynamic>>(
      '/worker/orders/$orderId/purchases/scan',
      data: formData,
    );

    final apiResponse = ApiResponse<List<PurchaseModel>>.fromJson(response.data!, fromJsonT: (json) => (json as List)
          .map((e) => PurchaseModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiResponse.data!;
  }

  @override
  Future<PurchaseModel> submitForApproval(String orderId, String purchaseId) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      '/worker/orders/$orderId/purchases/$purchaseId/submit',
    );

    final apiResponse = ApiResponse<PurchaseModel>.fromJson(response.data!, fromJsonT: (json) => PurchaseModel.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }

  @override
  Future<void> deleteDraft(String orderId, String purchaseId) async {
    await apiClient.delete<Map<String, dynamic>>(
      '/worker/orders/$orderId/purchases/$purchaseId',
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
    final response = await apiClient.post<Map<String, dynamic>>(
      '/worker/orders/$orderId/purchases/$purchaseId/clarify-response',
      data: {
        'response_text': responseText,
        if (updatedItemName != null) 'updated_item_name': updatedItemName,
        if (updatedReason != null) 'updated_reason': updatedReason,
      },
    );

    final apiResponse = ApiResponse<PurchaseModel>.fromJson(response.data!, fromJsonT: (json) => PurchaseModel.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }
}
