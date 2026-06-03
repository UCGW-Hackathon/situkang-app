import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/wallet_entities.dart';
import '../../domain/repositories/wallet_repository.dart';

part 'wallet_event.dart';
part 'wallet_state.dart';

@injectable
class WalletBloc extends Bloc<WalletEvent, WalletState> {
  WalletBloc(this.repository) : super(const WalletState()) {
    on<FetchWalletSummary>(_onFetchWalletSummary);
    on<FetchWalletTransactions>(_onFetchWalletTransactions);
    on<LoadMoreWalletTransactions>(_onLoadMoreWalletTransactions);
    on<FilterWalletTransactions>(_onFilterWalletTransactions);
    on<RequestWithdrawal>(_onRequestWithdrawal);
  }

  final WalletRepository repository;

  Future<void> _onFetchWalletSummary(
    FetchWalletSummary event,
    Emitter<WalletState> emit,
  ) async {
    emit(state.copyWith(summaryStatus: WalletStatus.loading));

    final result = await repository.getWalletSummary();

    result.fold(
      (failure) => emit(state.copyWith(
        summaryStatus: WalletStatus.error,
        failure: failure,
      )),
      (summary) => emit(state.copyWith(
        summaryStatus: WalletStatus.success,
        summary: summary,
      )),
    );
  }

  Future<void> _onFetchWalletTransactions(
    FetchWalletTransactions event,
    Emitter<WalletState> emit,
  ) async {
    emit(state.copyWith(transactionsStatus: WalletStatus.loading, page: 1));

    final result = await repository.getTransactions(
      page: 1,
      type: state.filterType,
      status: state.filterStatus,
      startDate: state.startDate,
      endDate: state.endDate,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        transactionsStatus: WalletStatus.error,
        failure: failure,
      )),
      (transactions) => emit(state.copyWith(
        transactionsStatus: WalletStatus.success,
        transactions: transactions,
        hasReachedMax: transactions.isEmpty,
      )),
    );
  }

  Future<void> _onLoadMoreWalletTransactions(
    LoadMoreWalletTransactions event,
    Emitter<WalletState> emit,
  ) async {
    if (state.hasReachedMax || state.transactionsStatus == WalletStatus.loading) return;

    final nextPage = state.page + 1;
    final result = await repository.getTransactions(
      page: nextPage,
      type: state.filterType,
      status: state.filterStatus,
      startDate: state.startDate,
      endDate: state.endDate,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        transactionsStatus: WalletStatus.error,
        failure: failure,
      )),
      (transactions) {
        emit(transactions.isEmpty
            ? state.copyWith(hasReachedMax: true)
            : state.copyWith(
                transactionsStatus: WalletStatus.success,
                transactions: List.of(state.transactions)..addAll(transactions),
                page: nextPage,
                hasReachedMax: false,
              ));
      },
    );
  }

  Future<void> _onFilterWalletTransactions(
    FilterWalletTransactions event,
    Emitter<WalletState> emit,
  ) async {
    emit(state.copyWith(
      filterType: event.type,
      filterStatus: event.status,
      startDate: event.startDate,
      endDate: event.endDate,
    ));
    add(FetchWalletTransactions());
  }

  Future<void> _onRequestWithdrawal(
    RequestWithdrawal event,
    Emitter<WalletState> emit,
  ) async {
    emit(state.copyWith(withdrawStatus: WalletStatus.loading));

    final result = await repository.requestWithdrawal(
      amount: event.amount,
      bankName: event.bankName,
      accountNumber: event.accountNumber,
      accountHolderName: event.accountHolderName,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        withdrawStatus: WalletStatus.error,
        failure: failure,
      )),
      (_) {
        emit(state.copyWith(withdrawStatus: WalletStatus.success));
        // Refresh summary and transactions
        add(FetchWalletSummary());
        add(FetchWalletTransactions());
      },
    );
  }
}
