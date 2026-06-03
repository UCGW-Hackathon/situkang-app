import '../../domain/entities/purchase_summary.dart';

/// Data model for purchase summary, mapping API JSON to domain entity.
class PurchaseSummaryModel {
  const PurchaseSummaryModel({
    required this.totalItems,
    required this.totalCost,
    required this.approvedCost,
    required this.pendingCost,
    required this.rejectedCost,
    required this.needsClarificationCost,
    this.aiSummary,
  });

  /// Creates a [PurchaseSummaryModel] from a JSON map.
  factory PurchaseSummaryModel.fromJson(Map<String, dynamic> json) {
    return PurchaseSummaryModel(
      totalItems: json['total_items'] as int? ?? 0,
      totalCost: json['total_cost'] as int? ?? 0,
      approvedCost: json['approved_cost'] as int? ?? 0,
      pendingCost: json['pending_cost'] as int? ?? 0,
      rejectedCost: json['rejected_cost'] as int? ?? 0,
      needsClarificationCost:
          json['needs_clarification_cost'] as int? ?? 0,
      aiSummary: json['ai_summary'] as String?,
    );
  }

  final int totalItems;
  final int totalCost;
  final int approvedCost;
  final int pendingCost;
  final int rejectedCost;
  final int needsClarificationCost;
  final String? aiSummary;

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() => {
        'total_items': totalItems,
        'total_cost': totalCost,
        'approved_cost': approvedCost,
        'pending_cost': pendingCost,
        'rejected_cost': rejectedCost,
        'needs_clarification_cost': needsClarificationCost,
        'ai_summary': aiSummary,
      };

  /// Converts this model to a domain [PurchaseSummary] entity.
  PurchaseSummary toEntity() => PurchaseSummary(
        totalItems: totalItems,
        totalCost: totalCost,
        approvedCost: approvedCost,
        pendingCost: pendingCost,
        rejectedCost: rejectedCost,
        needsClarificationCost: needsClarificationCost,
        aiSummary: aiSummary,
      );
}
