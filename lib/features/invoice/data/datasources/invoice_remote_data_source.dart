import 'dart:io';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../models/invoice_model.dart';

abstract class InvoiceRemoteDataSource {
  Future<InvoiceModel> getInvoice(String orderId);
  Future<InvoiceModel> confirmPayment(String invoiceId, String paymentMethod);
  Future<InvoiceModel> uploadPaymentProof(String invoiceId, File proofImage);
  Future<String> downloadInvoicePdf(String invoiceId);
}

@LazySingleton(as: InvoiceRemoteDataSource)
class InvoiceRemoteDataSourceImpl implements InvoiceRemoteDataSource {
  const InvoiceRemoteDataSourceImpl(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<InvoiceModel> getInvoice(String orderId) async {
    final response = await apiClient.get<Map<String, dynamic>>(
      '/orders/$orderId/invoice',
    );
    final apiResponse = ApiResponse<InvoiceModel>.fromJson(response.data!, fromJsonT: (json) => InvoiceModel.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }

  @override
  Future<InvoiceModel> confirmPayment(
      String invoiceId, String paymentMethod) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      '/invoices/$invoiceId/pay',
      data: {'payment_method': paymentMethod},
    );
    final apiResponse = ApiResponse<InvoiceModel>.fromJson(response.data!, fromJsonT: (json) => InvoiceModel.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }

  @override
  Future<InvoiceModel> uploadPaymentProof(
      String invoiceId, File proofImage) async {
    final formData = FormData.fromMap({
      'proof': await MultipartFile.fromFile(
        proofImage.path,
        filename: proofImage.path.split('/').last,
      ),
    });

    final response = await apiClient.post<Map<String, dynamic>>(
      '/invoices/$invoiceId/upload-proof',
      data: formData,
    );
    final apiResponse = ApiResponse<InvoiceModel>.fromJson(response.data!, fromJsonT: (json) => InvoiceModel.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }

  @override
  Future<String> downloadInvoicePdf(String invoiceId) async {
    // Note: The actual path depends on the platform, usually handled by path_provider.
    // For now, this returns a dummy URL. In a real app, we might use Dio to download
    // to a temporary directory.
    return 'https://api.situkang.id/v1/invoices/$invoiceId/pdf';
  }
}
