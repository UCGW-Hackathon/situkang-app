part of 'order_bloc.dart';

/// Sealed class representing all order-related states.
///
/// The [OrderBloc] emits these states in response to [OrderEvent]s,
/// driving the UI to display the appropriate screen or feedback.
sealed class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];
}

/// The initial state before any order action has been taken.
class OrderInitial extends OrderState {
  const OrderInitial();
}

/// State emitted while an order operation is in progress.
///
/// The UI should display a loading indicator when in this state.
class OrderLoading extends OrderState {
  const OrderLoading();
}

/// State emitted when the order list has been successfully loaded.
///
/// Contains the list of orders, pagination metadata, and the current filter.
/// Validates: Requirement 8.1 (orders sorted by creation date, newest first).
class OrdersLoaded extends OrderState {
  const OrdersLoaded({
    required this.orders,
    required this.meta,
    this.filter,
  });

  /// The list of orders for the current page.
  final List<Order> orders;

  /// Pagination metadata.
  final PaginationMeta meta;

  /// The currently applied filter.
  final OrderFilter? filter;

  @override
  List<Object?> get props => [orders, meta, filter];
}

/// State emitted when a single order's full detail has been loaded.
///
/// Validates: Requirement 8.3 (full order information).
class OrderDetailLoaded extends OrderState {
  const OrderDetailLoaded({required this.orderDetail});

  /// The full order detail.
  final OrderDetail orderDetail;

  @override
  List<Object?> get props => [orderDetail];
}

/// State emitted when an order has been successfully created.
///
/// Validates: Requirement 7.1 (order created with status "pending").
class OrderCreated extends OrderState {
  const OrderCreated({required this.order});

  /// The newly created order.
  final Order order;

  @override
  List<Object?> get props => [order];
}

/// State emitted when an order operation fails.
///
/// Contains the [Failure] describing what went wrong, enabling the UI
/// to display appropriate error messages.
///
/// Handles:
/// - Worker unavailable (Requirement 7.7)
/// - Validation errors (Requirement 7.8)
/// - Cancellation not allowed (Requirement 8.6)
class OrderError extends OrderState {
  const OrderError({required this.failure});

  /// The failure describing what went wrong.
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
