import 'package:injectable/injectable.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/purchase_model.dart';
import '../models/purchase_summary_model.dart';

/// Remote data source for purchase management operations (User side).
///
/// Makes API calls to the purchase endpoints for fetching purchases,
/// approving, rejecting, requesting clarification, and bulk-approving.
abstract class PurchaseRemoteDataSource {
  /// Fetches all purchases for the given [orderId].
  ///
  /// Calls `GET /orders/{orderId}/purchases`.
  /// Returns a list of purchase models and a summary model.
  Future<(List<PurchaseModel>, PurchaseSummaryModel)> getPurchases(
      String orderId);

  /// Approves a purchase.
  ///
  /// Calls `POST /orders/{orderId}/purchases/{purchaseId}/approve`.
  /// Returns the updated purchase model.
  Future<PurchaseModel> approvePurchase(String orderId, String purchaseId);

  /// Rejects a purchase with a reason.
  ///
  /// Calls `POST /orders/{orderId}/purchases/{purchaseId}/reject`.
  /// Returns the updated purchase model.
  Future<PurchaseModel> rejectPurchase(
      String orderId, String purchaseId, String reason);

  /// Requests clarification on a purchase.
  ///
  /// Calls `POST /orders/{orderId}/purchases/{purchaseId}/clarify`.
  /// Returns the updated purchase model.
  Future<PurchaseModel> requestClarification(
      String orderId, String purchaseId, String question);

  /// Bulk-approves multiple purchases.
  ///
  /// Calls `POST /orders/{orderId}/purchases/bulk-approve`.
  /// Returns the list of updated purchase models.
  Future<List<PurchaseModel>> bulkApprove(
      String orderId, List<String> purchaseIds);
}

/// Implementation of [PurchaseRemoteDataSource] using [ApiClient].
@LazySingleton(as: PurchaseRemoteDataSource)
class PurchaseRemoteDataSourceImpl implements PurchaseRemoteDataSource {
  const PurchaseRemoteDataSourceImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<(List<PurchaseModel>, PurchaseSummaryModel)> getPurchases(
      String orderId) async {
    final response = await apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.orderPurchases(orderId),
    );

    final data = response.data!;
    final purchasesJson = data['data'] as List<dynamic>? ?? [];
    final purchases = purchasesJson
        .map((json) => PurchaseModel.fromJson(json as Map<String, dynamic>))
        .toList();

    final summaryJson =
        data['summary'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final summary = PurchaseSummaryModel.fromJson(summaryJson);

    return (purchases, summary);
  }

  @override
  Future<PurchaseModel> approvePurchase(
      String orderId, String purchaseId) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.purchaseApprove(orderId, purchaseId),
    );

    final data = response.data!;
    final purchaseJson = data['data'] as Map<String, dynamic>;
    return PurchaseModel.fromJson(purchaseJson);
  }

  @override
  Future<PurchaseModel> rejectPurchase(
      String orderId, String purchaseId, String reason) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.purchaseReject(orderId, purchaseId),
      data: {'reason': reason},
    );

    final data = response.data!;
    final purchaseJson = data['data'] as Map<String, dynamic>;
    return PurchaseModel.fromJson(purchaseJson);
  }

  @override
  Future<PurchaseModel> requestClarification(
      String orderId, String purchaseId, String question) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.purchaseClarify(orderId, purchaseId),
      data: {'question': question},
    );

    final data = response.data!;
    final purchaseJson = data['data'] as Map<String, dynamic>;
    return PurchaseModel.fromJson(purchaseJson);
  }

  @override
  Future<List<PurchaseModel>> bulkApprove(
      String orderId, List<String> purchaseIds) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.purchasesBulkApprove(orderId),
      data: {'purchase_ids': purchaseIds},
    );

    final data = response.data!;
    final purchasesJson = data['data'] as List<dynamic>? ?? [];
    return purchasesJson
        .map((json) => PurchaseModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
