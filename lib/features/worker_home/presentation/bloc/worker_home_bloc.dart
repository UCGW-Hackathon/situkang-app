import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/worker_dashboard.dart';
import '../../domain/repositories/worker_home_repository.dart';

part 'worker_home_event.dart';
part 'worker_home_state.dart';

@injectable
class WorkerHomeBloc extends Bloc<WorkerHomeEvent, WorkerHomeState> {
  WorkerHomeBloc(this.repository) : super(WorkerHomeInitial()) {
    on<FetchDashboardData>(_onFetchDashboardData);
    on<ToggleAvailability>(_onToggleAvailability);
  }

  final WorkerHomeRepository repository;

  Future<void> _onFetchDashboardData(
    FetchDashboardData event,
    Emitter<WorkerHomeState> emit,
  ) async {
    emit(WorkerHomeLoading());

    final result = await repository.getDashboardData();

    result.fold(
      (failure) => emit(WorkerHomeError(failure)),
      (dashboard) => emit(WorkerHomeLoaded(dashboard)),
    );
  }

  Future<void> _onToggleAvailability(
    ToggleAvailability event,
    Emitter<WorkerHomeState> emit,
  ) async {
    if (state is! WorkerHomeLoaded) return;
    final currentState = state as WorkerHomeLoaded;

    // Optimistic update
    final updatedDashboard = currentState.dashboard.copyWith(
      isAvailable: event.isAvailable,
    );
    emit(WorkerHomeLoaded(updatedDashboard));

    final result = await repository.toggleAvailability(
      isAvailable: event.isAvailable,
    );

    result.fold(
      (failure) {
        // Revert on failure
        emit(WorkerHomeLoaded(
          currentState.dashboard,
          actionError: failure,
        ));
      },
      (newState) {
        // Ensure state matches server response
        emit(WorkerHomeLoaded(
          currentState.dashboard.copyWith(isAvailable: newState),
        ));
      },
    );
  }
}
