part of 'order_bloc.dart';

/// Sealed class representing all order-related events.
///
/// Events are dispatched from the UI layer to trigger state changes
/// in the [OrderBloc].
sealed class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object?> get props => [];
}

/// Event dispatched when the user submits a new order.
///
/// Validates: Requirement 7.1 (create order with required fields).
class CreateOrderRequested extends OrderEvent {
  const CreateOrderRequested({required this.params});

  /// The order creation parameters.
  final CreateOrderParams params;

  @override
  List<Object?> get props => [params];
}

/// Event dispatched to fetch the user's order list.
///
/// Validates: Requirement 8.1 (display orders sorted by creation date).
class FetchOrdersRequested extends OrderEvent {
  const FetchOrdersRequested({
    this.filter,
    this.page = 1,
  });

  /// Optional filter to apply (e.g., status filter).
  final OrderFilter? filter;

  /// Page number for pagination.
  final int page;

  @override
  List<Object?> get props => [filter, page];
}

/// Event dispatched to fetch the full detail of a specific order.
///
/// Validates: Requirement 8.3 (navigate to order detail screen).
class FetchOrderDetailRequested extends OrderEvent {
  const FetchOrderDetailRequested({required this.orderId});

  /// The ID of the order to fetch.
  final String orderId;

  @override
  List<Object?> get props => [orderId];
}

/// Event dispatched when the user cancels an order.
///
/// Validates: Requirement 8.5 (cancel order with reason).
class CancelOrderRequested extends OrderEvent {
  const CancelOrderRequested({
    required this.orderId,
    required this.reason,
  });

  /// The ID of the order to cancel.
  final String orderId;

  /// The reason for cancellation.
  final String reason;

  @override
  List<Object?> get props => [orderId, reason];
}

/// Event dispatched when the user applies a status filter.
///
/// Validates: Requirement 8.2 (filter orders by status).
class ApplyStatusFilterRequested extends OrderEvent {
  const ApplyStatusFilterRequested({this.status});

  /// The status to filter by. Null means show all orders.
  final OrderStatus? status;

  @override
  List<Object?> get props => [status];
}
