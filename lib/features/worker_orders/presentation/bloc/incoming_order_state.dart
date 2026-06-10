part of 'incoming_order_bloc.dart';

sealed class IncomingOrderState extends Equatable {
  const IncomingOrderState();

  @override
  List<Object?> get props => [];
}

class IncomingOrderInitial extends IncomingOrderState {}

class IncomingOrderLoading extends IncomingOrderState {}

class IncomingOrderEmpty extends IncomingOrderState {
  const IncomingOrderEmpty();
}

class IncomingOrderPending extends IncomingOrderState {
  const IncomingOrderPending({
    required this.order,
    required this.remainingSeconds,
  });

  final Order order;
  final int remainingSeconds;

  IncomingOrderPending copyWith({Order? order, int? remainingSeconds}) {
    return IncomingOrderPending(
      order: order ?? this.order,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
    );
  }

  @override
  List<Object?> get props => [order, remainingSeconds];
}

class IncomingOrderProcessing extends IncomingOrderState {}

class IncomingOrderAccepted extends IncomingOrderState {
  const IncomingOrderAccepted(this.orderId);

  final String orderId;

  @override
  List<Object?> get props => [orderId];
}

class IncomingOrderRejected extends IncomingOrderState {
  const IncomingOrderRejected();
}

class IncomingOrderExpired extends IncomingOrderState {
  const IncomingOrderExpired();
}

class IncomingOrderError extends IncomingOrderState {
  const IncomingOrderError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

class IncomingOrderActionError extends IncomingOrderState {
  const IncomingOrderActionError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
