part of 'invoice_bloc.dart';

sealed class InvoiceState extends Equatable {
  const InvoiceState();

  @override
  List<Object?> get props => [];
}

class InvoiceInitial extends InvoiceState {}

class InvoiceLoading extends InvoiceState {}

class InvoiceLoaded extends InvoiceState {
  const InvoiceLoaded(
    this.invoice, {
    this.isPaymentLoading = false,
    this.isDownloadLoading = false,
    this.actionError,
    this.paymentSuccess = false,
    this.downloadUrl,
  });

  final Invoice invoice;
  final bool isPaymentLoading;
  final bool isDownloadLoading;
  final Failure? actionError;
  final bool paymentSuccess;
  final String? downloadUrl;

  InvoiceLoaded copyWith({
    Invoice? invoice,
    bool? isPaymentLoading,
    bool? isDownloadLoading,
    Failure? actionError,
    bool? paymentSuccess,
    String? downloadUrl,
  }) {
    return InvoiceLoaded(
      invoice ?? this.invoice,
      isPaymentLoading: isPaymentLoading ?? this.isPaymentLoading,
      isDownloadLoading: isDownloadLoading ?? this.isDownloadLoading,
      actionError: actionError, // Clear error if not explicitly provided
      paymentSuccess: paymentSuccess ?? this.paymentSuccess,
      downloadUrl: downloadUrl ?? this.downloadUrl,
    );
  }

  @override
  List<Object?> get props => [
        invoice,
        isPaymentLoading,
        isDownloadLoading,
        actionError,
        paymentSuccess,
        downloadUrl,
      ];
}

class InvoiceError extends InvoiceState {
  const InvoiceError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
