import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/theme.dart';
import '../../../invoice/domain/entities/invoice.dart';
import '../../../invoice/domain/repositories/invoice_repository.dart';
import '../../domain/entities/worker_order_detail.dart';
import '../../domain/repositories/worker_order_repository.dart';

class WorkerInvoicePage extends StatefulWidget {
  const WorkerInvoicePage({required this.orderId, this.invoice, super.key});

  final String orderId;
  final Invoice? invoice;

  static const _brandTeal = Color(0xFF00647C);
  static const _screenBackground = Color(0xFFF7F8FE);

  @override
  State<WorkerInvoicePage> createState() => _WorkerInvoicePageState();
}

class _WorkerInvoicePageState extends State<WorkerInvoicePage> {
  Invoice? _invoice;
  WorkerOrderDetail? _orderDetail;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _invoice = widget.invoice;
    _refreshInvoice();
  }

  Future<void> _refreshInvoice() async {
    setState(() => _isLoading = true);
    final invoiceResult = await getIt<InvoiceRepository>().getInvoice(orderId: widget.orderId);
    final orderResult = await getIt<WorkerOrderRepository>().getOrderDetail(widget.orderId);
    if (!mounted) return;
    setState(() => _isLoading = false);

    invoiceResult.fold(
      (failure) {
        // Suppress error snackbar popups (e.g. DioException Resource Not Found) as requested
      },
      (invoice) {
        setState(() => _invoice = invoice);
      },
    );

    orderResult.fold(
      (failure) {},
      (orderDetail) {
        setState(() => _orderDetail = orderDetail);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'id');
    final serviceFee = _invoice?.baseServiceFee ?? _orderDetail?.baseServiceFee ?? 0;
    final materialTotal = _invoice?.materialsTotal ?? _orderDetail?.totalMaterialCost ?? 0;
    final additionalCost = _invoice?.additionalCostTotal ?? _orderDetail?.totalAdditionalCost ?? 0;
    final bookingFee = _invoice?.bookingFee ?? _orderDetail?.bookingFee ?? 0;
    final platformFee = _invoice?.platformFee ?? 0;
    final discount = _invoice?.discount ?? 0;
    final computedTotal =
        serviceFee +
        materialTotal +
        additionalCost +
        bookingFee +
        platformFee -
        discount;
    final total = (_invoice?.grandTotal ?? 0) > 0
        ? _invoice!.grandTotal
        : (_orderDetail?.grandTotal ?? 0) > 0
            ? _orderDetail!.grandTotal!
            : computedTotal;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: WorkerInvoicePage._screenBackground,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset + 144),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _CircleIconButton(
                    icon: Icons.arrow_back,
                    onTap: () => context.pop(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      (_invoice?.status == PaymentStatus.paid || _orderDetail?.status == OrderStatus.paid)
                          ? 'Pembayaran Selesai'
                          : 'Menunggu Pembayaran',
                      style: AppTypography.label.copyWith(
                        color: WorkerInvoicePage._brandTeal,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              Text(
                (_invoice?.status == PaymentStatus.paid || _orderDetail?.status == OrderStatus.paid)
                    ? 'Pembayaran Berhasil'
                    : 'Terima Pembayaran Tunai',
                textAlign: TextAlign.center,
                style: AppTypography.h3.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                (_invoice?.status == PaymentStatus.paid || _orderDetail?.status == OrderStatus.paid)
                    ? 'Pelanggan telah melunasi pembayaran untuk pekerjaan ini.'
                    : 'Silakan kumpulkan pembayaran tunai dari pelanggan sesuai total di bawah.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'RINGKASAN INVOICE',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              _SummaryCard(
                formatter: formatter,
                serviceFee: serviceFee,
                materialTotal: materialTotal,
                total: total,
              ),
              const SizedBox(height: 22),
              Text(
                'INFORMASI PELANGGAN',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              _CustomerCard(
                customerName: _orderDetail?.customer?.fullName,
                customerAvatar: _orderDetail?.customer?.avatarUrl,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 22,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (_invoice?.status == PaymentStatus.paid || _orderDetail?.status == OrderStatus.paid)
                                ? 'Total Biaya Telah Dibayar'
                                : 'Total Biaya Yang Harus Dibayarkan',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Rp ${formatter.format(total)}',
                            style: AppTypography.h4.copyWith(
                              color: WorkerInvoicePage._brandTeal,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Jasa: Rp ${formatter.format(serviceFee)}\nMaterial: Rp ${formatter.format(materialTotal)}',
                      textAlign: TextAlign.right,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (_invoice?.status == PaymentStatus.paid || _orderDetail?.status == OrderStatus.paid)
                  _SlideActionButton(
                    text: 'GESER UNTUK MENYELESAIKAN PEKERJAAN',
                    onCompleted: () async {
                      await getIt<WorkerOrderRepository>().updateOrderStatus(
                        orderId: widget.orderId,
                        status: 'completed',
                      );
                      if (context.mounted) {
                        context.go('/worker');
                      }
                    },
                  )
                else
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 54,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF0F6),
                          borderRadius: BorderRadius.circular(AppSizing.radiusFull),
                          border: Border.all(color: const Color(0xFFD7E0EA)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.lock_clock_outlined,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Menunggu pembayaran pelanggan',
                              style: AppTypography.buttonMedium.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _refreshInvoice,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.refresh, size: 18),
                        label: const Text('Cek Status Pembayaran'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: WorkerInvoicePage._brandTeal,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.formatter,
    required this.serviceFee,
    required this.materialTotal,
    required this.total,
  });

  final NumberFormat formatter;
  final int serviceFee;
  final int materialTotal;
  final int total;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E6EC)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _SummaryRow(
              label: 'Biaya Jasa',
              value: 'Rp ${formatter.format(serviceFee)}',
            ),
            const SizedBox(height: 10),
            _SummaryRow(
              label: 'Biaya Material',
              value: 'Rp ${formatter.format(materialTotal)}',
            ),
            const Divider(height: 28),
            _SummaryRow(
              label: 'Total Tagihan',
              value: 'Rp ${formatter.format(total)}',
              prominent: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.prominent = false,
  });

  final String label;
  final String value;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: prominent
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              fontWeight: prominent ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            color: prominent
                ? WorkerInvoicePage._brandTeal
                : AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    this.customerName,
    this.customerAvatar,
  });

  final String? customerName;
  final String? customerAvatar;

  @override
  Widget build(BuildContext context) {
    final avatar = customerAvatar?.trim();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E6EC)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFE5D8C4),
            backgroundImage: avatar == null || avatar.isEmpty ? null : NetworkImage(avatar),
            child: avatar == null || avatar.isEmpty
                ? const Icon(Icons.person, color: WorkerInvoicePage._brandTeal)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerName ?? 'Pelanggan Setia',
                  style: AppTypography.label.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Pelanggan',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFFFB020),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble_outline, size: 18),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE9F2FF),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 18, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _SlideActionButton extends StatefulWidget {
  const _SlideActionButton({required this.text, required this.onCompleted});

  final String text;
  final VoidCallback onCompleted;

  @override
  State<_SlideActionButton> createState() => _SlideActionButtonState();
}

