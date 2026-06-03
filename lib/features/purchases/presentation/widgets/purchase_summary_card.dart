import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/purchase_summary.dart';

/// Widget displaying the aggregated purchase summary.
///
/// Shows total items, total cost, and cost breakdown by status
/// (approved, pending, rejected, needs clarification), plus
/// an AI-generated summary text if available.
///
/// Validates: Requirement 10.7
class PurchaseSummaryCard extends StatelessWidget {
  const PurchaseSummaryCard({
    super.key,
    required this.summary,
  });

  /// The purchase summary data.
  final PurchaseSummary summary;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'id');

    return AppCard(
      color: AppColors.primaryContainer.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.summarize_outlined,
                color: AppColors.primary,
                size: AppSizing.iconMd,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Ringkasan Pembelian',
                style: AppTypography.h6.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Cost breakdown
          _buildSummaryRow(
            'Total Item',
            '${summary.totalItems} item',
            isPrice: false,
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildSummaryRow(
            'Total Biaya',
            'Rp${formatter.format(summary.totalCost)}',
            isBold: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),

          // Status breakdown
          _buildStatusRow(
            'Disetujui',
            'Rp${formatter.format(summary.approvedCost)}',
            AppColors.success,
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildStatusRow(
            'Menunggu Persetujuan',
            'Rp${formatter.format(summary.pendingCost)}',
            AppColors.warning,
          ),
          if (summary.rejectedCost > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            _buildStatusRow(
              'Ditolak',
              'Rp${formatter.format(summary.rejectedCost)}',
              AppColors.error,
            ),
          ],
          if (summary.needsClarificationCost > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            _buildStatusRow(
              'Perlu Klarifikasi',
              'Rp${formatter.format(summary.needsClarificationCost)}',
              AppColors.info,
            ),
          ],

          // AI summary
          if (summary.aiSummary != null && summary.aiSummary!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: AppSpacing.cardPaddingSmall,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizing.radiusSm),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: AppSizing.iconSm,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      summary.aiSummary!,
                      style: AppTypography.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isPrice = true,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodyMedium),
        Text(
          value,
          style: isBold ? AppTypography.priceMedium : AppTypography.label,
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(label, style: AppTypography.bodySmall),
          ],
        ),
        Text(
          value,
          style: AppTypography.label.copyWith(color: color),
        ),
      ],
    );
  }
}
