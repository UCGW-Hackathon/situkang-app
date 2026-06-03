part of 'worker_purchase_bloc.dart';

sealed class WorkerPurchaseState extends Equatable {
  const WorkerPurchaseState();

  @override
  List<Object?> get props => [];
}

class WorkerPurchaseInitial extends WorkerPurchaseState {}

class WorkerPurchaseLoading extends WorkerPurchaseState {}

class WorkerPurchaseAiProcessing extends WorkerPurchaseState {}

class WorkerPurchaseOcrProcessing extends WorkerPurchaseState {}

class WorkerPurchaseSuccess extends WorkerPurchaseState {
  const WorkerPurchaseSuccess({
    required this.purchase,
    this.message,
  });

  final Purchase purchase;
  final String? message;

  @override
  List<Object?> get props => [purchase, message];
}

class WorkerPurchaseBatchSuccess extends WorkerPurchaseState {
  const WorkerPurchaseBatchSuccess(this.purchases);

  final List<Purchase> purchases;

  @override
  List<Object?> get props => [purchases];
}

class WorkerPurchaseDeleted extends WorkerPurchaseState {
  const WorkerPurchaseDeleted(this.purchaseId);

  final String purchaseId;

  @override
  List<Object?> get props => [purchaseId];
}

class WorkerPurchaseError extends WorkerPurchaseState {
  const WorkerPurchaseError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
