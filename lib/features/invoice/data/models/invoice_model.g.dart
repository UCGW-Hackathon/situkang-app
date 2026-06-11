// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InvoiceLineItemModel _$InvoiceLineItemModelFromJson(
  Map<String, dynamic> json,
) => InvoiceLineItemModel(
  id: json['id'] as String,
  name: json['name'] as String,
  quantity: (json['quantity'] as num).toDouble(),
  unitPrice: (json['unit_price'] as num).toInt(),
  totalPrice: (json['total_price'] as num).toInt(),
  type: json['type'] as String? ?? 'material',
);

Map<String, dynamic> _$InvoiceLineItemModelToJson(
  InvoiceLineItemModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'quantity': instance.quantity,
  'unit_price': instance.unitPrice,
  'total_price': instance.totalPrice,
  'type': instance.type,
};

InvoiceModel _$InvoiceModelFromJson(Map<String, dynamic> json) => InvoiceModel(
  // API returns 'invoice_id' as the invoice primary key
  id: json['invoice_id'] as String,
  orderId: json['order_id'] as String,
  invoiceNumber: json['invoice_number'] as String,
  baseServiceFee: (json['base_service_fee'] as num).toInt(),
  bookingFee: (json['booking_fee'] as num).toInt(),
  platformFee: (json['platform_fee'] as num? ?? 0).toInt(),
  // API returns 'total_material_cost'
  materialsTotal: (json['total_material_cost'] as num? ?? 0).toInt(),
  // API returns 'total_additional_cost'
  additionalCostTotal: (json['total_additional_cost'] as num? ?? 0).toInt(),
  // API returns 'discount_amount'
  discount: (json['discount_amount'] as num? ?? 0).toInt(),
  grandTotal: (json['grand_total'] as num).toInt(),
  // status not always returned by API — default to 'unpaid'
  statusStr: json['status'] as String? ?? 'unpaid',
  // API returns 'line_items'
  itemModels: (json['line_items'] as List<dynamic>? ?? [])
      .map((e) => InvoiceLineItemModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  createdAt: DateTime.parse(json['created_at'] as String),
  // due_date optional — API may not return it
  dueDate: json['due_date'] == null
      ? null
      : DateTime.parse(json['due_date'] as String),
  paymentMethodStr: json['payment_method'] as String?,
  paidAt: json['paid_at'] == null
      ? null
      : DateTime.parse(json['paid_at'] as String),
  // API returns 'ai_work_summary'
  aiSummary: json['ai_work_summary'] as String?,
  workerNotes: json['worker_notes'] as String?,
);

Map<String, dynamic> _$InvoiceModelToJson(InvoiceModel instance) =>
    <String, dynamic>{
      'invoice_id': instance.id,
      'order_id': instance.orderId,
      'invoice_number': instance.invoiceNumber,
      'base_service_fee': instance.baseServiceFee,
      'booking_fee': instance.bookingFee,
      'platform_fee': instance.platformFee,
      'total_material_cost': instance.materialsTotal,
      'total_additional_cost': instance.additionalCostTotal,
      'discount_amount': instance.discount,
      'grand_total': instance.grandTotal,
      'created_at': instance.createdAt.toIso8601String(),
      'due_date': instance.dueDate?.toIso8601String(),
      'paid_at': instance.paidAt?.toIso8601String(),
      'ai_work_summary': instance.aiSummary,
      'worker_notes': instance.workerNotes,
      'status': instance.statusStr,
      'payment_method': instance.paymentMethodStr,
      'line_items': instance.itemModels.map((e) => e.toJson()).toList(),
    };
