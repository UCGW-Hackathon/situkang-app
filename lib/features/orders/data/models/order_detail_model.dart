import '../../../../core/constants/enums.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_detail.dart';
import 'order_model.dart';

/// Data model for the full order detail, mapping API JSON to domain entity.
///
/// Handles the order detail response format from `GET /orders/{order_id}`.
class OrderDetailModel {
  const OrderDetailModel({
    required this.orderId,
    required this.orderNumber,
    required this.title,
    required this.description,
    required this.status,
    required this.urgency,
    required this.location,
    required this.createdAt,
    this.userId,
    this.workerId,
    this.serviceId,
    this.categoryId,
    this.worker,
    this.service,
    this.preferredDate,
    this.preferredTimeStart,
    this.preferredTimeEnd,
    this.notes,
    this.bookingFee = 2000,
    this.baseServiceFee,
    this.totalMaterialCost = 0,
    this.totalAdditionalCost = 0,
    this.grandTotal,
    this.photos = const [],
    this.acceptedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancelReason,
    this.timeline = const [],
    this.purchaseSummary,
    this.hasUnreadChat = false,
    this.canCancel = false,
    this.cancellationPolicy,
    this.updatedAt,
  });

  /// Creates an [OrderDetailModel] from a JSON map.
  factory OrderDetailModel.fromJson(Map<String, dynamic> json) {
    // Parse location
    final locationJson = json['location'] as Map<String, dynamic>? ?? {};
    final locationModel = OrderLocationModel.fromJson(locationJson);

    // Parse worker
    OrderWorkerInfoModel? worker;
    if (json['worker'] is Map<String, dynamic>) {
      worker = OrderWorkerInfoModel.fromJson(
          json['worker'] as Map<String, dynamic>);
    }

    // Parse service
    OrderServiceInfoModel? service;
    if (json['service'] is Map<String, dynamic>) {
      service = OrderServiceInfoModel.fromJson(
          json['service'] as Map<String, dynamic>);
    }

    // Parse schedule
    final scheduleJson = json['schedule'] as Map<String, dynamic>?;
    String? preferredDate;
    String? preferredTimeStart;
    String? preferredTimeEnd;
    if (scheduleJson != null) {
      preferredDate = scheduleJson['preferred_date'] as String?;
      preferredTimeStart = scheduleJson['preferred_time_start'] as String?;
      preferredTimeEnd = scheduleJson['preferred_time_end'] as String?;
    }

    // Parse pricing
    final pricingJson = json['pricing'] as Map<String, dynamic>?;
    var bookingFee = 2000;
    int? baseServiceFee;
    var totalMaterialCost = 0;
    var totalAdditionalCost = 0;
    int? grandTotal;
    if (pricingJson != null) {
      bookingFee = pricingJson['booking_fee'] as int? ?? 2000;
      baseServiceFee = pricingJson['base_service_fee'] as int?;
      totalMaterialCost = pricingJson['total_material_cost'] as int? ?? 0;
      totalAdditionalCost = pricingJson['total_additional_cost'] as int? ?? 0;
      grandTotal = pricingJson['grand_total'] as int?;
    }

    // Parse timeline
    final timelineJson = json['timeline'] as List<dynamic>? ?? [];
    final timeline = timelineJson
        .map((t) =>
            OrderTimelineEntryModel.fromJson(t as Map<String, dynamic>))
        .toList();

    // Parse purchase summary
    OrderPurchaseSummaryModel? purchaseSummary;
    if (json['purchase_summary'] is Map<String, dynamic>) {
      purchaseSummary = OrderPurchaseSummaryModel.fromJson(
          json['purchase_summary'] as Map<String, dynamic>);
    }

    // Parse photos
    final photosJson = json['photos'] as List<dynamic>? ?? [];
    final photos = photosJson.map((p) => p.toString()).toList();

    return OrderDetailModel(
      orderId: json['order_id'] as String? ?? '',
      orderNumber: json['order_number'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: OrderStatus.fromString(json['status'] as String? ?? 'pending'),
      urgency:
          OrderUrgency.fromString(json['urgency'] as String? ?? 'normal'),
      location: locationModel,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      userId: json['user_id'] as String?,
      workerId: json['worker_id'] as String?,
      serviceId: json['service_id'] as String?,
      categoryId: json['category_id'] as String?,
      worker: worker,
      service: service,
      preferredDate: preferredDate,
      preferredTimeStart: preferredTimeStart,
      preferredTimeEnd: preferredTimeEnd,
      notes: json['notes'] as String?,
      bookingFee: bookingFee,
      baseServiceFee: baseServiceFee,
      totalMaterialCost: totalMaterialCost,
      totalAdditionalCost: totalAdditionalCost,
      grandTotal: grandTotal,
      photos: photos,
      acceptedAt: json['accepted_at'] != null
          ? DateTime.tryParse(json['accepted_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.tryParse(json['cancelled_at'] as String)
          : null,
      cancelReason: json['cancel_reason'] as String?,
      timeline: timeline,
      purchaseSummary: purchaseSummary,
      hasUnreadChat: json['has_unread_chat'] as bool? ?? false,
      canCancel: json['can_cancel'] as bool? ?? false,
      cancellationPolicy: json['cancellation_policy'] as String?,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  final String orderId;
  final String orderNumber;
  final String title;
  final String description;
  final OrderStatus status;
  final OrderUrgency urgency;
  final OrderLocationModel location;
  final DateTime createdAt;
  final String? userId;
  final String? workerId;
  final String? serviceId;
  final String? categoryId;
  final OrderWorkerInfoModel? worker;
  final OrderServiceInfoModel? service;
  final String? preferredDate;
  final String? preferredTimeStart;
  final String? preferredTimeEnd;
  final String? notes;
  final int bookingFee;
  final int? baseServiceFee;
  final int totalMaterialCost;
  final int totalAdditionalCost;
  final int? grandTotal;
  final List<String> photos;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancelReason;
  final List<OrderTimelineEntryModel> timeline;
  final OrderPurchaseSummaryModel? purchaseSummary;
  final bool hasUnreadChat;
  final bool canCancel;
  final String? cancellationPolicy;
  final DateTime? updatedAt;

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() => {
        'order_id': orderId,
        'order_number': orderNumber,
        'title': title,
        'description': description,
        'status': status.value,
        'urgency': urgency.value,
        'location': location.toJson(),
        'created_at': createdAt.toIso8601String(),
        'user_id': userId,
        'worker_id': workerId,
        'service_id': serviceId,
        'category_id': categoryId,
        'worker': worker?.toJson(),
        'service': service?.toJson(),
        'schedule': {
          'preferred_date': preferredDate,
          'preferred_time_start': preferredTimeStart,
          'preferred_time_end': preferredTimeEnd,
        },
        'pricing': {
          'booking_fee': bookingFee,
          'base_service_fee': baseServiceFee,
          'total_material_cost': totalMaterialCost,
          'total_additional_cost': totalAdditionalCost,
          'grand_total': grandTotal,
        },
        'notes': notes,
        'photos': photos,
        'accepted_at': acceptedAt?.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        'cancelled_at': cancelledAt?.toIso8601String(),
        'cancel_reason': cancelReason,
        'timeline': timeline.map((t) => t.toJson()).toList(),
        'purchase_summary': purchaseSummary?.toJson(),
        'has_unread_chat': hasUnreadChat,
        'can_cancel': canCancel,
        'cancellation_policy': cancellationPolicy,
        'updated_at': updatedAt?.toIso8601String(),
      };

  /// Converts this model to a domain [OrderDetail] entity.
  OrderDetail toEntity() => OrderDetail(
        id: orderId,
        orderNumber: orderNumber,
        title: title,
        description: description,
        status: status,
        urgency: urgency,
        location: location.toEntity(),
        createdAt: createdAt,
        userId: userId,
        workerId: worker?.workerId ?? workerId,
        serviceId: service?.serviceId ?? serviceId,
        categoryId: categoryId,
        workerInfo: worker?.toEntity(),
        serviceInfo: service?.toEntity(),
        preferredDate: preferredDate != null
            ? DateTime.tryParse(preferredDate!)
            : null,
        preferredTimeStart: preferredTimeStart,
        preferredTimeEnd: preferredTimeEnd,
        notes: notes,
        addressDetail: location.addressDetail,
        bookingFee: bookingFee,
        baseServiceFee: baseServiceFee,
        totalMaterialCost: totalMaterialCost,
        totalAdditionalCost: totalAdditionalCost,
        grandTotal: grandTotal,
        photos: photos,
        acceptedAt: acceptedAt,
        completedAt: completedAt,
        cancelledAt: cancelledAt,
        cancelReason: cancelReason,
        timeline: timeline.map((t) => t.toEntity()).toList(),
        purchaseSummary: purchaseSummary?.toEntity(),
        hasUnreadChat: hasUnreadChat,
        canCancel: canCancel,
        cancellationPolicy: cancellationPolicy,
        updatedAt: updatedAt,
      );
}

/// Data model for order location.
class OrderLocationModel {
  const OrderLocationModel({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.addressDetail,
  });

  /// Creates an [OrderLocationModel] from a JSON map.
  factory OrderLocationModel.fromJson(Map<String, dynamic> json) {
    return OrderLocationModel(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      address: json['address'] as String? ?? '',
      addressDetail: json['address_detail'] as String?,
    );
  }

  final double latitude;
  final double longitude;
  final String address;
  final String? addressDetail;

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'address_detail': addressDetail,
      };

  /// Converts this model to a domain [OrderLocation] entity.
  OrderLocation toEntity() => OrderLocation(
        latitude: latitude,
        longitude: longitude,
        address: address,
        addressDetail: addressDetail,
      );
}

/// Data model for service info within an order.
class OrderServiceInfoModel {
  const OrderServiceInfoModel({
    required this.serviceId,
    required this.name,
    this.category,
  });

  /// Creates an [OrderServiceInfoModel] from a JSON map.
  factory OrderServiceInfoModel.fromJson(Map<String, dynamic> json) {
    return OrderServiceInfoModel(
      serviceId: json['service_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String?,
    );
  }

  final String serviceId;
  final String name;
  final String? category;

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() => {
        'service_id': serviceId,
        'name': name,
        'category': category,
      };

  /// Converts this model to a domain [OrderServiceInfo] entity.
  OrderServiceInfo toEntity() => OrderServiceInfo(
        serviceId: serviceId,
        name: name,
        category: category,
      );
}

/// Data model for timeline entries.
class OrderTimelineEntryModel {
  const OrderTimelineEntryModel({
    required this.event,
    required this.label,
    required this.isCompleted,
    this.timestamp,
  });

  /// Creates an [OrderTimelineEntryModel] from a JSON map.
  factory OrderTimelineEntryModel.fromJson(Map<String, dynamic> json) {
    return OrderTimelineEntryModel(
      event: json['event'] as String? ?? '',
      label: json['label'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String)
          : null,
      isCompleted: json['is_completed'] as bool? ?? false,
    );
  }

  final String event;
  final String label;
  final DateTime? timestamp;
  final bool isCompleted;

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() => {
        'event': event,
        'label': label,
        'timestamp': timestamp?.toIso8601String(),
        'is_completed': isCompleted,
      };

  /// Converts this model to a domain [OrderTimelineEntry] entity.
  OrderTimelineEntry toEntity() => OrderTimelineEntry(
        event: event,
        label: label,
        timestamp: timestamp,
        isCompleted: isCompleted,
      );
}

/// Data model for purchase summary within an order.
class OrderPurchaseSummaryModel {
  const OrderPurchaseSummaryModel({
    this.totalItems = 0,
    this.totalCost = 0,
    this.pendingApproval = 0,
    this.approved = 0,
    this.rejected = 0,
  });

  /// Creates an [OrderPurchaseSummaryModel] from a JSON map.
  factory OrderPurchaseSummaryModel.fromJson(Map<String, dynamic> json) {
    return OrderPurchaseSummaryModel(
      totalItems: json['total_items'] as int? ?? 0,
      totalCost: json['total_cost'] as int? ?? 0,
      pendingApproval: json['pending_approval'] as int? ?? 0,
      approved: json['approved'] as int? ?? 0,
      rejected: json['rejected'] as int? ?? 0,
    );
  }

  final int totalItems;
  final int totalCost;
  final int pendingApproval;
  final int approved;
  final int rejected;

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() => {
        'total_items': totalItems,
        'total_cost': totalCost,
        'pending_approval': pendingApproval,
        'approved': approved,
        'rejected': rejected,
      };

  /// Converts this model to a domain [OrderPurchaseSummary] entity.
  OrderPurchaseSummary toEntity() => OrderPurchaseSummary(
        totalItems: totalItems,
        totalCost: totalCost,
        pendingApproval: pendingApproval,
        approved: approved,
        rejected: rejected,
      );
}
