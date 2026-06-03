import 'package:injectable/injectable.dart';
import '../../../../core/storage/cache_manager.dart';
import '../models/order_detail_model.dart';
import '../models/order_model.dart';

/// Local data source for caching order data.
///
/// Uses [CacheManager] to store and retrieve order lists and details
/// for offline access and cache-first read strategy.
abstract class OrderLocalDataSource {
  /// Retrieves the cached order list, or null if not cached or expired.
  Future<List<OrderModel>?> getCachedOrders(String cacheKey);

  /// Caches the order list.
  Future<void> cacheOrders(String cacheKey, List<OrderModel> orders);

  /// Retrieves the cached order detail, or null if not cached or expired.
  Future<OrderDetailModel?> getCachedOrderDetail(String orderId);

  /// Caches an order detail.
  Future<void> cacheOrderDetail(OrderDetailModel order);

  /// Clears all cached order data.
  Future<void> clearCache();
}

/// Implementation of [OrderLocalDataSource] using [CacheManager].
@LazySingleton(as: OrderLocalDataSource)
class OrderLocalDataSourceImpl implements OrderLocalDataSource {
  const OrderLocalDataSourceImpl({required this.cacheManager});

  final CacheManager cacheManager;

  static const String _ordersPrefix = 'orders_';
  static const String _orderDetailPrefix = 'order_detail_';

  @override
  Future<List<OrderModel>?> getCachedOrders(String cacheKey) async {
    final cachedData = await cacheManager.get<List<dynamic>>(
      '$_ordersPrefix$cacheKey',
    );

    if (cachedData == null) return null;
    return cachedData
        .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> cacheOrders(String cacheKey, List<OrderModel> orders) async {
    await cacheManager.put(
      '$_ordersPrefix$cacheKey',
      orders.map((o) => o.toJson()).toList(),
      ttl: const Duration(minutes: 10), // Short TTL for order lists
    );
  }

  @override
  Future<OrderDetailModel?> getCachedOrderDetail(String orderId) async {
    final cachedData = await cacheManager.get<Map<String, dynamic>>(
      '$_orderDetailPrefix$orderId',
    );

    if (cachedData == null) return null;
    return OrderDetailModel.fromJson(cachedData);
  }

  @override
  Future<void> cacheOrderDetail(OrderDetailModel order) async {
    await cacheManager.put(
      '$_orderDetailPrefix${order.orderId}',
      order.toJson(),
      ttl: const Duration(minutes: 15), // Moderate TTL for order details
    );
  }

  @override
  Future<void> clearCache() async {
    // CacheManager doesn't support prefix-based clearing,
    // so we rely on TTL expiration for cleanup.
    // For a full clear, use cacheManager.clearAll() at the app level.
  }
}
