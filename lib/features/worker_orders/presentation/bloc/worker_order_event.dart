part of 'worker_order_bloc.dart';

sealed class WorkerOrderEvent extends Equatable {
  const WorkerOrderEvent();

  @override
  List<Object?> get props => [];
}

class FetchWorkerOrderDetail extends WorkerOrderEvent {
  const FetchWorkerOrderDetail({required this.orderId});

  final String orderId;

  @override
  List<Object?> get props => [orderId];
}

class UpdateOrderStatus extends WorkerOrderEvent {
  const UpdateOrderStatus({
    required this.orderId,
    required this.status,
    required this.currentStatus,
  });

  final String orderId;
  final String status;
  final String currentStatus;

  @override
  List<Object?> get props => [orderId, status, currentStatus];
}

class UploadProgressPhoto extends WorkerOrderEvent {
  const UploadProgressPhoto({
    required this.orderId,
    required this.filePath,
    this.caption,
  });

  final String orderId;
  final String filePath;
  final String? caption;

  @override
  List<Object?> get props => [orderId, filePath, caption];
}

class AddWorkItem extends WorkerOrderEvent {
  const AddWorkItem({
    required this.orderId,
    required this.itemName,
    required this.cost,
    this.description,
  });

  final String orderId;
  final String itemName;
  final int cost;
  final String? description;

  @override
  List<Object?> get props => [orderId, itemName, cost, description];
}

class CompleteOrder extends WorkerOrderEvent {
  const CompleteOrder({required this.orderId, this.workerNotes});

  final String orderId;
  final String? workerNotes;

  @override
  List<Object?> get props => [orderId, workerNotes];
}
