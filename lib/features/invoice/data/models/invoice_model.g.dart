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
  id: json['id'] as String,
  orderId: json['order_id'] as String,
  invoiceNumber: json['invoice_number'] as String,
  baseServiceFee: (json['base_service_fee'] as num).toInt(),
  bookingFee: (json['booking_fee'] as num).toInt(),
  platformFee: (json['platform_fee'] as num).toInt(),
  materialsTotal: (json['materials_total'] as num).toInt(),
  additionalCostTotal: (json['additional_cost_total'] as num).toInt(),
  discount: (json['discount'] as num).toInt(),
  grandTotal: (json['grand_total'] as num).toInt(),
  statusStr: json['status'] as String,
  paymentMethodStr: json['payment_method'] as String?,
  itemModels: (json['items'] as List<dynamic>)
      .map((e) => InvoiceLineItemModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  createdAt: DateTime.parse(json['created_at'] as String),
  dueDate: DateTime.parse(json['due_date'] as String),
  paidAt: json['paid_at'] == null
      ? null
      : DateTime.parse(json['paid_at'] as String),
  aiSummary: json['ai_summary'] as String?,
  workerNotes: json['worker_notes'] as String?,
);

Map<String, dynamic> _$InvoiceModelToJson(InvoiceModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order_id': instance.orderId,
      'invoice_number': instance.invoiceNumber,
      'base_service_fee': instance.baseServiceFee,
      'booking_fee': instance.bookingFee,
      'platform_fee': instance.platformFee,
      'materials_total': instance.materialsTotal,
      'additional_cost_total': instance.additionalCostTotal,
      'discount': instance.discount,
      'grand_total': instance.grandTotal,
      'created_at': instance.createdAt.toIso8601String(),
      'due_date': instance.dueDate.toIso8601String(),
      'paid_at': instance.paidAt?.toIso8601String(),
      'ai_summary': instance.aiSummary,
      'worker_notes': instance.workerNotes,
      'status': instance.statusStr,
      'payment_method': instance.paymentMethodStr,
      'items': instance.itemModels.map((e) => e.toJson()).toList(),
    };