class _SlideActionButtonState extends State<_SlideActionButton> {
  static const _gojekGreen = Color(0xFF00AA13);
  double _progress = 0;
  bool _completed = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const knobSize = 48.0;
        final maxTravel = constraints.maxWidth - knobSize;
        final knobLeft = maxTravel * _progress;

        return GestureDetector(
          onHorizontalDragUpdate: _completed
              ? null
              : (details) {
                  setState(() {
                    _progress = (_progress + details.delta.dx / maxTravel)
                        .clamp(0.0, 1.0);
                  });
                },
          onHorizontalDragEnd: _completed
              ? null
              : (_) {
                  if (_progress >= 0.92) {
                    _completed = true;
                    setState(() => _progress = 1);
                    HapticFeedback.heavyImpact();
                    SystemSound.play(SystemSoundType.alert);
                    widget.onCompleted();
                  } else {
                    setState(() => _progress = 0);
                  }
                },
          child: SizedBox(
            height: 56,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFCFE0FF),
                    borderRadius: BorderRadius.circular(AppSizing.radiusFull),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: _progress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _gojekGreen,
                      borderRadius: BorderRadius.circular(AppSizing.radiusFull),
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 64),
                    child: Text(
                      widget.text,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: WorkerInvoicePage._brandTeal,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 80),
                  left: knobLeft,
                  child: Container(
                    width: knobSize,
                    height: knobSize,
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: WorkerInvoicePage._brandTeal,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.chevron_right, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
