import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/websocket_events.dart';
import '../../../../core/network/websocket_manager.dart';
import '../../data/models/purchase_model.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/entities/purchase_summary.dart';
import '../../domain/repositories/purchase_repository.dart';

part 'purchase_event.dart';
part 'purchase_state.dart';

/// BLoC responsible for managing purchase state on the User side.
///
/// Handles fetching purchases, approving, rejecting, requesting clarification,
/// bulk approval, and real-time new purchase events via WebSocket.
///
/// Validates:
/// - Requirement 10.1: Display purchase items with all fields
/// - Requirement 10.3: Approve pending purchases
/// - Requirement 10.4: Reject with reason (1-1000 chars)
/// - Requirement 10.5: Request clarification (1-1000 chars)
/// - Requirement 10.6: Bulk approval
/// - Requirement 10.7: Purchase summary display
/// - Requirement 10.8: WebSocket new_purchase events (within 2 seconds)
/// - Requirement 10.9: Status validation (only pending_approval actionable)
/// - Requirement 10.10: Network error handling (preserve previous status)
@injectable
class PurchaseBloc extends Bloc<PurchaseEvent, PurchaseState> {
  /// Creates a [PurchaseBloc] with the required dependencies.
  PurchaseBloc({
    required PurchaseRepository purchaseRepository,
    required WebSocketManager webSocketManager,
  })  : _purchaseRepository = purchaseRepository,
        _webSocketManager = webSocketManager,
        super(const PurchaseInitial()) {
    on<FetchPurchases>(_onFetchPurchases);
    on<ApprovePurchase>(_onApprovePurchase);
    on<RejectPurchase>(_onRejectPurchase);
    on<RequestClarification>(_onRequestClarification);
    on<BulkApprove>(_onBulkApprove);
    on<NewPurchaseReceived>(_onNewPurchaseReceived);

    _webSocketSubscription = _webSocketManager.eventStream.listen(_onWebSocketEvent);
  }

  final PurchaseRepository _purchaseRepository;
  final WebSocketManager _webSocketManager;
  StreamSubscription<WebSocketEvent>? _webSocketSubscription;

  /// Handles incoming WebSocket events, filtering for new_purchase events.
  void _onWebSocketEvent(WebSocketEvent event) {
    if (event is NewPurchaseEvent) {
      final purchase = PurchaseModel.fromJson(event.purchaseData).toEntity();
      add(NewPurchaseReceived(purchase: purchase));
    }
  }

  /// Handles [FetchPurchases] events.
  ///
  /// Emits [PurchaseLoading], then either [PurchaseLoaded] on success
  /// or [PurchaseError] on failure.
  Future<void> _onFetchPurchases(
    FetchPurchases event,
    Emitter<PurchaseState> emit,
  ) async {
    emit(const PurchaseLoading());

    final result = await _purchaseRepository.getPurchases(event.orderId);

    result.fold(
      (failure) => emit(PurchaseError(failure: failure)),
      (data) => emit(PurchaseLoaded(
        purchases: data.$1,
        summary: data.$2,
      )),
    );
  }

  /// Handles [ApprovePurchase] events.
  ///
  /// Validates that the purchase is in "pending_approval" status before
  /// attempting the action. On network error, preserves previous status.
  /// Validates: Requirements 10.3, 10.9, 10.10.
  Future<void> _onApprovePurchase(
    ApprovePurchase event,
    Emitter<PurchaseState> emit,
  ) async {
    final currentState = state;
    if (currentState is! PurchaseLoaded) return;

    // Validate status (Requirement 10.9)
    final purchase = currentState.purchases.firstWhere(
      (p) => p.id == event.purchaseId,
      orElse: () => currentState.purchases.first,
    );
    if (!purchase.status.isActionable) {
      emit(currentState.copyWith(
        actionError: () => const ServerFailure(
          'Aksi tidak diizinkan untuk status pembelian saat ini',
          statusCode: 422,
        ),
      ));
      return;
    }

    // Set loading for this specific purchase
    emit(currentState.copyWith(
      actionLoadingIds: {...currentState.actionLoadingIds, event.purchaseId},
      actionError: () => null,
    ));

    final result = await _purchaseRepository.approvePurchase(
      event.orderId,
      event.purchaseId,
    );

    result.fold(
      // Requirement 10.10: preserve previous status on error
      (failure) => emit(currentState.copyWith(
        actionLoadingIds: currentState.actionLoadingIds
            .difference({event.purchaseId}),
        actionError: () => failure,
      )),
      (updatedPurchase) {
        final updatedList = currentState.purchases.map((p) {
          return p.id == event.purchaseId ? updatedPurchase : p;
        }).toList();
        emit(currentState.copyWith(
          purchases: updatedList,
          summary: _recalculateSummary(updatedList, currentState.summary),
          actionLoadingIds: currentState.actionLoadingIds
              .difference({event.purchaseId}),
          actionError: () => null,
        ));
      },
    );
  }

