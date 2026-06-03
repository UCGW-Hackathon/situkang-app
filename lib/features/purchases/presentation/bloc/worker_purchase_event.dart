part of 'worker_purchase_bloc.dart';

sealed class WorkerPurchaseEvent extends Equatable {
  const WorkerPurchaseEvent();

  @override
  List<Object?> get props => [];
}

class AddManualPurchase extends WorkerPurchaseEvent {
  const AddManualPurchase({
    required this.orderId,
    required this.itemName,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.totalPrice,
    this.reason,
    this.receiptPhotoPath,
  });

  final String orderId;
  final String itemName;
  final String category;
  final int quantity;
  final String unit;
  final int unitPrice;
  final int totalPrice;
  final String? reason;
  final String? receiptPhotoPath;

  @override
  List<Object?> get props => [
        orderId,
        itemName,
        category,
        quantity,
        unit,
        unitPrice,
        totalPrice,
        reason,
        receiptPhotoPath,
      ];
}

class ProcessAiPurchase extends WorkerPurchaseEvent {
  const ProcessAiPurchase({
    required this.orderId,
    required this.rawText,
  });

  final String orderId;
  final String rawText;

  @override
  List<Object?> get props => [orderId, rawText];
}

class ScanReceiptPurchase extends WorkerPurchaseEvent {
  const ScanReceiptPurchase({
    required this.orderId,
    required this.photoPath,
  });

  final String orderId;
  final String photoPath;

  @override
  List<Object?> get props => [orderId, photoPath];
}

class SubmitPurchaseForApproval extends WorkerPurchaseEvent {
  const SubmitPurchaseForApproval({
    required this.orderId,
    required this.purchaseId,
  });

  final String orderId;
  final String purchaseId;

  @override
  List<Object?> get props => [orderId, purchaseId];
}

class DeleteDraftPurchase extends WorkerPurchaseEvent {
  const DeleteDraftPurchase({
    required this.orderId,
    required this.purchaseId,
  });

  final String orderId;
  final String purchaseId;

  @override
  List<Object?> get props => [orderId, purchaseId];
}

class RespondToClarification extends WorkerPurchaseEvent {
  const RespondToClarification({
    required this.orderId,
    required this.purchaseId,
    required this.responseText,
    this.updatedItemName,
    this.updatedReason,
  });

  final String orderId;
  final String purchaseId;
  final String responseText;
  final String? updatedItemName;
  final String? updatedReason;

  @override
  List<Object?> get props => [
        orderId,
        purchaseId,
        responseText,
        updatedItemName,
        updatedReason,
      ];
}
