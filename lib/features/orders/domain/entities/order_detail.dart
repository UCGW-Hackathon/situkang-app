import 'package:equatable/equatable.dart';

import '../../../../core/constants/enums.dart';
import 'order.dart';

/// Represents a timeline entry in the order progress.
class OrderTimelineEntry extends Equatable {
  const OrderTimelineEntry({
    required this.event,
    required this.label,
    required this.isCompleted,
    this.timestamp,
  });

  /// Event identifier (e.g., "order_created", "order_accepted").
  final String event;

  /// Human-readable label for the event.
  final String label;

  /// When this event occurred.
  final DateTime? timestamp;

  /// Whether this step has been completed.
  final bool isCompleted;

  @override
  List<Object?> get props => [event, label, timestamp, isCompleted];
}

/// Represents a purchase summary within an order detail.
class OrderPurchaseSummary extends Equatable {
  const OrderPurchaseSummary({
    this.totalItems = 0,
    this.totalCost = 0,
    this.pendingApproval = 0,
    this.approved = 0,
    this.rejected = 0,
  });

  /// Total number of purchase items.
  final int totalItems;

  /// Total cost of all purchases.
  final int totalCost;

  /// Number of items pending approval.
  final int pendingApproval;

  /// Number of approved items.
  final int approved;

  /// Number of rejected items.
  final int rejected;

  @override
  List<Object?> get props => [
        totalItems,
        totalCost,
        pendingApproval,
        approved,
        rejected,
      ];
}

/// Represents the full detail of an order.
///
/// Used in the order detail screen. Contains all information about
/// the order including worker details, service, location, schedule,
/// pricing breakdown, photos, notes, timeline, and purchase summary.
class OrderDetail extends Equatable {
  const OrderDetail({
    required this.id,
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
    this.workerInfo,
    this.serviceInfo,
    this.preferredDate,
    this.preferredTimeStart,
    this.preferredTimeEnd,
    this.notes,
    this.addressDetail,
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

  /// Unique order identifier.
  final String id;

  /// Human-readable order number.
  final String orderNumber;

  /// Order title.
  final String title;

  /// Problem description.
  final String description;

  /// Current order status.
  final OrderStatus status;

  /// Order urgency level.
  final OrderUrgency urgency;

  /// Work location.
  final OrderLocation location;

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

  /// Worker detailed info.
  final OrderWorkerInfo? workerInfo;

  /// Service detailed info.
  final OrderServiceInfo? serviceInfo;

  /// Preferred date for the service.
  final DateTime? preferredDate;

  /// Preferred start time (as "HH:MM" string).
  final String? preferredTimeStart;

  /// Preferred end time (as "HH:MM" string).
  final String? preferredTimeEnd;

  /// Additional notes for the worker.
  final String? notes;

  /// Additional address details.
  final String? addressDetail;

  /// Booking fee in Rupiah (default Rp2.000).
  final int bookingFee;

  /// Base service fee in Rupiah.
  final int? baseServiceFee;

  /// Total material cost in Rupiah.
  final int totalMaterialCost;

  /// Total additional cost in Rupiah.
  final int totalAdditionalCost;

  /// Grand total in Rupiah.
  final int? grandTotal;

  /// Photos attached to the order.
  final List<String> photos;

  /// When the order was accepted by the worker.
  final DateTime? acceptedAt;

  /// When the order was completed.
  final DateTime? completedAt;

  /// When the order was cancelled.
  final DateTime? cancelledAt;

  /// Reason for cancellation.
  final String? cancelReason;

  /// Order progress timeline.
  final List<OrderTimelineEntry> timeline;

  /// Purchase summary for this order.
  final OrderPurchaseSummary? purchaseSummary;

  /// Whether there are unread chat messages.
  final bool hasUnreadChat;

  /// Whether the order can be cancelled.
  final bool canCancel;

  /// Cancellation policy text.
  final String? cancellationPolicy;

  /// When the order was last updated.
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
        id,
        orderNumber,
        title,
        description,
        status,
        urgency,
        location,
        createdAt,
        userId,
        workerId,
        serviceId,
        categoryId,
        workerInfo,
        serviceInfo,
        preferredDate,
        preferredTimeStart,
        preferredTimeEnd,
        notes,
        addressDetail,
        bookingFee,
        baseServiceFee,
        totalMaterialCost,
        totalAdditionalCost,
        grandTotal,
        photos,
        acceptedAt,
        completedAt,
        cancelledAt,
        cancelReason,
        timeline,
        purchaseSummary,
        hasUnreadChat,
        canCancel,
        cancellationPolicy,
        updatedAt,
      ];
}
