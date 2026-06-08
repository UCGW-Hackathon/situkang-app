import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/worker_dashboard.dart';

part 'worker_dashboard_model.g.dart';

@JsonSerializable()
class WorkerDashboardModel extends WorkerDashboard {

  factory WorkerDashboardModel.fromEntity(WorkerDashboard entity) {
    return WorkerDashboardModel(
      earningsToday: entity.earningsToday,
      earningsWeek: entity.earningsWeek,
      earningsMonth: entity.earningsMonth,
      walletBalance: entity.walletBalance,
      acceptanceRate: entity.acceptanceRate,
      averageRating: entity.averageRating,
      jobsCompleted: entity.jobsCompleted,
      incomingOrderCount: entity.incomingOrderCount,
      isAvailable: entity.isAvailable,
      activeOrderId: entity.activeOrderId,
      activeOrderTitle: entity.activeOrderTitle,
      activeOrderStatus: entity.activeOrderStatus,
      activeOrderCustomerName: entity.activeOrderCustomerName,
      activeOrderStartTime: entity.activeOrderStartTime,
    );
  }
  const WorkerDashboardModel({
    @JsonKey(name: 'earnings_today') required super.earningsToday,
    @JsonKey(name: 'earnings_week') required super.earningsWeek,
    @JsonKey(name: 'earnings_month') required super.earningsMonth,
    @JsonKey(name: 'wallet_balance') required super.walletBalance,
    @JsonKey(name: 'acceptance_rate') required super.acceptanceRate,
    @JsonKey(name: 'average_rating') required super.averageRating,
    @JsonKey(name: 'jobs_completed') required super.jobsCompleted,
    @JsonKey(name: 'incoming_order_count') required super.incomingOrderCount,
    @JsonKey(name: 'is_available') required super.isAvailable,
    @JsonKey(name: 'active_order_id') super.activeOrderId,
    @JsonKey(name: 'active_order_title') super.activeOrderTitle,
    @JsonKey(name: 'active_order_status') super.activeOrderStatus,
    @JsonKey(name: 'active_order_customer_name') super.activeOrderCustomerName,
    @JsonKey(name: 'active_order_start_time') super.activeOrderStartTime,
  });

  factory WorkerDashboardModel.fromJson(Map<String, dynamic> json) =>
      _$WorkerDashboardModelFromJson(json);

  Map<String, dynamic> toJson() => _$WorkerDashboardModelToJson(this);
}
