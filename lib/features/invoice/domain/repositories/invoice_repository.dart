import 'package:situkang_app/core/error/result.dart';
import 'dart:io';

import '../../../../core/error/failures.dart';
import '../entities/invoice.dart';

/// Repository interface for invoice and payment operations.
abstract class InvoiceRepository {
  /// Fetches the invoice for a specific order.
  Future<Result<Invoice>> getInvoice({required String orderId});

  /// Confirms a payment for an invoice with a specific method.
  Future<Result<Invoice>> confirmPayment({
    required String invoiceId,
    required String paymentMethod,
  });

  /// Uploads payment proof (e.g. for bank transfers).
  Future<Result<Invoice>> uploadPaymentProof({
    required String invoiceId,
    required File proofImage,
  });

  /// Downloads the invoice as a PDF file, returning the local file path.
  Future<Result<String>> downloadInvoicePdf({required String invoiceId});
}
