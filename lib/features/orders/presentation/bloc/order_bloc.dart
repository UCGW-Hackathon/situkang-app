import 'package:injectable/injectable.dart' hide Order;
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/api_response.dart';
import '../../domain/entities/create_order_params.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_detail.dart';
import '../../domain/entities/order_filter.dart';
import '../../domain/repositories/order_repository.dart';

part 'order_event.dart';
part 'order_state.dart';

/// BLoC responsible for managing order state (User side).
///
/// Handles order creation, fetching order lists with filters,
/// viewing order details, and cancelling orders.
///
/// Validates:
/// - Requirement 7.1: Create order with required fields
/// - Requirement 7.7: Worker unavailable error
/// - Requirement 7.8: Validation errors
/// - Requirement 8.1: Orders sorted by creation date (newest first)
/// - Requirement 8.2: Status filter
/// - Requirement 8.3: Order detail with full info
/// - Requirement 8.4: Cancel button for cancellable states
/// - Requirement 8.5: Cancel order with reason
/// - Requirement 8.6: Cancellation not allowed after arrival
@injectable
class OrderBloc extends Bloc<OrderEvent, OrderState> {
  /// Creates an [OrderBloc] with the required repository.
  OrderBloc({
    required OrderRepository orderRepository,
  })  : _orderRepository = orderRepository,
        super(const OrderInitial()) {
    on<CreateOrderRequested>(_onCreateOrderRequested);
    on<FetchOrdersRequested>(_onFetchOrdersRequested);
    on<FetchOrderDetailRequested>(_onFetchOrderDetailRequested);
    on<CancelOrderRequested>(_onCancelOrderRequested);
    on<ApplyStatusFilterRequested>(_onApplyStatusFilterRequested);
  }

  final OrderRepository _orderRepository;

  /// Handles [CreateOrderRequested] events.
  ///
  /// Emits [OrderLoading], then either [OrderCreated] on success
  /// or [OrderError] on failure (e.g., worker unavailable, validation errors).
  Future<void> _onCreateOrderRequested(
    CreateOrderRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderLoading());

    final result = await _orderRepository.createOrder(event.params);

    result.fold(
      (failure) => emit(OrderError(failure: failure)),
      (order) => emit(OrderCreated(order: order)),
    );
  }

  /// Handles [FetchOrdersRequested] events.
  ///
  /// Emits [OrderLoading], then either [OrdersLoaded] on success
  /// or [OrderError] on failure.
  Future<void> _onFetchOrdersRequested(
    FetchOrdersRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderLoading());

    final result = await _orderRepository.getOrders(
      filter: event.filter,
      page: event.page,
    );

    result.fold(
      (failure) => emit(OrderError(failure: failure)),
      (data) => emit(OrdersLoaded(
        orders: data.$1,
        meta: data.$2,
        filter: event.filter,
      )),
    );
  }

  /// Handles [FetchOrderDetailRequested] events.
  ///
  /// Emits [OrderLoading], then either [OrderDetailLoaded] on success
  /// or [OrderError] on failure.
  Future<void> _onFetchOrderDetailRequested(
    FetchOrderDetailRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderLoading());

    final result = await _orderRepository.getOrderDetail(event.orderId);

    result.fold(
      (failure) => emit(OrderError(failure: failure)),
      (orderDetail) => emit(OrderDetailLoaded(orderDetail: orderDetail)),
    );
  }

  /// Handles [CancelOrderRequested] events.
  ///
  /// Emits [OrderLoading], then either [OrderCreated] (with updated order)
  /// on success or [OrderError] on failure (e.g., cancellation not allowed).
  Future<void> _onCancelOrderRequested(
    CancelOrderRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderLoading());

    final result = await _orderRepository.cancelOrder(
      event.orderId,
      event.reason,
    );

    result.fold(
      (failure) => emit(OrderError(failure: failure)),
      (order) => emit(OrderCreated(order: order)),
    );
  }

  /// Handles [ApplyStatusFilterRequested] events.
  ///
  /// Creates a filter with the selected status and fetches orders.
  Future<void> _onApplyStatusFilterRequested(
    ApplyStatusFilterRequested event,
    Emitter<OrderState> emit,
  ) async {
    final filter = event.status != null
        ? OrderFilter(status: event.status)
        : null;

    add(FetchOrdersRequested(filter: filter));
  }
}
