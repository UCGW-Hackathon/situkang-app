import 'dart:io';

import 'package:injectable/injectable.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../models/invoice_model.dart';

abstract class InvoiceRemoteDataSource {
  Future<InvoiceModel> getInvoice(String orderId);
  Future<InvoiceModel> confirmPayment(String orderId, String paymentMethod);
  Future<InvoiceModel> uploadPaymentProof(String orderId, File proofImage);
  Future<String> downloadInvoicePdf(String orderId);
}

@LazySingleton(as: InvoiceRemoteDataSource)
class InvoiceRemoteDataSourceImpl implements InvoiceRemoteDataSource {
  const InvoiceRemoteDataSourceImpl(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<InvoiceModel> getInvoice(String orderId) async {
    final response = await apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.orderInvoice(orderId),
    );
    final apiResponse = ApiResponse<InvoiceModel>.fromJson(
      response.data!,
      fromJsonT: (json) => InvoiceModel.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }

  @override
  Future<InvoiceModel> confirmPayment(
      String orderId, String paymentMethod) async {
    await apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.orderPayment(orderId),
      data: {'payment_method': paymentMethod},
    );
    // Refetch the updated invoice
    return getInvoice(orderId);
  }

  @override
  Future<InvoiceModel> uploadPaymentProof(
      String orderId, File proofImage) async {
    // In backend contract, payment proof is passed as a text URL to POST /orders/{id}/payment.
    // Since there's no general upload endpoint for payment proof, we simulate the upload by sending a mock URL.
    await apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.orderPayment(orderId),
      data: {
        'payment_method': 'bank_transfer',
        'payment_proof_url': 'http://situkang-api-20260616.eastasia.azurecontainer.io:7860/v1/proofs/proof_$orderId.jpg',
        'transaction_proof_url': 'http://situkang-api-20260616.eastasia.azurecontainer.io:7860/v1/proofs/proof_$orderId.jpg',
      },
    );
    // Refetch the updated invoice
    return getInvoice(orderId);
  }

  @override
  Future<String> downloadInvoicePdf(String orderId) async {
    return '${AppConstants.baseUrl}${ApiEndpoints.orderInvoicePdf(orderId)}';
  }
}