  /// Handles [RejectPurchase] events.
  ///
  /// Validates status and reason length before attempting the action.
  /// Validates: Requirements 10.4, 10.9, 10.10.
  Future<void> _onRejectPurchase(
    RejectPurchase event,
    Emitter<PurchaseState> emit,
  ) async {
    final currentState = state;
    if (currentState is! PurchaseLoaded) return;

    // Validate reason length
    if (event.reason.isEmpty || event.reason.length > 1000) {
      emit(currentState.copyWith(
        actionError: () => const ValidationFailure(
          'Alasan penolakan harus 1-1000 karakter',
          fieldErrors: {'reason': 'Alasan penolakan harus 1-1000 karakter'},
        ),
      ));
      return;
    }

    // Validate status (Requirement 10.9)
    final purchase = currentState.purchases.firstWhere(
      (p) => p.id == event.purchaseId,
      orElse: () => currentState.purchases.first,
    );
    if (!purchase.status.isActionable) {
      emit(currentState.copyWith(
        actionError: () => const ServerFailure(
          'Aksi tidak diizinkan untuk status pembelian saat ini',
          statusCode: 422,
        ),
      ));
      return;
    }

    emit(currentState.copyWith(
      actionLoadingIds: {...currentState.actionLoadingIds, event.purchaseId},
      actionError: () => null,
    ));

    final result = await _purchaseRepository.rejectPurchase(
      event.orderId,
      event.purchaseId,
      event.reason,
    );

    result.fold(
      (failure) => emit(currentState.copyWith(
        actionLoadingIds: currentState.actionLoadingIds
            .difference({event.purchaseId}),
        actionError: () => failure,
      )),
      (updatedPurchase) {
        final updatedList = currentState.purchases.map((p) {
          return p.id == event.purchaseId ? updatedPurchase : p;
        }).toList();
        emit(currentState.copyWith(
          purchases: updatedList,
          summary: _recalculateSummary(updatedList, currentState.summary),
          actionLoadingIds: currentState.actionLoadingIds
              .difference({event.purchaseId}),
          actionError: () => null,
        ));
      },
    );
  }

  /// Handles [RequestClarification] events.
  ///
  /// Validates status and question length before attempting the action.
  /// Validates: Requirements 10.5, 10.9, 10.10.
  Future<void> _onRequestClarification(
    RequestClarification event,
    Emitter<PurchaseState> emit,
  ) async {
    final currentState = state;
    if (currentState is! PurchaseLoaded) return;

    // Validate question length
    if (event.question.isEmpty || event.question.length > 1000) {
      emit(currentState.copyWith(
        actionError: () => const ValidationFailure(
          'Pertanyaan klarifikasi harus 1-1000 karakter',
          fieldErrors: {'question': 'Pertanyaan klarifikasi harus 1-1000 karakter'},
        ),
      ));
      return;
    }

    // Validate status (Requirement 10.9)
    final purchase = currentState.purchases.firstWhere(
      (p) => p.id == event.purchaseId,
      orElse: () => currentState.purchases.first,
    );
    if (!purchase.status.isActionable) {
      emit(currentState.copyWith(
        actionError: () => const ServerFailure(
          'Aksi tidak diizinkan untuk status pembelian saat ini',
          statusCode: 422,
        ),
      ));
      return;
    }

    emit(currentState.copyWith(
      actionLoadingIds: {...currentState.actionLoadingIds, event.purchaseId},
      actionError: () => null,
    ));

    final result = await _purchaseRepository.requestClarification(
      event.orderId,
      event.purchaseId,
      event.question,
    );

    result.fold(
      (failure) => emit(currentState.copyWith(
        actionLoadingIds: currentState.actionLoadingIds
            .difference({event.purchaseId}),
        actionError: () => failure,
      )),
      (updatedPurchase) {
        final updatedList = currentState.purchases.map((p) {
          return p.id == event.purchaseId ? updatedPurchase : p;
        }).toList();
        emit(currentState.copyWith(
          purchases: updatedList,
          summary: _recalculateSummary(updatedList, currentState.summary),
          actionLoadingIds: currentState.actionLoadingIds
              .difference({event.purchaseId}),
          actionError: () => null,
        ));
      },
    );
  }

