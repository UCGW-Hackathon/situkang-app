import 'package:equatable/equatable.dart';

/// Represents the data shown on the worker dashboard.
class WorkerDashboard extends Equatable {
  const WorkerDashboard({
    required this.earningsToday,
    required this.earningsWeek,
    required this.earningsMonth,
    required this.walletBalance,
    required this.acceptanceRate,
    required this.averageRating,
    required this.jobsCompleted,
    required this.incomingOrderCount,
    required this.isAvailable,
    this.activeOrderId,
    this.activeOrderTitle,
    this.activeOrderStatus,
    this.activeOrderCustomerName,
    this.activeOrderStartTime,
  });

  final int earningsToday;
  final int earningsWeek;
  final int earningsMonth;
  final int walletBalance;
  
  // Weekly summary stats
  final double acceptanceRate;
  final double averageRating;
  final int jobsCompleted;
  
  final int incomingOrderCount;
  final bool isAvailable;

  // Active Order info (if any)
  final String? activeOrderId;
  final String? activeOrderTitle;
  final String? activeOrderStatus;
  final String? activeOrderCustomerName;
  final DateTime? activeOrderStartTime;

  WorkerDashboard copyWith({
    int? earningsToday,
    int? earningsWeek,
    int? earningsMonth,
    int? walletBalance,
    double? acceptanceRate,
    double? averageRating,
    int? jobsCompleted,
    int? incomingOrderCount,
    bool? isAvailable,
    String? activeOrderId,
    String? activeOrderTitle,
    String? activeOrderStatus,
    String? activeOrderCustomerName,
    DateTime? activeOrderStartTime,
  }) {
    return WorkerDashboard(
      earningsToday: earningsToday ?? this.earningsToday,
      earningsWeek: earningsWeek ?? this.earningsWeek,
      earningsMonth: earningsMonth ?? this.earningsMonth,
      walletBalance: walletBalance ?? this.walletBalance,
      acceptanceRate: acceptanceRate ?? this.acceptanceRate,
      averageRating: averageRating ?? this.averageRating,
      jobsCompleted: jobsCompleted ?? this.jobsCompleted,
      incomingOrderCount: incomingOrderCount ?? this.incomingOrderCount,
      isAvailable: isAvailable ?? this.isAvailable,
      activeOrderId: activeOrderId ?? this.activeOrderId,
      activeOrderTitle: activeOrderTitle ?? this.activeOrderTitle,
      activeOrderStatus: activeOrderStatus ?? this.activeOrderStatus,
      activeOrderCustomerName:
          activeOrderCustomerName ?? this.activeOrderCustomerName,
      activeOrderStartTime: activeOrderStartTime ?? this.activeOrderStartTime,
    );
  }

  @override
  List<Object?> get props => [
        earningsToday,
        earningsWeek,
        earningsMonth,
        walletBalance,
        acceptanceRate,
        averageRating,
        jobsCompleted,
        incomingOrderCount,
        isAvailable,
        activeOrderId,
        activeOrderTitle,
        activeOrderStatus,
        activeOrderCustomerName,
        activeOrderStartTime,
      ];
}
