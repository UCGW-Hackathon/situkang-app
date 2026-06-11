import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';

class OrderPaymentSuccessPage extends StatelessWidget {
  const OrderPaymentSuccessPage({
    required this.orderId,
    this.workerName,
    this.serviceName,
    this.total,
    this.paymentMethod,
    super.key,
  });

  final String orderId;
  final String? workerName;
  final String? serviceName;
  final int? total;
  final String? paymentMethod;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'id');
    final totalLabel = total == null ? '-' : 'Rp ${formatter.format(total)}';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Container(
                width: 92,
                height: 92,
                margin: const EdgeInsets.only(bottom: 22),
                decoration: const BoxDecoration(
                  color: Color(0xFFE7F8ED),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF00AA13),
                  size: 54,
                ),
              ),
              Text(
                'Terima kasih sudah memakai jasa SITUKANG',
                textAlign: TextAlign.center,
                style: AppTypography.h2.copyWith(
                  color: const Color(0xFF111827),
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Pembayaran Anda sudah kami catat. Semoga rumahnya makin nyaman.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE4EAF0)),
                ),
                child: Column(
                  children: [
                    _SuccessInfoRow(
                      label: 'Pesanan',
                      value: serviceName?.isNotEmpty == true
                          ? serviceName!
                          : orderId,
                    ),
                    const SizedBox(height: 12),
                    _SuccessInfoRow(
                      label: 'Tukang',
                      value: workerName?.isNotEmpty == true
                          ? workerName!
                          : 'Tukang',
                    ),
                    const SizedBox(height: 12),
                    _SuccessInfoRow(
                      label: 'Metode',
                      value: paymentMethod ?? 'Cash',
                    ),
                    const Divider(height: 26),
                    _SuccessInfoRow(
                      label: 'Total',
                      value: totalLabel,
                      emphasize: true,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.home_outlined, size: 18),
                label: const Text('Kembali ke Home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007C92),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: AppTypography.buttonMedium.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => context.go('/orders'),
                child: const Text('Lihat Riwayat Pesanan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessInfoRow extends StatelessWidget {
  const _SuccessInfoRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: (emphasize ? AppTypography.h5 : AppTypography.bodyMedium)
                .copyWith(
                  color: emphasize
                      ? const Color(0xFF007C92)
                      : const Color(0xFF111827),
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
      ],
    );
  }
}
