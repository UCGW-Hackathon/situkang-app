import 'package:equatable/equatable.dart';

import '../../../../core/constants/enums.dart';
import 'risk_flag.dart';

/// Represents a material/tool purchase made by a Worker during an active order.
///
/// Purchases go through an AI-assisted validation process and require
/// User approval before being included in the final invoice.
class Purchase extends Equatable {
  const Purchase({
    required this.id,
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

  /// Unique purchase identifier.
  final String id;

  /// The order this purchase belongs to.
  final String orderId;

  /// The worker who made this purchase.
  final String workerId;

  /// Name of the purchased item.
  final String itemName;

  /// Category of the purchase (material, alat, sparepart, etc.).
  final PurchaseCategory category;

  /// Quantity purchased.
  final double quantity;

  /// Unit of measurement (e.g., "kg", "meter", "buah").
  final String unit;

  /// Price per unit in Rupiah.
  final int unitPrice;

  /// Total price in Rupiah (quantity * unitPrice).
  final int totalPrice;

  /// Reason for the purchase.
  final String? reason;

  /// URL to the receipt photo (if available).
  final String? receiptPhotoUrl;

  /// Current status of the purchase.
  final PurchaseStatus status;

  /// AI confidence score (0.00 - 1.00) indicating how confident
  /// the AI is about the purchase validity.
  final double? confidence;

  /// Whether this purchase needs clarification from the worker.
  final bool needsClarification;

  /// The clarification question asked by the user.
  final String? clarificationQuestion;

  /// The worker's response to the clarification question.
  final String? clarificationResponse;

  /// AI-generated explanation about the purchase analysis.
  final String? aiExplanation;

  /// List of AI-detected risk flags for this purchase.
  final List<RiskFlag> riskFlags;

  /// When the purchase was created.
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        orderId,
        workerId,
        itemName,
        category,
        quantity,
        unit,
        unitPrice,
        totalPrice,
        reason,
        receiptPhotoUrl,
        status,
        confidence,
        needsClarification,
        clarificationQuestion,
        clarificationResponse,
        aiExplanation,
        riskFlags,
        createdAt,
      ];
}
