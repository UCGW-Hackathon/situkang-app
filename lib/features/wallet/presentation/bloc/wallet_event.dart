part of 'wallet_bloc.dart';

sealed class WalletEvent extends Equatable {
  const WalletEvent();

  @override
  List<Object?> get props => [];
}

class FetchWalletSummary extends WalletEvent {}

class FetchWalletTransactions extends WalletEvent {}

class LoadMoreWalletTransactions extends WalletEvent {}

class FilterWalletTransactions extends WalletEvent {
  const FilterWalletTransactions({
    this.type,
    this.status,
    this.startDate,
    this.endDate,
  });

  final String? type;
  final String? status;
  final DateTime? startDate;
  final DateTime? endDate;

  @override
  List<Object?> get props => [type, status, startDate, endDate];
}

class RequestWithdrawal extends WalletEvent {
  const RequestWithdrawal({
    required this.amount,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolderName,
  });

  final int amount;
  final String bankName;
  final String accountNumber;
  final String accountHolderName;

  @override
  List<Object?> get props => [
        amount,
        bankName,
        accountNumber,
        accountHolderName,
      ];
}
