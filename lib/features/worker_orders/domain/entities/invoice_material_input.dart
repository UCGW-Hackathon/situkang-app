class InvoiceMaterialInput {
  const InvoiceMaterialInput({
    required this.itemName,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.totalPrice,
    this.purchaseId,
    this.reason,
  });

  final String? purchaseId;
  final String itemName;
  final String category;
  final double quantity;
  final String unit;
  final int unitPrice;
  final int totalPrice;
  final String? reason;

  Map<String, dynamic> toJson() => {
    if (purchaseId != null && purchaseId!.isNotEmpty) 'purchase_id': purchaseId,
    'item_name': itemName,
    'category': category,
    'quantity': quantity,
    'unit': unit,
    'unit_price': unitPrice,
    'total_price': totalPrice,
    if (reason != null && reason!.trim().isNotEmpty) 'reason': reason!.trim(),
  };
}
