part of 'purchase_bloc.dart';

/// Sealed class representing all purchase management events.
///
/// Events are dispatched from the UI layer to trigger state changes
/// in the [PurchaseBloc].
sealed class PurchaseEvent extends Equatable {
  const PurchaseEvent();

  @override
  List<Object?> get props => [];
}

/// Event dispatched to fetch all purchases for an order.
///
/// Validates: Requirement 10.1 (display purchase items).
class FetchPurchases extends PurchaseEvent {
  /// Creates a [FetchPurchases] event for the given [orderId].
  const FetchPurchases({required this.orderId});

  /// The order ID to fetch purchases for.
  final String orderId;

  @override
  List<Object?> get props => [orderId];
}

/// Event dispatched when the user approves a purchase.
///
/// Only purchases with status "pending_approval" can be approved.
/// Validates: Requirement 10.3.
class ApprovePurchase extends PurchaseEvent {
  /// Creates an [ApprovePurchase] event.
  const ApprovePurchase({
    required this.orderId,
    required this.purchaseId,
  });

  /// The order this purchase belongs to.
  final String orderId;

  /// The purchase to approve.
  final String purchaseId;

  @override
  List<Object?> get props => [orderId, purchaseId];
}

/// Event dispatched when the user rejects a purchase with a reason.
///
/// Requires a reason of 1-1000 characters.
/// Validates: Requirement 10.4.
class RejectPurchase extends PurchaseEvent {
  /// Creates a [RejectPurchase] event.
  const RejectPurchase({
    required this.orderId,
    required this.purchaseId,
    required this.reason,
  });

  /// The order this purchase belongs to.
  final String orderId;

  /// The purchase to reject.
  final String purchaseId;

  /// The rejection reason (1-1000 characters).
  final String reason;

  @override
  List<Object?> get props => [orderId, purchaseId, reason];
}

/// Event dispatched when the user requests clarification on a purchase.
///
/// Requires a question of 1-1000 characters.
/// Validates: Requirement 10.5.
class RequestClarification extends PurchaseEvent {
  /// Creates a [RequestClarification] event.
  const RequestClarification({
    required this.orderId,
    required this.purchaseId,
    required this.question,
  });

  /// The order this purchase belongs to.
  final String orderId;

  /// The purchase to request clarification on.
  final String purchaseId;

  /// The clarification question (1-1000 characters).
  final String question;

  @override
  List<Object?> get props => [orderId, purchaseId, question];
}

/// Event dispatched when the user bulk-approves multiple purchases.
///
/// All selected purchases must have status "pending_approval".
/// Validates: Requirement 10.6.
class BulkApprove extends PurchaseEvent {
  /// Creates a [BulkApprove] event.
  const BulkApprove({
    required this.orderId,
    required this.purchaseIds,
  });

  /// The order these purchases belong to.
  final String orderId;

  /// The list of purchase IDs to approve.
  final List<String> purchaseIds;

  @override
  List<Object?> get props => [orderId, purchaseIds];
}

/// Event dispatched when a new purchase is received via WebSocket.
///
/// Validates: Requirement 10.8 (display within 2 seconds).
class NewPurchaseReceived extends PurchaseEvent {
  /// Creates a [NewPurchaseReceived] event.
  const NewPurchaseReceived({required this.purchase});

  /// The new purchase received from WebSocket.
  final Purchase purchase;

  @override
  List<Object?> get props => [purchase];
}
