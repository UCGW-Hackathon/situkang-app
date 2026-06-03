import 'package:equatable/equatable.dart';

import '../../../../core/constants/enums.dart';

/// Represents the user's currently active order displayed on the home screen.
///
/// Shown as a banner when the user has an order with status:
/// pending, accepted, on_the_way, arrived, or in_progress.
class ActiveOrder extends Equatable {
  const ActiveOrder({
    required this.orderId,
    required this.status,
    required this.workerName,
    required this.serviceName,
    this.etaMinutes,
  });

  /// The unique order identifier.
  final String orderId;

  /// Current order status.
  final OrderStatus status;

  /// Name of the assigned worker.
  final String workerName;

  /// Name of the booked service.
  final String serviceName;

  /// Estimated time of arrival in minutes, or null if not available.
  final int? etaMinutes;

  @override
  List<Object?> get props => [
        orderId,
        status,
        workerName,
        serviceName,
        etaMinutes,
      ];
}
