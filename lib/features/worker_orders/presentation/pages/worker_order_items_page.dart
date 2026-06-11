import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/theme.dart';
import '../../../invoice/domain/entities/invoice.dart';
import '../../../purchases/domain/entities/purchase.dart';
import '../../../purchases/domain/repositories/worker_purchase_repository.dart';
import '../../domain/entities/worker_order_detail.dart';

class WorkerOrderItemsPage extends StatefulWidget {
  const WorkerOrderItemsPage({required this.orderId, this.detail, super.key});

  final String orderId;
  final WorkerOrderDetail? detail;

  @override
  State<WorkerOrderItemsPage> createState() => _WorkerOrderItemsPageState();
}

class _WorkerOrderItemsPageState extends State<WorkerOrderItemsPage> {
  static const _brandTeal = Color(0xFF00647C);
  static const _gojekGreen = Color(0xFF00AA13);
  static const _screenBackground = Color(0xFFF7F8FE);
  static const _baseServiceFee = 150000;

  final _formatter = NumberFormat('#,###', 'id');
  final _purchaseRepository = getIt<WorkerPurchaseRepository>();
  final List<Purchase> _items = [];

  bool _isSaving = false;
  bool _isCreatingInvoice = false;

  int get _materialsTotal =>
      _items.fold(0, (total, item) => total + item.totalPrice);

