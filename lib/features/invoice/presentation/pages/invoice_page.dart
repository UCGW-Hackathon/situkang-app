import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/invoice.dart';
import '../bloc/invoice_bloc.dart';
import '../widgets/payment_method_selector.dart';
import '../widgets/work_summary.dart';

/// Page displaying invoice details and handling payments.
///
/// Shows line items breakdown, work summary, and payment options.
/// Validates: Requirements 12.1-12.8
class InvoicePage extends StatefulWidget {
  const InvoicePage({
    required this.orderId, super.key,
  });

  /// The order ID associated with this invoice.
  final String orderId;

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  PaymentMethod? _selectedMethod;
  File? _paymentProof;
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    context.read<InvoiceBloc>().add(FetchInvoice(orderId: widget.orderId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tagihan & Pembayaran'),
        actions: [
          BlocBuilder<InvoiceBloc, InvoiceState>(
            builder: (context, state) {
              if (state is InvoiceLoaded &&
                  state.invoice.status == PaymentStatus.paid) {
                return IconButton(
                  icon: state.isDownloadLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download),
                  onPressed: state.isDownloadLoading
                      ? null
                      : () {
                          context.read<InvoiceBloc>().add(
                                DownloadInvoice(
                                  orderId: state.invoice.orderId,
                                ),
                              );
                        },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<InvoiceBloc, InvoiceState>(
        listener: (context, state) {
          if (state is InvoiceLoaded) {
            if (state.paymentSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pembayaran berhasil diproses!'),
                  backgroundColor: AppColors.success,
                ),
              );
            } else if (state.actionError != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.actionError!.message),
                  backgroundColor: AppColors.error,
                ),
              );
            } else if (state.downloadUrl != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Invoice berhasil diunduh'),
                  backgroundColor: AppColors.success,
                ),
              );
              // In a real app, use url_launcher or open_file here
            }
          }
        },
        builder: (context, state) {
          if (state is InvoiceLoading) {
            return const LoadingIndicator();
          }

          if (state is InvoiceError) {
            // Check if it's a 404 (not yet available)
            if (state.failure.message.contains('404') ||
                state.failure.message.toLowerCase().contains('not found')) {
              return _buildNotAvailableState();
            }

            return AppErrorWidget(
              message: state.failure.message,
              onRetry: () {
                context
                    .read<InvoiceBloc>()
                    .add(FetchInvoice(orderId: widget.orderId));
              },
            );
          }

          if (state is InvoiceLoaded) {
            return _buildContent(context, state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildNotAvailableState() {
    return Center(
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: AppSizing.iconXxl,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Tagihan Belum Tersedia',
              style: AppTypography.h6.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Tagihan akan muncul setelah tukang menyelesaikan pekerjaannya.',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, InvoiceLoaded state) {
    final invoice = state.invoice;
    final isPaid = invoice.status == PaymentStatus.paid;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: AppSpacing.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusHeader(invoice),
                const SizedBox(height: AppSpacing.formSectionSpacing),
                
                WorkSummary(
                  aiSummary: invoice.aiSummary,
                  workerNotes: invoice.workerNotes,
                ),
                if (invoice.aiSummary != null || invoice.workerNotes != null)
                  const SizedBox(height: AppSpacing.formSectionSpacing),

                _buildInvoiceDetails(invoice),
                const SizedBox(height: AppSpacing.formSectionSpacing),

                if (!isPaid) ...[
                  PaymentMethodSelector(
                    selectedMethod: _selectedMethod,
                    onMethodSelected: (method) {
                      setState(() {
                        _selectedMethod = method;
                        _paymentProof = null;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.formSectionSpacing),

                  if (_selectedMethod == PaymentMethod.bankTransfer)
                    _buildPaymentProofSection(),
                ],
              ],
            ),
          ),
        ),
        if (!isPaid) _buildBottomBar(context, state),
      ],
    );
  }

  Widget _buildStatusHeader(Invoice invoice) {
    final isPaid = invoice.status == PaymentStatus.paid;

    return AppCard(
      color: isPaid
          ? AppColors.success.withValues(alpha: 0.1)
          : AppColors.warning.withValues(alpha: 0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Status Tagihan',
                style: AppTypography.caption,
              ),
              const SizedBox(height: 2),
              Text(
                isPaid ? 'LUNAS' : 'BELUM DIBAYAR',
                style: AppTypography.h6.copyWith(
                  color: isPaid ? AppColors.success : AppColors.warning,
                ),
              ),
            ],
          ),
          Icon(
            isPaid ? Icons.check_circle : Icons.pending_actions,
            color: isPaid ? AppColors.success : AppColors.warning,
            size: AppSizing.iconXl,
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceDetails(Invoice invoice) {
    final formatter = NumberFormat('#,###', 'id');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Rincian Tagihan', style: AppTypography.h5),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('No. Invoice', style: AppTypography.caption),
                  Text(
                    invoice.invoiceNumber,
                    style: AppTypography.label,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tanggal', style: AppTypography.caption),
                  Text(
                    DateFormat('dd MMM yyyy').format(invoice.createdAt),
                    style: AppTypography.label,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.md),

              // Items
              if (invoice.items.isNotEmpty) ...[
                const Text('Material & Item', style: AppTypography.label),
                const SizedBox(height: AppSpacing.xs),
                ...invoice.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, style: AppTypography.bodySmall),
                                Text(
                                  '${item.quantity} x Rp${formatter.format(item.unitPrice)}',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Rp${formatter.format(item.totalPrice)}',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: AppSpacing.sm),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.sm),
              ],

              // Summary rows
              _buildSummaryRow(
                'Biaya Layanan',
                formatter.format(invoice.baseServiceFee),
              ),
              const SizedBox(height: AppSpacing.xs),
              if (invoice.materialsTotal > 0) ...[
                _buildSummaryRow(
                  'Total Material',
                  formatter.format(invoice.materialsTotal),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              if (invoice.additionalCostTotal > 0) ...[
                _buildSummaryRow(
                  'Biaya Tambahan',
                  formatter.format(invoice.additionalCostTotal),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              _buildSummaryRow(
                'Biaya Booking',
                formatter.format(invoice.bookingFee),
              ),
              const SizedBox(height: AppSpacing.xs),
              _buildSummaryRow(
                'Biaya Platform',
                formatter.format(invoice.platformFee),
              ),
              if (invoice.discount > 0) ...[
                const SizedBox(height: AppSpacing.xs),
                _buildSummaryRow(
                  'Diskon',
                  '-Rp${formatter.format(invoice.discount)}',
                  valueColor: AppColors.success,
                  isDiscount: true,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.md),

              // Grand Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Pembayaran', style: AppTypography.h6),
                  Text(
                    'Rp${formatter.format(invoice.grandTotal)}',
                    style: AppTypography.priceLarge.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    Color? valueColor,
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodyMedium),
        Text(
          isDiscount ? value : 'Rp$value',
          style: AppTypography.label.copyWith(color: valueColor),
        ),
      ],
    );
  }

  Widget _buildPaymentProofSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Bukti Pembayaran', style: AppTypography.h5),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            children: [
              if (_paymentProof != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizing.radiusSm),
                  child: Image.file(
                    _paymentProof!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.upload_file),
                label: Text(
                  _paymentProof == null ? 'Unggah Bukti' : 'Ganti Foto',
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Format JPG/PNG, maksimal 5MB',
                style: AppTypography.caption,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile =
          await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        // Validate size (mocked, assume backend validates too)
        final file = File(pickedFile.path);
        final length = await file.length();
        if (length > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ukuran file maksimal 5MB'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }

        setState(() {
          _paymentProof = file;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih gambar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildBottomBar(BuildContext context, InvoiceLoaded state) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.pagePaddingHorizontal,
        right: AppSpacing.pagePaddingHorizontal,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppButton(
            text: 'Bayar Sekarang',
            isLoading: state.isPaymentLoading,
            isDisabled: _selectedMethod == null ||
                (_selectedMethod == PaymentMethod.bankTransfer &&
                    _paymentProof == null),
            onPressed: () {
              if (_selectedMethod == PaymentMethod.bankTransfer &&
                  _paymentProof != null) {
                context.read<InvoiceBloc>().add(
                      UploadPaymentProof(
                        orderId: state.invoice.orderId,
                        proofImage: _paymentProof!,
                      ),
                    );
              } else if (_selectedMethod != null) {
                // Determine method string representation
                final String methodStr;
                switch (_selectedMethod!) {
                  case PaymentMethod.cash:
                    methodStr = 'cash';
                  case PaymentMethod.bankTransfer:
                    methodStr = 'bank_transfer';
                  case PaymentMethod.ewallet:
                    methodStr = 'ewallet';
                }

                context.read<InvoiceBloc>().add(
                      ConfirmPayment(
                        orderId: state.invoice.orderId,
                        paymentMethod: methodStr,
                      ),
                    );
              }
            },
          ),
        ],
      ),
    );
  }
}
