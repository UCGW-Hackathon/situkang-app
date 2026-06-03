import '../../../../core/constants/enums.dart';
import '../../domain/entities/purchase.dart';
import 'risk_flag_model.dart';

/// Data model for a purchase, mapping API JSON to domain entity.
///
/// Handles the purchase response format from the purchases API endpoints.
class PurchaseModel {
  const PurchaseModel({
    required this.purchaseId,
    required this.orderId,
    required this.workerId,
    required this.itemName,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    this.reason,
    this.receiptPhotoUrl,
    this.confidence,
    this.needsClarification = false,
    this.clarificationQuestion,
    this.clarificationResponse,
    this.aiExplanation,
    this.riskFlags = const [],
  });

  /// Creates a [PurchaseModel] from a JSON map.
  factory PurchaseModel.fromJson(Map<String, dynamic> json) {
    final riskFlagsJson = json['risk_flags'] as List<dynamic>? ?? [];
    final riskFlags = riskFlagsJson
        .map((flag) => RiskFlagModel.fromJson(flag as Map<String, dynamic>))
        .toList();

    return PurchaseModel(
      purchaseId: json['purchase_id'] as String? ?? '',
      orderId: json['order_id'] as String? ?? '',
      workerId: json['worker_id'] as String? ?? '',
      itemName: json['item_name'] as String? ?? '',
      category: PurchaseCategory.fromString(
          json['category'] as String? ?? 'lainnya'),
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? '',
      unitPrice: json['unit_price'] as int? ?? 0,
      totalPrice: json['total_price'] as int? ?? 0,
      status: PurchaseStatus.fromString(
          json['status'] as String? ?? 'draft'),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      reason: json['reason'] as String?,
      receiptPhotoUrl: json['receipt_photo_url'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      needsClarification: json['needs_clarification'] as bool? ?? false,
      clarificationQuestion: json['clarification_question'] as String?,
      clarificationResponse: json['clarification_response'] as String?,
      aiExplanation: json['ai_explanation'] as String?,
      riskFlags: riskFlags,
    );
  }

  final String purchaseId;
  final String orderId;
  final String workerId;
  final String itemName;
  final PurchaseCategory category;
  final double quantity;
  final String unit;
  final int unitPrice;
  final int totalPrice;
  final String? reason;
  final String? receiptPhotoUrl;
  final PurchaseStatus status;
  final double? confidence;
  final bool needsClarification;
  final String? clarificationQuestion;
  final String? clarificationResponse;
  final String? aiExplanation;
  final List<RiskFlagModel> riskFlags;
  final DateTime createdAt;

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() => {
        'purchase_id': purchaseId,
        'order_id': orderId,
        'worker_id': workerId,
        'item_name': itemName,
        'category': category.value,
        'quantity': quantity,
        'unit': unit,
        'unit_price': unitPrice,
        'total_price': totalPrice,
        'reason': reason,
        'receipt_photo_url': receiptPhotoUrl,
        'status': status.value,
        'confidence': confidence,
        'needs_clarification': needsClarification,
        'clarification_question': clarificationQuestion,
        'clarification_response': clarificationResponse,
        'ai_explanation': aiExplanation,
        'risk_flags': riskFlags.map((f) => f.toJson()).toList(),
        'created_at': createdAt.toIso8601String(),
      };

  /// Converts this model to a domain [Purchase] entity.
  Purchase toEntity() => Purchase(
        id: purchaseId,
        orderId: orderId,
        workerId: workerId,
        itemName: itemName,
        category: category,
        quantity: quantity,
        unit: unit,
        unitPrice: unitPrice,
        totalPrice: totalPrice,
        reason: reason,
        receiptPhotoUrl: receiptPhotoUrl,
        status: status,
        confidence: confidence,
        needsClarification: needsClarification,
        clarificationQuestion: clarificationQuestion,
        clarificationResponse: clarificationResponse,
        aiExplanation: aiExplanation,
        riskFlags: riskFlags.map((f) => f.toEntity()).toList(),
        createdAt: createdAt,
      );
}
