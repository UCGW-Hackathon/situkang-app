import 'package:equatable/equatable.dart';

/// Summary of all purchases for an order.
///
/// Provides aggregated cost breakdowns by status and an AI-generated
/// summary text describing the overall purchase situation.
class PurchaseSummary extends Equatable {
  const PurchaseSummary({
    required this.totalItems,
    required this.totalCost,
    required this.approvedCost,
    required this.pendingCost,
    required this.rejectedCost,
    required this.needsClarificationCost,
    this.aiSummary,
  });

  /// Total number of purchase items.
  final int totalItems;

  /// Total cost of all purchases regardless of status (in Rupiah).
  final int totalCost;

  /// Total cost of approved purchases (in Rupiah).
  final int approvedCost;

  /// Total cost of pending approval purchases (in Rupiah).
  final int pendingCost;

  /// Total cost of rejected purchases (in Rupiah).
  final int rejectedCost;

  /// Total cost of purchases needing clarification (in Rupiah).
  final int needsClarificationCost;

  /// AI-generated summary text describing the purchase situation.
  final String? aiSummary;

  @override
  List<Object?> get props => [
        totalItems,
        totalCost,
        approvedCost,
        pendingCost,
        rejectedCost,
        needsClarificationCost,
        aiSummary,
      ];
}
