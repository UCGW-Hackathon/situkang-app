import 'package:equatable/equatable.dart';

class WalletSummary extends Equatable {
  const WalletSummary({
    required this.availableBalance,
    required this.totalEarnings,
    required this.totalWithdrawn,
    required this.pendingEarnings,
  });

  final int availableBalance;
  final int totalEarnings;
  final int totalWithdrawn;
  final int pendingEarnings;

  @override
  List<Object?> get props => [
        availableBalance,
        totalEarnings,
        totalWithdrawn,
        pendingEarnings,
      ];
}

class WalletTransaction extends Equatable {
  const WalletTransaction({
    required this.id,
    required this.type, // 'earning', 'withdrawal', 'refund'
    required this.amount,
    required this.description,
    required this.date,
    required this.status, // 'pending', 'completed', 'failed'
  });

  final String id;
  final String type;
  final int amount;
  final String description;
  final DateTime date;
  final String status;

  @override
  List<Object?> get props => [
        id,
        type,
        amount,
        description,
        date,
        status,
      ];
}
