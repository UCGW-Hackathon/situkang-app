import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart' hide Order;

import '../../../../core/constants/enums.dart';
import '../../../../core/error/failures.dart';
import '../../../orders/domain/entities/order.dart';
import '../../domain/repositories/worker_history_repository.dart';

part 'worker_history_event.dart';
part 'worker_history_state.dart';

@injectable
class WorkerHistoryBloc extends Bloc<WorkerHistoryEvent, WorkerHistoryState> {
  WorkerHistoryBloc(this.repository) : super(const WorkerHistoryState()) {
    on<FetchWorkerHistory>(_onFetchWorkerHistory);
    on<LoadMoreWorkerHistory>(_onLoadMoreWorkerHistory);
    on<FilterWorkerHistory>(_onFilterWorkerHistory);
  }

  final WorkerHistoryRepository repository;

  Future<void> _onFetchWorkerHistory(
    FetchWorkerHistory event,
    Emitter<WorkerHistoryState> emit,
  ) async {
    emit(state.copyWith(status: WorkerHistoryStatus.loading, page: 1));

    final result = await repository.getHistory(
      status: state.statusFilter,
      page: 1,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: WorkerHistoryStatus.error,
        failure: failure,
      )),
      (orders) => emit(state.copyWith(
        status: WorkerHistoryStatus.success,
        orders: orders,
        hasReachedMax: orders.isEmpty, // Simple pagination logic
      )),
    );
  }

  Future<void> _onLoadMoreWorkerHistory(
    LoadMoreWorkerHistory event,
    Emitter<WorkerHistoryState> emit,
  ) async {
    if (state.hasReachedMax || state.status == WorkerHistoryStatus.loading) return;

    final nextPage = state.page + 1;
    final result = await repository.getHistory(
      status: state.statusFilter,
      page: nextPage,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: WorkerHistoryStatus.error,
        failure: failure,
      )),
      (orders) {
        emit(orders.isEmpty
            ? state.copyWith(hasReachedMax: true)
            : state.copyWith(
                status: WorkerHistoryStatus.success,
                orders: List.of(state.orders)..addAll(orders),
                page: nextPage,
                hasReachedMax: false,
              ));
      },
    );
  }

  Future<void> _onFilterWorkerHistory(
    FilterWorkerHistory event,
    Emitter<WorkerHistoryState> emit,
  ) async {
    if (event.status == null) {
      emit(state.copyWith(clearStatusFilter: true));
    } else {
      emit(state.copyWith(statusFilter: event.status));
    }
    add(FetchWorkerHistory()); // Re-fetch with new filter
  }
}
