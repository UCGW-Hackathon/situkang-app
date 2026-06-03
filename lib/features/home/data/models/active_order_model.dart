import '../../../../core/constants/enums.dart';
import '../../domain/entities/active_order.dart';

/// Data Transfer Object for active order API responses.
///
/// Maps snake_case JSON fields from the `/home` endpoint to the
/// domain [ActiveOrder] entity.
class ActiveOrderModel {
  const ActiveOrderModel({
    required this.orderId,
    required this.status,
    required this.workerName,
    required this.serviceName,
    this.etaMinutes,
  });

  /// Parses an [ActiveOrderModel] from a JSON map.
  ///
  /// Returns `null` if the JSON is null (no active order).
  static ActiveOrderModel? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return ActiveOrderModel(
      orderId: json['order_id'] as String,
      status: OrderStatus.fromString(json['status'] as String),
      workerName: json['worker_name'] as String,
      serviceName: json['service_name'] as String,
      etaMinutes: json['eta_minutes'] as int?,
    );
  }

  final String orderId;
  final OrderStatus status;
  final String workerName;
  final String serviceName;
  final int? etaMinutes;

  /// Converts this model to a JSON map for caching.
  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'status': status.value,
      'worker_name': workerName,
      'service_name': serviceName,
      'eta_minutes': etaMinutes,
    };
  }

  /// Converts this data model to the domain [ActiveOrder] entity.
  ActiveOrder toEntity() {
    return ActiveOrder(
      orderId: orderId,
      status: status,
      workerName: workerName,
      serviceName: serviceName,
      etaMinutes: etaMinutes,
    );
  }
}
