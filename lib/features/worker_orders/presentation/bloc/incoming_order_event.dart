part of 'incoming_order_bloc.dart';

sealed class IncomingOrderEvent extends Equatable {
  const IncomingOrderEvent();

  @override
  List<Object?> get props => [];
}

class FetchIncomingOrders extends IncomingOrderEvent {}

class UpdateCountdown extends IncomingOrderEvent {}

class AcceptIncomingOrder extends IncomingOrderEvent {
  const AcceptIncomingOrder({
    required this.orderId,
    this.estimatedArrivalMinutes,
  });

  final String orderId;
  final int? estimatedArrivalMinutes;

  @override
  List<Object?> get props => [orderId, estimatedArrivalMinutes];
}

class RejectIncomingOrder extends IncomingOrderEvent {
  const RejectIncomingOrder({
    required this.orderId,
    required this.reasonCode,
  });

  final String orderId;
  final String reasonCode;

  @override
  List<Object?> get props => [orderId, reasonCode];
}
