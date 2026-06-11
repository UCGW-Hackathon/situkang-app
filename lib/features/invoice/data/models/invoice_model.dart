import 'package:json_annotation/json_annotation.dart';

import '../../../../core/constants/enums.dart';
import '../../domain/entities/invoice.dart';

part 'invoice_model.g.dart';

@JsonSerializable()
class InvoiceLineItemModel extends InvoiceLineItem {

  factory InvoiceLineItemModel.fromEntity(InvoiceLineItem entity) {
    return InvoiceLineItemModel(
      id: entity.id,
      name: entity.name,
      quantity: entity.quantity,
      unitPrice: entity.unitPrice,
      totalPrice: entity.totalPrice,
      type: entity.type,
    );
  }
  const InvoiceLineItemModel({
    required super.id,
    required super.name,
    required super.quantity,
    @JsonKey(name: 'unit_price') required super.unitPrice,
    @JsonKey(name: 'total_price') required super.totalPrice,
    super.type = 'material',
  });

  factory InvoiceLineItemModel.fromJson(Map<String, dynamic> json) =>
      _$InvoiceLineItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$InvoiceLineItemModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class InvoiceModel extends Invoice {

  factory InvoiceModel.fromJson(Map<String, dynamic> json) =>
      _$InvoiceModelFromJson(json);
  const InvoiceModel({
    // API returns 'invoice_id' as the invoice primary key
    @JsonKey(name: 'invoice_id') required super.id,
    @JsonKey(name: 'order_id') required super.orderId,
    @JsonKey(name: 'invoice_number') required super.invoiceNumber,
    @JsonKey(name: 'base_service_fee') required super.baseServiceFee,
    @JsonKey(name: 'booking_fee') required super.bookingFee,
    @JsonKey(name: 'platform_fee') required super.platformFee,
    // API returns 'total_material_cost' (not 'materials_total')
    @JsonKey(name: 'total_material_cost') required super.materialsTotal,
    // API returns 'total_additional_cost' (not 'additional_cost_total')
    @JsonKey(name: 'total_additional_cost') required super.additionalCostTotal,
    // API returns 'discount_amount' (not 'discount')
    @JsonKey(name: 'discount_amount') required super.discount,
    @JsonKey(name: 'grand_total') required super.grandTotal,
    // status is not returned by API — default to 'unpaid'
    this.statusStr = 'unpaid',
    // API returns 'line_items' (not 'items')
    @JsonKey(name: 'line_items') required this.itemModels,
    @JsonKey(name: 'created_at') required super.createdAt,
    // due_date is not returned by API — default to created_at + 7 days handled in fromJson
    @JsonKey(name: 'due_date') super.dueDate,
    @JsonKey(name: 'payment_method') this.paymentMethodStr,
    @JsonKey(name: 'paid_at') super.paidAt,
    // API returns 'ai_work_summary' (not 'ai_summary')
    @JsonKey(name: 'ai_work_summary') super.aiSummary,
    @JsonKey(name: 'worker_notes') super.workerNotes,
  }) : super(
          status: statusStr == 'paid'
              ? PaymentStatus.paid
              : statusStr == 'failed'
                  ? PaymentStatus.unpaid
                  : PaymentStatus.pending,
          paymentMethod: paymentMethodStr == 'cash'
              ? PaymentMethod.cash
              : paymentMethodStr == 'bank_transfer'
                  ? PaymentMethod.bankTransfer
                  : paymentMethodStr == 'ewallet'
                      ? PaymentMethod.ewallet
                      : null,
          items: itemModels,
        );

  @JsonKey(name: 'status')
  final String statusStr;

  @JsonKey(name: 'payment_method')
  final String? paymentMethodStr;

  @JsonKey(name: 'line_items')
  final List<InvoiceLineItemModel> itemModels;

  Map<String, dynamic> toJson() => _$InvoiceModelToJson(this);
}
