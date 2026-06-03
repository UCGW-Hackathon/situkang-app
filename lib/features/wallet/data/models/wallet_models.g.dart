// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WalletSummaryModel _$WalletSummaryModelFromJson(Map<String, dynamic> json) =>
    WalletSummaryModel(
      availableBalance: (json['available_balance'] as num).toInt(),
      totalEarnings: (json['total_earnings'] as num).toInt(),
      totalWithdrawn: (json['total_withdrawn'] as num).toInt(),
      pendingEarnings: (json['pending_earnings'] as num).toInt(),
    );

Map<String, dynamic> _$WalletSummaryModelToJson(WalletSummaryModel instance) =>
    <String, dynamic>{
      'available_balance': instance.availableBalance,
      'total_earnings': instance.totalEarnings,
      'total_withdrawn': instance.totalWithdrawn,
      'pending_earnings': instance.pendingEarnings,
    };

WalletTransactionModel _$WalletTransactionModelFromJson(
  Map<String, dynamic> json,
) => WalletTransactionModel(
  id: json['id'] as String,
  type: json['type'] as String,
  amount: (json['amount'] as num).toInt(),
  description: json['description'] as String,
  date: DateTime.parse(json['date'] as String),
  status: json['status'] as String,
);

Map<String, dynamic> _$WalletTransactionModelToJson(
  WalletTransactionModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'amount': instance.amount,
  'description': instance.description,
  'date': instance.date.toIso8601String(),
  'status': instance.status,
};
