import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/entities/purchase_summary.dart';
import '../../domain/entities/risk_flag.dart';
import '../bloc/purchase_bloc.dart';
import '../widgets/purchase_summary_card.dart';

/// Page displaying purchase items for an order with approval controls.
///
/// Shows purchases with AI confidence scores, risk flags, and allows
/// the user to approve, reject, or request clarification on items.
///
/// Validates: Requirements 10.1-10.10
class PurchaseListPage extends StatefulWidget {
  const PurchaseListPage({
    super.key,
    required this.orderId,
  });

  /// The order ID to fetch purchases for.
  final String orderId;

  @override
  State<PurchaseListPage> createState() => _PurchaseListPageState();
}

class _PurchaseListPageState extends State<PurchaseListPage> {
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    context.read<PurchaseBloc>().add(FetchPurchases(orderId: widget.orderId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembelian Material'),
        actions: [
          if (_isSelectionMode && _selectedIds.isNotEmpty)
            TextButton.icon(
              onPressed: _bulkApprove,
              icon: const Icon(Icons.check_circle, color: AppColors.success),
              label: Text(
                'Setujui (${_selectedIds.length})',
                style: AppTypography.buttonMedium.copyWith(
                  color: AppColors.success,
                ),
              ),
            ),
        ],
      ),
      body: BlocConsumer<PurchaseBloc, PurchaseState>(
        listener: (context, state) {
          if (state is PurchaseLoaded && state.actionError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.actionError!.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is PurchaseLoading) {
            return const LoadingIndicator();
          }

          if (state is PurchaseError) {
            return AppErrorWidget(
              message: state.failure.message,
              onRetry: () {
                context.read<PurchaseBloc>().add(
                      FetchPurchases(orderId: widget.orderId),
                    );
              },
            );
          }

          if (state is PurchaseLoaded) {
            return _buildContent(state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(PurchaseLoaded state) {
    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Purchase summary
          PurchaseSummaryCard(summary: state.summary),
          const SizedBox(height: AppSpacing.formSectionSpacing),

          // Selection mode toggle
          if (state.purchases.any((p) => p.status.isActionable))
            _buildSelectionToggle(state),

          const SizedBox(height: AppSpacing.sm),

          // Purchase list
          if (state.purchases.isEmpty)
            _buildEmptyState()
          else
            ...state.purchases.map(
              (purchase) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _PurchaseItemCard(
                  purchase: purchase,
                  isLoading: state.actionLoadingIds.contains(purchase.id),
                  isSelected: _selectedIds.contains(purchase.id),
                  isSelectionMode: _isSelectionMode,
                  onApprove: () => _approvePurchase(purchase),
                  onReject: () => _showRejectDialog(purchase),
                  onClarify: () => _showClarifyDialog(purchase),
                  onToggleSelect: () => _toggleSelect(purchase),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectionToggle(PurchaseLoaded state) {
    final pendingCount =
        state.purchases.where((p) => p.status.isActionable).length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('${state.purchases.length} item', style: AppTypography.h6),
        if (pendingCount > 0)
          TextButton.icon(
            onPressed: () {
              setState(() {
                _isSelectionMode = !_isSelectionMode;
                if (!_isSelectionMode) _selectedIds.clear();
              });
            },
            icon: Icon(
              _isSelectionMode
                  ? Icons.close
                  : Icons.checklist,
              size: AppSizing.iconSm,
            ),
            label: Text(
              _isSelectionMode ? 'Batal' : 'Pilih Item',
              style: AppTypography.buttonSmall.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Column(
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: AppSizing.iconXxl,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Belum ada pembelian',
              style: AppTypography.h6.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Pembelian material dari tukang akan muncul di sini',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _approvePurchase(Purchase purchase) {
    if (!purchase.status.isActionable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aksi tidak diizinkan untuk status pembelian saat ini'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    context.read<PurchaseBloc>().add(
          ApprovePurchase(
            orderId: widget.orderId,
            purchaseId: purchase.id,
          ),
        );
  }

  void _showRejectDialog(Purchase purchase) {
    if (!purchase.status.isActionable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aksi tidak diizinkan untuk status pembelian saat ini'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tolak Pembelian'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Item: ${purchase.itemName}',
              style: AppTypography.label,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Alasan penolakan *',
                hintText: 'Jelaskan alasan penolakan...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 1000,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              final reason = controller.text.trim();
              if (reason.isNotEmpty) {
                context.read<PurchaseBloc>().add(
                      RejectPurchase(
                        orderId: widget.orderId,
                        purchaseId: purchase.id,
                        reason: reason,
                      ),
                    );
                Navigator.pop(dialogContext);
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
  }

  void _showClarifyDialog(Purchase purchase) {
    if (!purchase.status.isActionable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aksi tidak diizinkan untuk status pembelian saat ini'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Minta Klarifikasi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Item: ${purchase.itemName}',
              style: AppTypography.label,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Pertanyaan klarifikasi *',
                hintText: 'Tanyakan detail tentang pembelian ini...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 1000,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              final question = controller.text.trim();
              if (question.isNotEmpty) {
                context.read<PurchaseBloc>().add(
                      RequestClarification(
                        orderId: widget.orderId,
                        purchaseId: purchase.id,
                        question: question,
                      ),
                    );
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
  }

  void _toggleSelect(Purchase purchase) {
    if (!purchase.status.isActionable) return;
    setState(() {
      if (_selectedIds.contains(purchase.id)) {
        _selectedIds.remove(purchase.id);
      } else {
        _selectedIds.add(purchase.id);
      }
    });
  }

  void _bulkApprove() {
    if (_selectedIds.isEmpty) return;
    context.read<PurchaseBloc>().add(
          BulkApprove(
            orderId: widget.orderId,
            purchaseIds: _selectedIds.toList(),
          ),
        );
    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });
  }
}

/// Card displaying a single purchase item with details and action buttons.
class _PurchaseItemCard extends StatelessWidget {
  const _PurchaseItemCard({
    required this.purchase,
    required this.isLoading,
    required this.isSelected,
    required this.isSelectionMode,
    this.onApprove,
    this.onReject,
    this.onClarify,
    this.onToggleSelect,
  });

  final Purchase purchase;
  final bool isLoading;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onClarify;
  final VoidCallback? onToggleSelect;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'id');

    return AppCard(
      onTap: isSelectionMode ? onToggleSelect : null,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: item name + status
              Row(
                children: [
                  if (isSelectionMode && purchase.status.isActionable)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: Icon(
                        isSelected
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textDisabled,
                        size: AppSizing.iconMd,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      purchase.itemName,
                      style: AppTypography.h6,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _PurchaseStatusBadge(status: purchase.status),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Category
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppSizing.radiusXs),
                ),
                child: Text(
                  purchase.category.label,
                  style: AppTypography.caption,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Quantity and price
              Row(
                children: [
                  Expanded(
                    child: _buildDetail(
                      'Jumlah',
                      '${purchase.quantity} ${purchase.unit}',
                    ),
                  ),
                  Expanded(
                    child: _buildDetail(
                      'Harga Satuan',
                      'Rp${formatter.format(purchase.unitPrice)}',
                    ),
                  ),
                  Expanded(
                    child: _buildDetail(
                      'Total',
                      'Rp${formatter.format(purchase.totalPrice)}',
                      isBold: true,
                    ),
                  ),
                ],
              ),

              // Reason
              if (purchase.reason != null && purchase.reason!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Alasan: ${purchase.reason}',
                  style: AppTypography.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // AI Confidence
              if (purchase.confidence != null) ...[
                const SizedBox(height: AppSpacing.sm),
                _buildConfidenceBar(purchase.confidence!),
              ],

              // Risk flags
              if (purchase.riskFlags.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                ...purchase.riskFlags.map(
                  (flag) => _buildRiskFlag(flag),
                ),
              ],

              // Clarification Q&A
              if (purchase.needsClarification &&
                  purchase.clarificationQuestion != null) ...[
                const SizedBox(height: AppSpacing.sm),
                _buildClarification(purchase),
              ],

              // Receipt photo link
              if (purchase.receiptPhotoUrl != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(
                      Icons.receipt_outlined,
                      size: AppSizing.iconSm,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Nota tersedia',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],

              // Action buttons
              if (purchase.status.isActionable && !isSelectionMode) ...[
                const SizedBox(height: AppSpacing.md),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.sm),
                _buildActionButtons(),
              ],
            ],
          ),

          // Loading overlay for individual item
          if (isLoading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                ),
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetail(String label, String value, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption),
        const SizedBox(height: 2),
        Text(
          value,
          style: isBold ? AppTypography.priceSmall : AppTypography.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildConfidenceBar(double confidence) {
    final color = confidence >= 0.8
        ? AppColors.success
        : confidence >= 0.5
            ? AppColors.warning
            : AppColors.error;

    return Row(
      children: [
        Text('AI Confidence: ', style: AppTypography.caption),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizing.radiusXs),
            child: LinearProgressIndicator(
              value: confidence,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          confidence.toStringAsFixed(2),
          style: AppTypography.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRiskFlag(RiskFlag flag) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber,
            size: AppSizing.iconSm,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              flag.message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClarification(Purchase purchase) {
    return Container(
      padding: AppSpacing.cardPaddingSmall,
      decoration: BoxDecoration(
        color: AppColors.infoLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppSizing.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline,
                size: AppSizing.iconSm,
                color: AppColors.info,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Klarifikasi',
                style: AppTypography.label.copyWith(color: AppColors.info),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Q: ${purchase.clarificationQuestion}',
            style: AppTypography.bodySmall,
          ),
          if (purchase.clarificationResponse != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'A: ${purchase.clarificationResponse}',
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onApprove,
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Setujui'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.success,
              side: const BorderSide(color: AppColors.success),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onReject,
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Tolak'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton(
          onPressed: onClarify,
          icon: const Icon(Icons.help_outline),
          color: AppColors.info,
          tooltip: 'Minta Klarifikasi',
        ),
      ],
    );
  }
}

/// Badge showing the purchase status with appropriate color.
class _PurchaseStatusBadge extends StatelessWidget {
  const _PurchaseStatusBadge({required this.status});

  final PurchaseStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _getColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizing.radiusFull),
      ),
      child: Text(
        _getLabel(),
        style: AppTypography.caption.copyWith(
          color: _getColor(),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getColor() {
    switch (status) {
      case PurchaseStatus.draft:
        return AppColors.textSecondary;
      case PurchaseStatus.pendingApproval:
        return AppColors.warning;
      case PurchaseStatus.approved:
        return AppColors.success;
      case PurchaseStatus.rejected:
        return AppColors.error;
      case PurchaseStatus.needsClarification:
        return AppColors.info;
    }
  }

  String _getLabel() {
    switch (status) {
      case PurchaseStatus.draft:
        return 'Draft';
      case PurchaseStatus.pendingApproval:
        return 'Menunggu';
      case PurchaseStatus.approved:
        return 'Disetujui';
      case PurchaseStatus.rejected:
        return 'Ditolak';
      case PurchaseStatus.needsClarification:
        return 'Perlu Klarifikasi';
    }
  }
}
