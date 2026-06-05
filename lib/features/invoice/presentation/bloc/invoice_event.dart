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
    required this.orderId,
    required this.paymentMethod,
  });

  final String orderId;
  final String paymentMethod;

  @override
  List<Object?> get props => [orderId, paymentMethod];
}

class UploadPaymentProof extends InvoiceEvent {
  const UploadPaymentProof({
    required this.orderId,
    required this.proofImage,
  });

  final String orderId;
  final File proofImage;

  @override
  List<Object?> get props => [orderId, proofImage];
}

class DownloadInvoice extends InvoiceEvent {
  const DownloadInvoice({required this.orderId});

  final String orderId;

  @override
  List<Object?> get props => [orderId];
}
