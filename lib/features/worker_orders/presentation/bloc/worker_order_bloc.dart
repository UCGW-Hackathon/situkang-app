import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../invoice/domain/entities/invoice.dart';
import '../../domain/repositories/worker_order_repository.dart';

part 'worker_order_event.dart';
part 'worker_order_state.dart';

@injectable
class WorkerOrderBloc extends Bloc<WorkerOrderEvent, WorkerOrderState> {
  WorkerOrderBloc(this.repository) : super(WorkerOrderInitial()) {
    on<UpdateOrderStatus>(_onUpdateOrderStatus);
    on<UploadProgressPhoto>(_onUploadProgressPhoto);
    on<AddWorkItem>(_onAddWorkItem);
    on<CompleteOrder>(_onCompleteOrder);
  }

  final WorkerOrderRepository repository;

  Future<void> _onUpdateOrderStatus(
    UpdateOrderStatus event,
    Emitter<WorkerOrderState> emit,
  ) async {
    // Validate state machine
    final validTransitions = {
      'accepted': ['on_the_way'],
      'on_the_way': ['arrived'],
      'arrived': ['in_progress'],
      'in_progress': ['work_paused', 'completed'],
      'work_paused': ['in_progress'],
    };

    if (validTransitions[event.currentStatus] == null || !validTransitions[event.currentStatus]!.contains(event.status)) {
      emit(const WorkerOrderError(ValidationFailure('Invalid status transition', fieldErrors: {})));
      return;
    }
    
    emit(WorkerOrderLoading());

    final result = await repository.updateOrderStatus(
      orderId: event.orderId,
      status: event.status,
    );

    result.fold(
      (failure) => emit(WorkerOrderError(failure)),
      (_) => emit(WorkerOrderStatusUpdated(event.status)),
    );
  }

  Future<void> _onUploadProgressPhoto(
    UploadProgressPhoto event,
    Emitter<WorkerOrderState> emit,
  ) async {
    emit(WorkerOrderLoading());

    final result = await repository.uploadProgressPhoto(
      orderId: event.orderId,
      filePath: event.filePath,
      caption: event.caption,
    );

    result.fold(
      (failure) => emit(WorkerOrderError(failure)),
      (_) => emit(WorkerOrderPhotoUploaded()),
    );
  }

  Future<void> _onAddWorkItem(
    AddWorkItem event,
    Emitter<WorkerOrderState> emit,
  ) async {
    emit(WorkerOrderLoading());

    final result = await repository.addWorkItem(
      orderId: event.orderId,
      itemName: event.itemName,
      cost: event.cost,
      description: event.description,
    );

    result.fold(
      (failure) => emit(WorkerOrderError(failure)),
      (_) => emit(WorkerOrderItemAdded()),
    );
  }

  Future<void> _onCompleteOrder(
    CompleteOrder event,
    Emitter<WorkerOrderState> emit,
  ) async {
    emit(WorkerOrderLoading());

    final result = await repository.completeOrder(
      orderId: event.orderId,
      workerNotes: event.workerNotes,
    );

    result.fold(
      (failure) => emit(WorkerOrderError(failure)),
      (invoice) => emit(WorkerOrderCompleted(invoice)),
    );
  }
}
