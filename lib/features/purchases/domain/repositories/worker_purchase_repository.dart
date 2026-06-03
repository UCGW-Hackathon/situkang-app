import 'package:situkang_app/core/error/result.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/purchase.dart';

/// Abstract repository interface for worker-side purchase management.
///
/// Defines the contract for adding purchases manually, via AI processing,
/// OCR scanning, and managing purchase drafts/approvals.
abstract class WorkerPurchaseRepository {
  /// Adds a new purchase manually (draft state).
  Future<Result<Purchase>> addPurchase({
    required String orderId,
    required String itemName,
    required String category,
    required int quantity,
    required String unit,
    required int unitPrice,
    required int totalPrice,
    String? reason,
    String? receiptPhotoPath,
  });

  /// Processes raw text input using AI to extract structured purchase items.
  Future<Result<List<Purchase>>> processAiInput({
    required String orderId,
    required String rawText,
  });

  /// Processes a receipt image using OCR to extract structured purchase items.
  Future<Result<List<Purchase>>> scanReceipt({
    required String orderId,
    required String photoPath,
  });

  /// Submits a draft purchase for customer approval.
  Future<Result<Purchase>> submitForApproval({
    required String orderId,
    required String purchaseId,
  });

  /// Deletes a draft purchase.
  Future<Result<void>> deleteDraft({
    required String orderId,
    required String purchaseId,
  });

  /// Responds to a clarification request from the customer.
  Future<Result<Purchase>> respondToClarification({
    required String orderId,
    required String purchaseId,
    required String responseText,
    String? updatedItemName,
    String? updatedReason,
  });
}
