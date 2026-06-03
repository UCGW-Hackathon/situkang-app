import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/repositories/worker_purchase_repository.dart';

part 'worker_purchase_event.dart';
part 'worker_purchase_state.dart';

@injectable
class WorkerPurchaseBloc extends Bloc<WorkerPurchaseEvent, WorkerPurchaseState> {
  WorkerPurchaseBloc(this.repository) : super(WorkerPurchaseInitial()) {
    on<AddManualPurchase>(_onAddManualPurchase);
    on<ProcessAiPurchase>(_onProcessAiPurchase);
    on<ScanReceiptPurchase>(_onScanReceiptPurchase);
    on<SubmitPurchaseForApproval>(_onSubmitPurchaseForApproval);
    on<DeleteDraftPurchase>(_onDeleteDraftPurchase);
    on<RespondToClarification>(_onRespondToClarification);
  }

  final WorkerPurchaseRepository repository;

  Future<void> _onAddManualPurchase(
    AddManualPurchase event,
    Emitter<WorkerPurchaseState> emit,
  ) async {
    emit(WorkerPurchaseLoading());

    final result = await repository.addPurchase(
      orderId: event.orderId,
      itemName: event.itemName,
      category: event.category,
      quantity: event.quantity,
      unit: event.unit,
      unitPrice: event.unitPrice,
      totalPrice: event.totalPrice,
      reason: event.reason,
      receiptPhotoPath: event.receiptPhotoPath,
    );

    result.fold(
      (failure) => emit(WorkerPurchaseError(failure)),
      (purchase) => emit(WorkerPurchaseSuccess(purchase: purchase)),
    );
  }

  Future<void> _onProcessAiPurchase(
    ProcessAiPurchase event,
    Emitter<WorkerPurchaseState> emit,
  ) async {
    emit(WorkerPurchaseAiProcessing());

    final result = await repository.processAiInput(
      orderId: event.orderId,
      rawText: event.rawText,
    );

    result.fold(
      (failure) => emit(WorkerPurchaseError(failure)),
      (purchases) => emit(WorkerPurchaseBatchSuccess(purchases)),
    );
  }

  Future<void> _onScanReceiptPurchase(
    ScanReceiptPurchase event,
    Emitter<WorkerPurchaseState> emit,
  ) async {
    emit(WorkerPurchaseOcrProcessing());

    final result = await repository.scanReceipt(
      orderId: event.orderId,
      photoPath: event.photoPath,
    );

    result.fold(
      (failure) => emit(WorkerPurchaseError(failure)),
      (purchases) => emit(WorkerPurchaseBatchSuccess(purchases)),
    );
  }

  Future<void> _onSubmitPurchaseForApproval(
    SubmitPurchaseForApproval event,
    Emitter<WorkerPurchaseState> emit,
  ) async {
    emit(WorkerPurchaseLoading());

    final result = await repository.submitForApproval(
      orderId: event.orderId,
      purchaseId: event.purchaseId,
    );

    result.fold(
      (failure) => emit(WorkerPurchaseError(failure)),
      (purchase) => emit(WorkerPurchaseSuccess(
        purchase: purchase,
        message: 'Pembelian diajukan untuk persetujuan.',
      )),
    );
  }

  Future<void> _onDeleteDraftPurchase(
    DeleteDraftPurchase event,
    Emitter<WorkerPurchaseState> emit,
  ) async {
    emit(WorkerPurchaseLoading());

    final result = await repository.deleteDraft(
      orderId: event.orderId,
      purchaseId: event.purchaseId,
    );

    result.fold(
      (failure) => emit(WorkerPurchaseError(failure)),
      (_) => emit(WorkerPurchaseDeleted(event.purchaseId)),
    );
  }

  Future<void> _onRespondToClarification(
    RespondToClarification event,
    Emitter<WorkerPurchaseState> emit,
  ) async {
    emit(WorkerPurchaseLoading());

    final result = await repository.respondToClarification(
      orderId: event.orderId,
      purchaseId: event.purchaseId,
      responseText: event.responseText,
      updatedItemName: event.updatedItemName,
      updatedReason: event.updatedReason,
    );

    result.fold(
      (failure) => emit(WorkerPurchaseError(failure)),
      (purchase) => emit(WorkerPurchaseSuccess(
        purchase: purchase,
        message: 'Klarifikasi berhasil dikirim.',
      )),
    );
  }
}
