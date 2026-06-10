import '../../../../core/error/result.dart';
import '../../../../core/network/api_response.dart';
import '../entities/create_order_params.dart';
import '../entities/order.dart';
import '../entities/order_detail.dart';
import '../entities/order_filter.dart';

/// Abstract repository interface for order management (User side).
///
/// Defines the contract for creating orders, fetching order lists with
/// filters and pagination, viewing order details, and cancelling orders.
/// Implementations should use a cache-first strategy for detail views
/// and cache order lists for offline access.
abstract class OrderRepository {
  /// Creates a new order with the given [params].
  ///
  /// Returns the created [Order] on success.
  /// May fail with [ServerFailure] if the worker is unavailable
  /// or [ValidationFailure] if required fields are missing/invalid.
  Future<Result<Order>> createOrder(CreateOrderParams params);

  /// Fetches the user's order list with optional [filter] and pagination.
  ///
  /// Orders are sorted by creation date (newest first) by default.
  /// Results are paginated with [page] and [perPage] parameters.
  Future<Result<(List<Order>, PaginationMeta)>> getOrders({
    OrderFilter? filter,
    int page = 1,
    int perPage = 10,
  });

  /// Fetches the full detail of a specific order by [orderId].
  ///
  /// Returns cached data if available on network failure.
  Future<Result<OrderDetail>> getOrderDetail(String orderId);

  /// Cancels an order with the given [orderId], [cancelReason], and optional
  /// [notes].
  ///
  /// Only orders in cancellable states (pending, accepted, on_the_way)
  /// can be cancelled. Returns the updated order data on success.
  Future<Result<Order>> cancelOrder(
    String orderId, {
    required String cancelReason,
    String? notes,
  });
}