  /// Handles [BulkApprove] events.
  ///
  /// Validates that all selected purchases are in "pending_approval" status.
  /// Validates: Requirements 10.6, 10.9, 10.10.
  Future<void> _onBulkApprove(
    BulkApprove event,
    Emitter<PurchaseState> emit,
  ) async {
    final currentState = state;
    if (currentState is! PurchaseLoaded) return;

    if (event.purchaseIds.isEmpty) return;

    // Validate all selected purchases are actionable (Requirement 10.9)
    final nonActionable = currentState.purchases
        .where((p) => event.purchaseIds.contains(p.id) && !p.status.isActionable)
        .toList();
    if (nonActionable.isNotEmpty) {
      emit(currentState.copyWith(
        actionError: () => const ServerFailure(
          'Beberapa item tidak dalam status yang dapat disetujui',
          statusCode: 422,
        ),
      ));
      return;
    }

    emit(currentState.copyWith(
      actionLoadingIds: {...currentState.actionLoadingIds, ...event.purchaseIds},
      actionError: () => null,
    ));

    final result = await _purchaseRepository.bulkApprove(
      event.orderId,
      event.purchaseIds,
    );

    result.fold(
      (failure) => emit(currentState.copyWith(
        actionLoadingIds: currentState.actionLoadingIds
            .difference(event.purchaseIds.toSet()),
        actionError: () => failure,
      )),
      (updatedPurchases) {
        final updatedMap = {for (final p in updatedPurchases) p.id: p};
        final updatedList = currentState.purchases.map((p) {
          return updatedMap[p.id] ?? p;
        }).toList();
        emit(currentState.copyWith(
          purchases: updatedList,
          summary: _recalculateSummary(updatedList, currentState.summary),
          actionLoadingIds: currentState.actionLoadingIds
              .difference(event.purchaseIds.toSet()),
          actionError: () => null,
        ));
      },
    );
  }

  /// Handles [NewPurchaseReceived] events from WebSocket.
  ///
  /// Appends the new purchase to the list and recalculates the summary.
  /// Validates: Requirement 10.8 (display within 2 seconds).
  void _onNewPurchaseReceived(
    NewPurchaseReceived event,
    Emitter<PurchaseState> emit,
  ) {
    final currentState = state;
    if (currentState is! PurchaseLoaded) return;

    // Avoid duplicates
    final exists = currentState.purchases.any((p) => p.id == event.purchase.id);
    if (exists) return;

    final updatedList = [event.purchase, ...currentState.purchases];
    emit(currentState.copyWith(
      purchases: updatedList,
      summary: _recalculateSummary(updatedList, currentState.summary),
    ));
  }

  /// Recalculates the purchase summary based on the current purchase list.
  ///
  /// Preserves the AI summary text from the original summary.
  PurchaseSummary _recalculateSummary(
    List<Purchase> purchases,
    PurchaseSummary originalSummary,
  ) {
    var approvedCost = 0;
    var pendingCost = 0;
    var rejectedCost = 0;
    var needsClarificationCost = 0;
    var totalCost = 0;

    for (final purchase in purchases) {
      totalCost += purchase.totalPrice;
      switch (purchase.status) {
        case PurchaseStatus.approved:
          approvedCost += purchase.totalPrice;
        case PurchaseStatus.pendingApproval:
          pendingCost += purchase.totalPrice;
        case PurchaseStatus.rejected:
          rejectedCost += purchase.totalPrice;
        case PurchaseStatus.needsClarification:
          needsClarificationCost += purchase.totalPrice;
        case PurchaseStatus.draft:
          break;
      }
    }

    return PurchaseSummary(
      totalItems: purchases.length,
      totalCost: totalCost,
      approvedCost: approvedCost,
      pendingCost: pendingCost,
      rejectedCost: rejectedCost,
      needsClarificationCost: needsClarificationCost,
      aiSummary: originalSummary.aiSummary,
    );
  }

  @override
  Future<void> close() {
    _webSocketSubscription?.cancel();
    return super.close();
  }
}
