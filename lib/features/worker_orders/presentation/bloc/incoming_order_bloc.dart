import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart' hide Order;

import '../../../../core/error/failures.dart';
import '../../../orders/domain/entities/order.dart';
import '../../domain/repositories/incoming_order_repository.dart';

part 'incoming_order_event.dart';
part 'incoming_order_state.dart';

@injectable
class IncomingOrderBloc extends Bloc<IncomingOrderEvent, IncomingOrderState> {
  IncomingOrderBloc(this.repository) : super(IncomingOrderInitial()) {
    on<FetchIncomingOrders>(_onFetchIncomingOrders);
    on<AcceptIncomingOrder>(_onAcceptIncomingOrder);
    on<RejectIncomingOrder>(_onRejectIncomingOrder);
    on<UpdateCountdown>(_onUpdateCountdown);
  }

  final IncomingOrderRepository repository;
  Timer? _countdownTimer;

  Future<void> _onFetchIncomingOrders(
    FetchIncomingOrders event,
    Emitter<IncomingOrderState> emit,
  ) async {
    emit(IncomingOrderLoading());
    _cancelTimer();

    final result = await repository.getIncomingOrders();

    result.fold(
      (failure) => emit(IncomingOrderError(failure)),
      (orders) {
        if (orders.isNotEmpty) {
          // Assume the first one is the active one to answer (SITUKANG usually gives 1 pending at a time)
          final activeOrder = orders.first;
          
          // Calculate remaining time
          final now = DateTime.now();
          final requestTime = activeOrder.createdAt;
          final elapsed = now.difference(requestTime).inSeconds;
          final remaining = 30 - elapsed; // 30 seconds countdown

          if (remaining > 0) {
            emit(IncomingOrderPending(
              order: activeOrder,
              remainingSeconds: remaining,
            ));
            _startTimer();
          } else {
            // Already expired
            emit(const IncomingOrderExpired());
          }
        } else {
          emit(const IncomingOrderEmpty());
        }
      },
    );
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isClosed) {
        _cancelTimer();
        return;
      }
      add(UpdateCountdown());
    });
  }

  void _cancelTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  void _onUpdateCountdown(
    UpdateCountdown event,
    Emitter<IncomingOrderState> emit,
  ) {
    if (state is IncomingOrderPending) {
      final currentState = state as IncomingOrderPending;
      if (currentState.remainingSeconds > 1) {
        emit(currentState.copyWith(
          remainingSeconds: currentState.remainingSeconds - 1,
        ));
      } else {
        _cancelTimer();
        emit(const IncomingOrderExpired());
        
        // Auto reject on server side might be handled by backend, 
        // but we can also trigger a local reject if needed.
        // For now, just mark expired.
      }
    }
  }

  Future<void> _onAcceptIncomingOrder(
    AcceptIncomingOrder event,
    Emitter<IncomingOrderState> emit,
  ) async {
    if (state is! IncomingOrderPending) return;
    
    _cancelTimer();
    emit(IncomingOrderProcessing());

    final result = await repository.acceptOrder(
      orderId: event.orderId,
      estimatedArrivalMinutes: event.estimatedArrivalMinutes,
    );

    result.fold(
      (failure) => emit(IncomingOrderActionError(failure)),
      (_) => emit(const IncomingOrderAccepted()),
    );
  }

  Future<void> _onRejectIncomingOrder(
    RejectIncomingOrder event,
    Emitter<IncomingOrderState> emit,
  ) async {
    if (state is! IncomingOrderPending) return;
    
    _cancelTimer();
    emit(IncomingOrderProcessing());

    final result = await repository.rejectOrder(
      orderId: event.orderId,
      reasonCode: event.reasonCode,
    );

    result.fold(
      (failure) => emit(IncomingOrderActionError(failure)),
      (_) => emit(const IncomingOrderRejected()),
    );
  }

  @override
  Future<void> close() {
    _cancelTimer();
    return super.close();
  }
}
