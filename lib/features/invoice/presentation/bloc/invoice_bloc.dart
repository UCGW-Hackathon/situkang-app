import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/repositories/invoice_repository.dart';

part 'invoice_event.dart';
part 'invoice_state.dart';

@injectable
class InvoiceBloc extends Bloc<InvoiceEvent, InvoiceState> {
  InvoiceBloc(this.repository) : super(InvoiceInitial()) {
    on<FetchInvoice>(_onFetchInvoice);
    on<ConfirmPayment>(_onConfirmPayment);
    on<UploadPaymentProof>(_onUploadPaymentProof);
    on<DownloadInvoice>(_onDownloadInvoice);
  }

  final InvoiceRepository repository;

  Future<void> _onFetchInvoice(
    FetchInvoice event,
    Emitter<InvoiceState> emit,
  ) async {
    emit(InvoiceLoading());

    final result = await repository.getInvoice(orderId: event.orderId);

    result.fold(
      (failure) => emit(InvoiceError(failure)),
      (invoice) => emit(InvoiceLoaded(invoice)),
    );
  }

  Future<void> _onConfirmPayment(
    ConfirmPayment event,
    Emitter<InvoiceState> emit,
  ) async {
    if (state is! InvoiceLoaded) return;
    final currentState = state as InvoiceLoaded;

    emit(currentState.copyWith(isPaymentLoading: true));

    final result = await repository.confirmPayment(
      invoiceId: event.invoiceId,
      paymentMethod: event.paymentMethod,
    );

    result.fold(
      (failure) => emit(currentState.copyWith(
        isPaymentLoading: false,
        actionError: failure,
      )),
      (updatedInvoice) => emit(InvoiceLoaded(
        updatedInvoice,
        paymentSuccess: true,
      )),
    );
  }

  Future<void> _onUploadPaymentProof(
    UploadPaymentProof event,
    Emitter<InvoiceState> emit,
  ) async {
    if (state is! InvoiceLoaded) return;
    final currentState = state as InvoiceLoaded;

    emit(currentState.copyWith(isPaymentLoading: true));

    final result = await repository.uploadPaymentProof(
      invoiceId: event.invoiceId,
      proofImage: event.proofImage,
    );

    result.fold(
      (failure) => emit(currentState.copyWith(
        isPaymentLoading: false,
        actionError: failure,
      )),
      (updatedInvoice) => emit(InvoiceLoaded(
        updatedInvoice,
        paymentSuccess: true,
      )),
    );
  }

  Future<void> _onDownloadInvoice(
    DownloadInvoice event,
    Emitter<InvoiceState> emit,
  ) async {
    if (state is! InvoiceLoaded) return;
    final currentState = state as InvoiceLoaded;

    emit(currentState.copyWith(isDownloadLoading: true));

    final result = await repository.downloadInvoicePdf(
      invoiceId: event.invoiceId,
    );

    result.fold(
      (failure) => emit(currentState.copyWith(
        isDownloadLoading: false,
        actionError: failure,
      )),
      (url) => emit(currentState.copyWith(
        isDownloadLoading: false,
        downloadUrl: url,
      )),
    );
  }
}
