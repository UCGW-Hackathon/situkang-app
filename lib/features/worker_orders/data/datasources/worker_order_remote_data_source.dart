import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../../invoice/data/models/invoice_model.dart';

abstract class WorkerOrderRemoteDataSource {
  Future<void> updateOrderStatus(String orderId, String status);
  
  Future<void> uploadProgressPhoto(String orderId, String filePath, String? caption);
  
  Future<void> addWorkItem({
    required String orderId,
    required String itemName,
    required int cost,
    String? description,
  });
  
  Future<InvoiceModel> completeOrder(String orderId, String? workerNotes);
}

@LazySingleton(as: WorkerOrderRemoteDataSource)
class WorkerOrderRemoteDataSourceImpl implements WorkerOrderRemoteDataSource {
  const WorkerOrderRemoteDataSourceImpl(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<void> updateOrderStatus(String orderId, String status) async {
    await apiClient.patch<Map<String, dynamic>>(
      '/worker/orders/$orderId/status',
      data: {'status': status},
    );
  }

  @override
  Future<void> uploadProgressPhoto(String orderId, String filePath, String? caption) async {
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
      data: {
        'item_name': itemName,
        'cost': cost,
        'description': ?description,
      },
    );
  }

  @override
  Future<InvoiceModel> completeOrder(String orderId, String? workerNotes) async {
    final invoiceResponse = await apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.workerOrderGenerateInvoice(orderId),
      data: {
        'worker_notes': ?workerNotes,
      },
    );

    await apiClient.patch<Map<String, dynamic>>(
      ApiEndpoints.workerOrderStatus(orderId),
      data: {'status': 'completed'},
    );
    
    final apiResponse = ApiResponse<InvoiceModel>.fromJson(
      invoiceResponse.data!,
      fromJsonT: (json) => InvoiceModel.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }
}
