part of 'wallet_bloc.dart';

enum WalletStatus { initial, loading, success, error }

class WalletState extends Equatable {
  const WalletState({
    this.summaryStatus = WalletStatus.initial,
    this.transactionsStatus = WalletStatus.initial,
    this.withdrawStatus = WalletStatus.initial,
    this.summary,
    this.transactions = const <WalletTransaction>[],
    this.hasReachedMax = false,
    this.page = 1,
    this.filterType,
    this.filterStatus,
    this.startDate,
    this.endDate,
    this.failure,
  });

  final WalletStatus summaryStatus;
  final WalletStatus transactionsStatus;
  final WalletStatus withdrawStatus;
  final WalletSummary? summary;
  final List<WalletTransaction> transactions;
  final bool hasReachedMax;
  final int page;
  final String? filterType;
  final String? filterStatus;
  final DateTime? startDate;
  final DateTime? endDate;
  final Failure? failure;

  WalletState copyWith({
    WalletStatus? summaryStatus,
    WalletStatus? transactionsStatus,
    WalletStatus? withdrawStatus,
    WalletSummary? summary,
    List<WalletTransaction>? transactions,
    bool? hasReachedMax,
    int? page,
    String? filterType,
    String? filterStatus,
    DateTime? startDate,
    DateTime? endDate,
    Failure? failure,
  }) {
    return WalletState(
      summaryStatus: summaryStatus ?? this.summaryStatus,
      transactionsStatus: transactionsStatus ?? this.transactionsStatus,
      withdrawStatus: withdrawStatus ?? WalletStatus.initial, // Reset withdraw status
      summary: summary ?? this.summary,
      transactions: transactions ?? this.transactions,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      page: page ?? this.page,
      filterType: filterType ?? this.filterType,
      filterStatus: filterStatus ?? this.filterStatus,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      failure: failure,
    );
  }

  @override
  List<Object?> get props => [
        summaryStatus,
        transactionsStatus,
        withdrawStatus,
        summary,
        transactions,
        hasReachedMax,
        page,
        filterType,
        filterStatus,
        startDate,
        endDate,
        failure,
      ];
}
