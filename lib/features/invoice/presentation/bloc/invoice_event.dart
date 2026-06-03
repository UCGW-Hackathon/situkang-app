part of 'invoice_bloc.dart';

sealed class InvoiceEvent extends Equatable {
  const InvoiceEvent();

  @override
  List<Object?> get props => [];
}

class FetchInvoice extends InvoiceEvent {
  const FetchInvoice({required this.orderId});

  final String orderId;

  @override
  List<Object?> get props => [orderId];
}

class ConfirmPayment extends InvoiceEvent {
  const ConfirmPayment({
    required this.invoiceId,
    required this.paymentMethod,
  });

  final String invoiceId;
  final String paymentMethod;

  @override
  List<Object?> get props => [invoiceId, paymentMethod];
}

class UploadPaymentProof extends InvoiceEvent {
  const UploadPaymentProof({
    required this.invoiceId,
    required this.proofImage,
  });

  final String invoiceId;
  final File proofImage;

  @override
  List<Object?> get props => [invoiceId, proofImage];
}

class DownloadInvoice extends InvoiceEvent {
  const DownloadInvoice({required this.invoiceId});

  final String invoiceId;

  @override
  List<Object?> get props => [invoiceId];
}
