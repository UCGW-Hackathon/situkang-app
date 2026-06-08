import 'package:situkang_app/core/error/result.dart';

import '../../../orders/domain/entities/order.dart';

/// Repository interface for managing incoming orders for a worker.
abstract class IncomingOrderRepository {
  /// Fetches pending incoming orders for the worker.
  Future<Result<List<Order>>> getIncomingOrders();

  /// Accepts an incoming order.
  /// Optionally providing an estimated arrival time in minutes.
  Future<Result<void>> acceptOrder({
    required String orderId,
    int? estimatedArrivalMinutes,
  });

  /// Rejects an incoming order with a specified reason.
  Future<Result<void>> rejectOrder({
    required String orderId,
    required String reasonCode,
  });
}