  int get _grandTotal => _baseServiceFee + _materialsTotal;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _screenBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset + 144),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildJobCard(),
                    const SizedBox(height: 22),
                    _buildMaterialHeader(),
                    const SizedBox(height: 12),
                    if (_items.isEmpty)
                      _buildEmptyMaterials()
                    else
                      ..._items.map(_buildMaterialItem),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final title = widget.detail?.title ?? 'Detail Pekerjaan';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          _CircleIconButton(icon: Icons.arrow_back, onTap: () => context.pop()),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: AppTypography.label.copyWith(
                color: _brandTeal,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _gojekGreen,
              borderRadius: BorderRadius.circular(AppSizing.radiusFull),
            ),
            child: Text(
              'Sedang Diproses',
              style: AppTypography.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard() {
    final detail = widget.detail;
    final address = detail?.location.address.trim();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E6EC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DETAIL PEKERJAAN',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              detail?.title ?? 'Pekerjaan',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    address == null || address.isEmpty
                        ? 'Lokasi pelanggan'
                        : address,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Text(
                  'Waktu Mulai:',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('hh:mm a').format(DateTime.now()),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Biaya Material',
            style: AppTypography.h5.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        FilledButton.icon(
          onPressed: _isSaving ? null : _showAddItemSheet,
          style: FilledButton.styleFrom(
            backgroundColor: _brandTeal,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizing.radiusFull),
            ),
          ),
          icon: _isSaving
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.add, size: 16),
          label: const Text('Tambah'),
        ),
      ],
    );
  }

  Widget _buildEmptyMaterials() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E6EC)),
      ),
      child: Text(
        'Belum ada material. Tambahkan item sebelum membuat tagihan.',
        textAlign: TextAlign.center,
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildMaterialItem(Purchase item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE9F2FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.build, color: _brandTeal, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName,
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${_formatQuantity(item.quantity)} ${item.unit} x Rp ${_formatter.format(item.unitPrice)}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Rp ${_formatter.format(item.totalPrice)}',
            style: AppTypography.label.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          IconButton(
            tooltip: 'Hapus material',
            onPressed: () => _deleteItem(item),
            icon: const Icon(Icons.delete, color: AppColors.error, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return DecoratedBox(
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
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding + 14),
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
                          'Estimasi Total Biaya',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Rp ${_formatter.format(_grandTotal)}',
                          style: AppTypography.h4.copyWith(
                            color: _brandTeal,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Jasa: Rp ${_formatter.format(_baseServiceFee)}\nMaterial: Rp ${_formatter.format(_materialsTotal)}',
                    textAlign: TextAlign.right,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SlideActionButton(
                text: _isCreatingInvoice
                    ? 'MEMBUAT TAGIHAN...'
                    : 'GESER UNTUK MEMBUAT TAGIHAN',
                enabled: !_isCreatingInvoice,
                onCompleted: _createInvoice,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddItemSheet() async {
    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final unitController = TextEditingController(text: 'pcs');
    final priceController = TextEditingController();
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showModalBottomSheet<_PurchaseInput>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        final keyboard = MediaQuery.viewInsetsOf(context).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 18, 16, keyboard + 18),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Tambah Material',
                  style: AppTypography.h4.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Nama barang'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Nama barang wajib diisi'
                      : null,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Jumlah'),
                        validator: (value) {
                          final quantity = int.tryParse(value ?? '');
                          if (quantity == null || quantity <= 0) {
                            return 'Tidak valid';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: unitController,
                        decoration: const InputDecoration(labelText: 'Satuan'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Wajib'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Harga satuan'),
                  validator: (value) {
                    final price = int.tryParse(value ?? '');
                    if (price == null || price <= 0) return 'Harga tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: reasonController,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Catatan kebutuhan',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    final quantity = int.parse(quantityController.text);
                    final unitPrice = int.parse(priceController.text);
                    Navigator.of(context).pop(
                      _PurchaseInput(
                        itemName: nameController.text.trim(),
                        quantity: quantity,
                        unit: unitController.text.trim(),
                        unitPrice: unitPrice,
                        totalPrice: quantity * unitPrice,
                        reason: reasonController.text.trim(),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _brandTeal,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Simpan Material'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result == null) return;
    await _addItem(result);
  }

  Future<void> _addItem(_PurchaseInput input) async {
    setState(() => _isSaving = true);

    final result = await _purchaseRepository.addPurchase(
      orderId: widget.orderId,
      itemName: input.itemName,
      category: 'material',
      quantity: input.quantity,
      unit: input.unit,
      unitPrice: input.unitPrice,
      totalPrice: input.totalPrice,
      reason: input.reason.isEmpty ? null : input.reason,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    result.fold(
      (failure) => _showError(failure.message),
      (purchase) => setState(() => _items.add(purchase)),
    );
  }

  Future<void> _deleteItem(Purchase item) async {
    if (item.id.isEmpty) {
      setState(() => _items.remove(item));
      return;
    }

    final result = await _purchaseRepository.deleteDraft(
      orderId: widget.orderId,
      purchaseId: item.id,
    );

    if (!mounted) return;
    result.fold(
      (failure) => _showError(failure.message),
      (_) => setState(() => _items.remove(item)),
    );
  }

  Future<void> _createInvoice() async {
    if (_isCreatingInvoice) return;
    setState(() => _isCreatingInvoice = true);

    final now = DateTime.now();
    final invoice = Invoice(
      id: 'local-${now.microsecondsSinceEpoch}',
      orderId: widget.orderId,
      invoiceNumber: 'LOCAL-${now.millisecondsSinceEpoch}',
      baseServiceFee: _baseServiceFee,
      bookingFee: 0,
      platformFee: 0,
      materialsTotal: _materialsTotal,
      additionalCostTotal: 0,
      discount: 0,
      grandTotal: _grandTotal,
      status: PaymentStatus.pending,
      paymentMethod: PaymentMethod.cash,
      items: _items
          .map(
            (item) => InvoiceLineItem(
              id: item.id,
              name: item.itemName,
              quantity: item.quantity,
              unitPrice: item.unitPrice,
              totalPrice: item.totalPrice,
              type: item.category.value,
            ),
          )
          .toList(),
      createdAt: now,
      dueDate: now,
    );

    if (!mounted) return;
    setState(() => _isCreatingInvoice = false);

    await context.push(
      '/worker/orders/${widget.orderId}/invoice',
      extra: invoice,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  String _formatQuantity(double quantity) {
    if (quantity == quantity.roundToDouble()) {
      return quantity.round().toString();
    }
    return quantity.toStringAsFixed(1);
  }
}

class _PurchaseInput {
  const _PurchaseInput({
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.totalPrice,
    required this.reason,
  });

  final String itemName;
  final int quantity;
  final String unit;
  final int unitPrice;
  final int totalPrice;
  final String reason;
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
  const _SlideActionButton({
    required this.text,
    required this.onCompleted,
    this.enabled = true,
  });

  final String text;
  final bool enabled;
  final VoidCallback onCompleted;

  @override
  State<_SlideActionButton> createState() => _SlideActionButtonState();
}

class _SlideActionButtonState extends State<_SlideActionButton> {
  static const _gojekGreen = Color(0xFF00AA13);
  double _progress = 0;
  bool _completed = false;

  @override
  void didUpdateWidget(covariant _SlideActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.enabled != widget.enabled) {
      _completed = false;
      _progress = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const knobSize = 48.0;
        final maxTravel = constraints.maxWidth - knobSize;
        final knobLeft = maxTravel * _progress;

        return GestureDetector(
          onHorizontalDragUpdate: !widget.enabled || _completed
              ? null
              : (details) {
                  setState(() {
                    _progress = (_progress + details.delta.dx / maxTravel)
                        .clamp(0.0, 1.0);
                  });
                },
          onHorizontalDragEnd: !widget.enabled || _completed
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
                    color: widget.enabled
                        ? const Color(0xFFCFE0FF)
                        : AppColors.surfaceVariant,
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
                        color: const Color(0xFF00647C),
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
                      color: widget.enabled
                          ? const Color(0xFF00647C)
                          : AppColors.textSecondary,
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
