import '../../../../core/constants/enums.dart';
import '../../domain/entities/order.dart';

/// Data model for an order in the list view, mapping API JSON to domain entity.
///
/// Handles the order list response format from `GET /orders`.
class OrderModel {
  const OrderModel({
    required this.orderId,
    required this.orderNumber,
    required this.title,
    required this.status,
    required this.createdAt,
    this.userId,
    this.workerId,
    this.serviceId,
    this.categoryId,
    this.worker,
    this.serviceName,
    this.totalPrice,
    this.completedAt,
    this.cancelledAt,
    this.bookingFee,
    this.estimatedBasePrice,
    this.workerName,
  });

  /// Creates an [OrderModel] from a JSON map.
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    OrderWorkerInfoModel? worker;
    if (json['worker'] is Map<String, dynamic>) {
      worker = OrderWorkerInfoModel.fromJson(
        json['worker'] as Map<String, dynamic>,
      );
    }

    return OrderModel(
      orderId: json['order_id'] as String? ?? json['id'] as String? ?? '',
      orderNumber: json['order_number'] as String? ?? '',
      title: json['title'] as String? ?? '',
      status: OrderStatus.fromString(json['status'] as String? ?? 'pending'),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      userId: json['user_id'] as String?,
      workerId: json['worker_id'] as String?,
      serviceId: json['service_id'] as String?,
      categoryId: json['category_id'] as String?,
      worker: worker,
      serviceName: json['service_name'] as String?,
      totalPrice: json['total_price'] as int?,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.tryParse(json['cancelled_at'] as String)
          : null,
      bookingFee: json['booking_fee'] as int?,
      estimatedBasePrice: json['estimated_base_price'] as int?,
      workerName: json['worker_name'] as String?,
    );
  }

  final String orderId;
  final String orderNumber;
  final String title;
  final OrderStatus status;
  final DateTime createdAt;
  final String? userId;
  final String? workerId;
  final String? serviceId;
  final String? categoryId;
  final OrderWorkerInfoModel? worker;
  final String? serviceName;
  final int? totalPrice;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final int? bookingFee;
  final int? estimatedBasePrice;
  final String? workerName;

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() => {
    'order_id': orderId,
    'order_number': orderNumber,
    'title': title,
    'status': status.value,
    'created_at': createdAt.toIso8601String(),
    'user_id': userId,
    'worker_id': workerId,
    'service_id': serviceId,
    'category_id': categoryId,
    'worker': worker?.toJson(),
    'service_name': serviceName,
    'total_price': totalPrice,
    'completed_at': completedAt?.toIso8601String(),
    'cancelled_at': cancelledAt?.toIso8601String(),
    'booking_fee': bookingFee,
    'estimated_base_price': estimatedBasePrice,
    'worker_name': workerName,
  };

  /// Converts this model to a domain [Order] entity.
  Order toEntity() => Order(
    id: orderId,
    orderNumber: orderNumber,
    title: title,
    status: status,
    createdAt: createdAt,
    userId: userId,
    workerId: worker?.workerId ?? workerId,
    serviceId: serviceId,
    categoryId: categoryId,
    workerInfo: worker?.toEntity(),
    serviceName: serviceName,
    totalPrice: totalPrice,
    completedAt: completedAt,
    cancelledAt: cancelledAt,
  );
}

/// Data model for worker info within an order.
class OrderWorkerInfoModel {
  const OrderWorkerInfoModel({
    required this.workerId,
    required this.fullName,
    this.avatarUrl,
    this.specialization,
    this.phone,
    this.rating,
    this.totalReviews,
    this.isVerified = false,
  });

  /// Creates an [OrderWorkerInfoModel] from a JSON map.
  factory OrderWorkerInfoModel.fromJson(Map<String, dynamic> json) {
    return OrderWorkerInfoModel(
      workerId: json['worker_id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      specialization: json['specialization'] as String?,
      phone: json['phone'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      totalReviews: json['total_reviews'] as int?,
      isVerified: json['is_verified'] as bool? ?? false,
    );
  }

  final String workerId;
  final String fullName;
  final String? avatarUrl;
  final String? specialization;
  final String? phone;
  final double? rating;
  final int? totalReviews;
  final bool isVerified;

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() => {
    'worker_id': workerId,
    'full_name': fullName,
    'avatar_url': avatarUrl,
    'specialization': specialization,
    'phone': phone,
    'rating': rating,
    'total_reviews': totalReviews,
    'is_verified': isVerified,
  };

  /// Converts this model to a domain [OrderWorkerInfo] entity.
  OrderWorkerInfo toEntity() => OrderWorkerInfo(
    workerId: workerId,
    fullName: fullName,
    avatarUrl: avatarUrl,
    specialization: specialization,
    phone: phone,
    rating: rating,
    totalReviews: totalReviews,
    isVerified: isVerified,
  );
}
