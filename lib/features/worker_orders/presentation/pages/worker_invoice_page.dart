import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../invoice/domain/entities/invoice.dart';

class WorkerInvoicePage extends StatelessWidget {
  const WorkerInvoicePage({required this.orderId, this.invoice, super.key});

  final String orderId;
  final Invoice? invoice;

  static const _brandTeal = Color(0xFF00647C);
  static const _screenBackground = Color(0xFFF7F8FE);

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'id');
    final total = invoice?.grandTotal ?? 0;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _screenBackground,
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
                      'Menunggu Pembayaran',
                      style: AppTypography.label.copyWith(
                        color: _brandTeal,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              Text(
                'Terima Pembayaran Tunai',
                textAlign: TextAlign.center,
                style: AppTypography.h3.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Silakan kumpulkan pembayaran tunai dari pelanggan sesuai total di bawah.',
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
              _SummaryCard(formatter: formatter, invoice: invoice),
              const SizedBox(height: 22),
              Text(
                'INFORMASI PELANGGAN',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              _CustomerCard(),
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
                            'Total Biaya Yang Harus Dibayarkan',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Rp ${formatter.format(total)}',
                            style: AppTypography.h4.copyWith(
                              color: _brandTeal,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Material: Rp ${formatter.format(invoice?.materialsTotal ?? 0)}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SlideActionButton(
                  text: 'GESER UNTUK SELESAI',
                  onCompleted: () => context.go('/worker'),
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
  const _SummaryCard({required this.formatter, required this.invoice});

  final NumberFormat formatter;
  final Invoice? invoice;

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
              value: 'Rp ${formatter.format(invoice?.baseServiceFee ?? 0)}',
            ),
            const SizedBox(height: 10),
            _SummaryRow(
              label: 'Biaya Material',
              value: 'Rp ${formatter.format(invoice?.materialsTotal ?? 0)}',
            ),
            const Divider(height: 28),
            _SummaryRow(
              label: 'Total Tagihan',
              value: 'Rp ${formatter.format(invoice?.grandTotal ?? 0)}',
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
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E6EC)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFFE5D8C4),
            child: Icon(Icons.person, color: WorkerInvoicePage._brandTeal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pelanggan',
                  style: AppTypography.label.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Pelanggan Setia',
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
