import '../../../../core/error/result.dart';
import '../entities/purchase.dart';
import '../entities/purchase_summary.dart';

/// Abstract repository interface for purchase management (User side).
///
/// Defines the contract for fetching purchases, approving, rejecting,
/// requesting clarification, and bulk-approving purchases associated
/// with an order. All methods return [Result] for functional error handling.
abstract class PurchaseRepository {
  /// Fetches all purchases for the given [orderId].
  ///
  /// Returns a list of [Purchase] entities and a [PurchaseSummary].
  /// May fail with [ServerFailure] on API errors or [NetworkFailure]
  /// when offline.
  Future<Result<(List<Purchase>, PurchaseSummary)>> getPurchases(
      String orderId);

  /// Approves a purchase with the given [purchaseId] on [orderId].
  ///
  /// Only purchases with status "pending_approval" can be approved.
  /// Returns the updated [Purchase] on success.
  /// May fail with [ServerFailure] if the purchase is not in an actionable state.
  Future<Result<Purchase>> approvePurchase(String orderId, String purchaseId);

  /// Rejects a purchase with the given [purchaseId] on [orderId].
  ///
  /// Requires a [reason] (1-1000 characters) explaining the rejection.
  /// Only purchases with status "pending_approval" can be rejected.
  /// Returns the updated [Purchase] on success.
  Future<Result<Purchase>> rejectPurchase(
      String orderId, String purchaseId, String reason);

  /// Requests clarification on a purchase with the given [purchaseId].
  ///
  /// Requires a [question] (1-1000 characters) to send to the worker.
  /// Only purchases with status "pending_approval" can receive clarification requests.
  /// Returns the updated [Purchase] on success.
  Future<Result<Purchase>> requestClarification(
      String orderId, String purchaseId, String question);

  /// Bulk-approves multiple purchases for the given [orderId].
  ///
  /// All [purchaseIds] must reference purchases with status "pending_approval".
  /// Returns the list of updated [Purchase] entities on success.
  Future<Result<List<Purchase>>> bulkApprove(
      String orderId, List<String> purchaseIds);
}
