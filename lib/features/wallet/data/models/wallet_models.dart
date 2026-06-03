import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/wallet_entities.dart';

part 'wallet_models.g.dart';

@JsonSerializable()
class WalletSummaryModel extends WalletSummary {
  const WalletSummaryModel({
    @JsonKey(name: 'available_balance') required super.availableBalance,
    @JsonKey(name: 'total_earnings') required super.totalEarnings,
    @JsonKey(name: 'total_withdrawn') required super.totalWithdrawn,
    @JsonKey(name: 'pending_earnings') required super.pendingEarnings,
  });

  factory WalletSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$WalletSummaryModelFromJson(json);

  Map<String, dynamic> toJson() => _$WalletSummaryModelToJson(this);
}

@JsonSerializable()
class WalletTransactionModel extends WalletTransaction {
  const WalletTransactionModel({
    required super.id,
    required super.type,
    required super.amount,
    required super.description,
    required super.date,
    required super.status,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) =>
      _$WalletTransactionModelFromJson(json);

  Map<String, dynamic> toJson() => _$WalletTransactionModelToJson(this);
}
