import 'package:equatable/equatable.dart';

import '../../../../core/constants/enums.dart';

/// Represents a worker's summary info within an order.
class OrderWorkerInfo extends Equatable {
  const OrderWorkerInfo({
    required this.workerId,
    required this.fullName,
    this.avatarUrl,
    this.specialization,
    this.phone,
    this.rating,
    this.totalReviews,
    this.isVerified = false,
    this.latitude,
    this.longitude,
  });

  /// Worker's unique identifier.
  final String workerId;

  /// Worker's full name.
  final String fullName;

  /// URL to the worker's avatar image.
  final String? avatarUrl;

  /// Worker's specialization description.
  final String? specialization;

  /// Worker's phone number.
  final String? phone;

  /// Worker's average rating.
  final double? rating;

  /// Worker's total reviews count.
  final int? totalReviews;

  /// Whether the worker is verified.
  final bool isVerified;

  /// Last known worker latitude, if returned by the backend.
  final double? latitude;

  /// Last known worker longitude, if returned by the backend.
  final double? longitude;

  @override
  List<Object?> get props => [
    workerId,
    fullName,
    avatarUrl,
    specialization,
    phone,
    rating,
    totalReviews,
    isVerified,
    latitude,
    longitude,
  ];
}

/// Represents a service's summary info within an order.
class OrderServiceInfo extends Equatable {
  const OrderServiceInfo({
    required this.serviceId,
    required this.name,
    this.category,
  });

  /// Service's unique identifier.
  final String serviceId;

  /// Service name.
  final String name;

  /// Service category name.
  final String? category;

  @override
  List<Object?> get props => [serviceId, name, category];
}

/// Represents a location with coordinates and address.
class OrderLocation extends Equatable {
  const OrderLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.addressDetail,
  });

  /// Latitude coordinate.
  final double latitude;

  /// Longitude coordinate.
  final double longitude;

  /// Full address string.
  final String address;

  /// Additional address details.
  final String? addressDetail;

  @override
  List<Object?> get props => [latitude, longitude, address, addressDetail];
}

/// Represents an order in the SITUKANG platform (list view).
///
/// Used in the orders list screen. Contains summary information
/// about the order including status, worker info, and pricing.
class Order extends Equatable {
  const Order({
    required this.id,
    required this.orderNumber,
    required this.title,
    required this.status,
    required this.createdAt,
    this.userId,
    this.workerId,
    this.serviceId,
    this.categoryId,
    this.workerInfo,
    this.serviceName,
    this.totalPrice,
    this.completedAt,
    this.cancelledAt,
  });

  /// Unique order identifier.
  final String id;

  /// Human-readable order number (e.g., "HD-20231025-001").
  final String orderNumber;

  /// Order title describing the problem.
  final String title;

  /// Current order status.
  final OrderStatus status;

  /// When the order was created.
  final DateTime createdAt;

  /// User who created the order.
  final String? userId;

  /// Worker assigned to the order.
  final String? workerId;

  /// Service ID for this order.
  final String? serviceId;

  /// Category ID for this order.
  final String? categoryId;

  /// Worker summary info.
  final OrderWorkerInfo? workerInfo;

  /// Service name.
  final String? serviceName;

  /// Total price (grand total) in Rupiah.
  final int? totalPrice;

  /// When the order was completed.
  final DateTime? completedAt;

  /// When the order was cancelled.
  final DateTime? cancelledAt;

  @override
  List<Object?> get props => [
    id,
    orderNumber,
    title,
    status,
    createdAt,
    userId,
    workerId,
    serviceId,
    categoryId,
    workerInfo,
    serviceName,
    totalPrice,
    completedAt,
    cancelledAt,
  ];
}
