// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'worker_dashboard_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkerDashboardModel _$WorkerDashboardModelFromJson(
  Map<String, dynamic> json,
) => WorkerDashboardModel(
  earningsToday: (json['earnings_today'] as num).toInt(),
  earningsWeek: (json['earnings_week'] as num).toInt(),
  earningsMonth: (json['earnings_month'] as num).toInt(),
  walletBalance: (json['wallet_balance'] as num).toInt(),
  acceptanceRate: (json['acceptance_rate'] as num).toDouble(),
  averageRating: (json['average_rating'] as num).toDouble(),
  jobsCompleted: (json['jobs_completed'] as num).toInt(),
  incomingOrderCount: (json['incoming_order_count'] as num).toInt(),
  isAvailable: json['is_available'] as bool,
  activeOrderId: json['active_order_id'] as String?,
  activeOrderTitle: json['active_order_title'] as String?,
  activeOrderStatus: json['active_order_status'] as String?,
  activeOrderCustomerName: json['active_order_customer_name'] as String?,
  activeOrderStartTime: json['active_order_start_time'] == null
      ? null
      : DateTime.parse(json['active_order_start_time'] as String),
);

Map<String, dynamic> _$WorkerDashboardModelToJson(
  WorkerDashboardModel instance,
) => <String, dynamic>{
  'earnings_today': instance.earningsToday,
  'earnings_week': instance.earningsWeek,
  'earnings_month': instance.earningsMonth,
  'wallet_balance': instance.walletBalance,
  'acceptance_rate': instance.acceptanceRate,
  'average_rating': instance.averageRating,
  'jobs_completed': instance.jobsCompleted,
  'incoming_order_count': instance.incomingOrderCount,
  'is_available': instance.isAvailable,
  'active_order_id': instance.activeOrderId,
  'active_order_title': instance.activeOrderTitle,
  'active_order_status': instance.activeOrderStatus,
  'active_order_customer_name': instance.activeOrderCustomerName,
  'active_order_start_time': instance.activeOrderStartTime?.toIso8601String(),
};
