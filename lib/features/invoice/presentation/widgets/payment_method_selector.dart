import 'package:flutter/material.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';

/// Widget for selecting a payment method.
///
/// Provides options for cash, bank transfer, and e-wallet.
class PaymentMethodSelector extends StatelessWidget {
  const PaymentMethodSelector({
    required this.selectedMethod, required this.onMethodSelected, super.key,
  });

  /// The currently selected payment method.
  final PaymentMethod? selectedMethod;

  /// Callback when a method is selected.
  final ValueChanged<PaymentMethod> onMethodSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Metode Pembayaran', style: AppTypography.h5),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildMethodOption(
                method: PaymentMethod.bankTransfer,
                icon: Icons.account_balance,
                title: 'Transfer Bank',
                subtitle: 'Transfer ke rekening virtual account',
              ),
              const Divider(height: 1),
              _buildMethodOption(
                method: PaymentMethod.ewallet,
                icon: Icons.account_balance_wallet,
                title: 'E-Wallet',
                subtitle: 'Gopay, OVO, Dana, LinkAja',
              ),
              const Divider(height: 1),
              _buildMethodOption(
                method: PaymentMethod.cash,
                icon: Icons.money,
                title: 'Tunai',
                subtitle: 'Bayar langsung ke tukang',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMethodOption({
    required PaymentMethod method,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = method == selectedMethod;

    return InkWell(
      onTap: () => onMethodSelected(method),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: AppSizing.iconMd,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.h6.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
            Radio<PaymentMethod>(
              value: method,
              groupValue: selectedMethod,
              onChanged: (value) {
                if (value != null) {
                  onMethodSelected(value);
                }
              },
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
