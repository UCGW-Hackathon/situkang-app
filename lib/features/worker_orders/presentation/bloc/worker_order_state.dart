part of 'worker_order_bloc.dart';

sealed class WorkerOrderState extends Equatable {
  const WorkerOrderState();

  @override
  List<Object?> get props => [];
}

class WorkerOrderInitial extends WorkerOrderState {}

class WorkerOrderLoading extends WorkerOrderState {}

class WorkerOrderStatusUpdated extends WorkerOrderState {
  const WorkerOrderStatusUpdated(this.newStatus);

  final String newStatus;

  @override
  List<Object?> get props => [newStatus];
}

class WorkerOrderPhotoUploaded extends WorkerOrderState {}

class WorkerOrderItemAdded extends WorkerOrderState {}

class WorkerOrderCompleted extends WorkerOrderState {
  const WorkerOrderCompleted(this.invoice);

  final Invoice invoice;

  @override
  List<Object?> get props => [invoice];
}

class WorkerOrderError extends WorkerOrderState {
  const WorkerOrderError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
