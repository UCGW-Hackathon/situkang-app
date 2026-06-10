import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../orders/domain/entities/order.dart';
import '../bloc/worker_order_bloc.dart';

class WorkerActiveOrderPage extends StatefulWidget {
  const WorkerActiveOrderPage({required this.order, super.key});

  final Order order;

  @override
  State<WorkerActiveOrderPage> createState() => _WorkerActiveOrderPageState();
}

class _WorkerActiveOrderPageState extends State<WorkerActiveOrderPage> {
  late String _currentStatus;
  bool _isSharingLocation = false;
  final _workerNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order.status.value;
    _updateLocationSharingState();
  }

  @override
  void dispose() {
    _workerNotesController.dispose();
    super.dispose();
  }

  void _updateLocationSharingState() {
    // Requirements: Location sharing is active during on_the_way and arrived.
    // In a real app, we would call the LocationSharingService here.
    setState(() {
      _isSharingLocation =
          _currentStatus == 'on_the_way' || _currentStatus == 'arrived';
    });
  }

  void _handleStatusChange(String newStatus) {
    context.read<WorkerOrderBloc>().add(
      UpdateOrderStatus(
        orderId: widget.order.id,
        status: newStatus,
        currentStatus: _currentStatus,
      ),
    );
  }

  void _showAddWorkItem() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return const SizedBox.shrink();
      },
    );
  }

  void _showUploadPhoto() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return const SizedBox.shrink();
      },
    );
  }

  void _showCompleteDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Selesaikan Pesanan?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pastikan semua pekerjaan telah selesai dan tagihan telah dimasukkan.',
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _workerNotesController,
                label: 'Catatan untuk Pelanggan (Opsional)',
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<WorkerOrderBloc>().add(
                  CompleteOrder(
                    orderId: widget.order.id,
                    workerNotes: _workerNotesController.text.trim().isNotEmpty
                        ? _workerNotesController.text.trim()
                        : null,
                  ),
                );
              },
              child: const Text('Selesaikan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pesanan Berlangsung')),
      body: BlocConsumer<WorkerOrderBloc, WorkerOrderState>(
        listener: (context, state) {
          if (state is WorkerOrderError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.failure.message),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state is WorkerOrderStatusUpdated) {
            setState(() {
              _currentStatus = state.newStatus;
            });
            _updateLocationSharingState();
          } else if (state is WorkerOrderItemAdded) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Item berhasil ditambahkan ke tagihan.'),
              ),
            );
          } else if (state is WorkerOrderPhotoUploaded) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Foto progres berhasil diunggah.')),
            );
          } else if (state is WorkerOrderCompleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pesanan Selesai! Menunggu pembayaran.'),
                backgroundColor: AppColors.success,
              ),
            );
            context.pop();
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Membuka tagihan...')));
          }
        },
        builder: (context, state) {
          final isLoading = state is WorkerOrderLoading;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: AppSpacing.pagePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildOrderInfo(),
                    const SizedBox(height: AppSpacing.xl),

                    if (_isSharingLocation) _buildLocationSharingIndicator(),

                    const SizedBox(height: AppSpacing.md),
                    const Text('Status Pekerjaan', style: AppTypography.h6),
                    const SizedBox(height: AppSpacing.md),

                    _buildStatusTracker(),
                    const SizedBox(height: AppSpacing.xl),

                    const Text('Aksi', style: AppTypography.h6),
                    const SizedBox(height: AppSpacing.md),

                    if (_currentStatus == 'in_progress') ...[
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              text: 'Upload Foto',
                              icon: Icons.camera_alt,
                              variant: AppButtonVariant.outline,
                              onPressed: _showUploadPhoto,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: AppButton(
                              text: 'Tambah Tagihan',
                              icon: Icons.add_shopping_cart,
                              variant: AppButtonVariant.outline,
                              onPressed: _showAddWorkItem,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],

                    _buildPrimaryActionButton(),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
              if (isLoading)
                const ColoredBox(
                  color: Colors.black12,
                  child: Center(child: LoadingIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrderInfo() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.build, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(widget.order.title, style: AppTypography.h6),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Row(
            children: [
              Icon(Icons.person, color: AppColors.textSecondary, size: 20),
              SizedBox(width: AppSpacing.sm),
              Text('Pelanggan', style: AppTypography.bodyMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Row(
            children: [
              Icon(Icons.location_on, color: AppColors.error, size: 20),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Lokasi Pelanggan',
                  style: AppTypography.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.phone, color: AppColors.success, size: 20),
              const SizedBox(width: AppSpacing.sm),
              const Text('08123456789', style: AppTypography.bodyMedium),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.chat),
                color: AppColors.primary,
                onPressed: () {
                  context.push(
                    '/worker/chat/${widget.order.id}',
                    extra: 'Pelanggan',
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSharingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        border: Border.all(color: AppColors.success),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: AppColors.success),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Berbagi Lokasi Langsung Aktif',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ),
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTracker() {
    final steps = [
      {'key': 'on_the_way', 'label': 'Menuju Lokasi'},
      {'key': 'arrived', 'label': 'Tiba di Lokasi'},
      {'key': 'in_progress', 'label': 'Sedang Dikerjakan'},
      {'key': 'completed', 'label': 'Selesai'},
    ];

    var currentIndex = steps.indexWhere((s) => s['key'] == _currentStatus);
    if (currentIndex == -1) currentIndex = 0; // Default if not found

    return Column(
      children: List.generate(steps.length, (index) {
        final isActive = index <= currentIndex;
        final isLast = index == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                        ? AppColors.primary
                        : AppColors.surfaceVariant,
                  ),
                  child: isActive
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: AppColors.onPrimary,
                        )
                      : null,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 30,
                    color: isActive
                        ? AppColors.primary
                        : AppColors.surfaceVariant,
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(
                  bottom: 24,
                ), // Match height + padding
                child: Text(
                  steps[index]['label']!,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildPrimaryActionButton() {
    switch (_currentStatus) {
      case 'on_the_way':
        return AppButton(
          text: 'Tiba di Lokasi',
          onPressed: () => _handleStatusChange('arrived'),
        );
      case 'arrived':
        return AppButton(
          text: 'Mulai Dikerjakan',
          onPressed: () => _handleStatusChange('in_progress'),
        );
      case 'in_progress':
        return AppButton(
          text: 'Selesaikan Pesanan',
          onPressed: _showCompleteDialog,
        );
      case 'completed':
        return const SizedBox.shrink();
      default:
        return AppButton(
          text: 'Menuju Lokasi',
          onPressed: () => _handleStatusChange('on_the_way'),
        );
    }
  }
}
