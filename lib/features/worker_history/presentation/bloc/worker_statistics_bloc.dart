import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/worker_statistics.dart';
import '../../domain/repositories/worker_history_repository.dart';

part 'worker_statistics_event.dart';
part 'worker_statistics_state.dart';

@injectable
class WorkerStatisticsBloc extends Bloc<WorkerStatisticsEvent, WorkerStatisticsState> {
  WorkerStatisticsBloc(this.repository) : super(WorkerStatisticsInitial()) {
    on<FetchWorkerStatistics>(_onFetchWorkerStatistics);
  }

  final WorkerHistoryRepository repository;

  Future<void> _onFetchWorkerStatistics(
    FetchWorkerStatistics event,
    Emitter<WorkerStatisticsState> emit,
  ) async {
    emit(WorkerStatisticsLoading());

    final result = await repository.getStatistics(timeRange: event.timeRange);

    result.fold(
      (failure) => emit(WorkerStatisticsError(failure)),
      (statistics) => emit(WorkerStatisticsLoaded(
        statistics: statistics,
        timeRange: event.timeRange,
      )),
    );
  }
}
