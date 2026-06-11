import 'package:equatable/equatable.dart';

import '../../../../core/constants/enums.dart';

/// Entity representing a line item in an invoice.
class InvoiceLineItem extends Equatable {
  const InvoiceLineItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.type = 'material',
  });

  final String id;
  final String name;
  final double quantity;
  final int unitPrice;
  final int totalPrice;
  final String type; // e.g., 'material', 'service', 'additional'

  @override
  List<Object?> get props => [id, name, quantity, unitPrice, totalPrice, type];
}

/// Entity representing an invoice and its payment status.
class Invoice extends Equatable {
  const Invoice({
    required this.id,
    required this.orderId,
    required this.invoiceNumber,
    required this.baseServiceFee,
    required this.bookingFee,
    required this.platformFee,
    required this.materialsTotal,
    required this.additionalCostTotal,
    required this.discount,
    required this.grandTotal,
    required this.status,
    required this.paymentMethod,
    required this.items,
    required this.createdAt,
    // dueDate is optional — API does not always return it
    this.dueDate,
    this.paidAt,
    this.aiSummary,
    this.workerNotes,
  });

  final String id;
  final String orderId;
  final String invoiceNumber;
  final int baseServiceFee;
  final int bookingFee;
  final int platformFee;
  final int materialsTotal;
  final int additionalCostTotal;
  final int discount;
  final int grandTotal;
  final PaymentStatus status;
  final PaymentMethod? paymentMethod;
  final List<InvoiceLineItem> items;
  final DateTime createdAt;
  final DateTime? dueDate; // optional — not always returned by API
  final DateTime? paidAt;
  final String? aiSummary;
  final String? workerNotes;

  @override
  List<Object?> get props => [
        id,
        orderId,
        invoiceNumber,
        baseServiceFee,
        bookingFee,
        platformFee,
        materialsTotal,
        additionalCostTotal,
        discount,
        grandTotal,
        status,
        paymentMethod,
        items,
        createdAt,
        dueDate,
        paidAt,
        aiSummary,
        workerNotes,
      ];
}
