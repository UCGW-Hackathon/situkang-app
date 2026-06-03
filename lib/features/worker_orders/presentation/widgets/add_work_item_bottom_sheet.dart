import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';

class AddWorkItemBottomSheet extends StatefulWidget {
  const AddWorkItemBottomSheet({
    super.key,
    required this.onAdd,
  });

  final void Function(String name, int cost, String? description) onAdd;

  @override
  State<AddWorkItemBottomSheet> createState() => _AddWorkItemBottomSheetState();
}

class _AddWorkItemBottomSheetState extends State<AddWorkItemBottomSheet> {
  final _nameController = TextEditingController();
  final _costController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final costText = _costController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final cost = int.tryParse(costText) ?? 0;
    final desc = _descController.text.trim();

    if (name.isEmpty || cost <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama barang dan biaya harus diisi dengan benar'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    widget.onAdd(name, cost, desc.isNotEmpty ? desc : null);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.pagePadding.left,
        right: AppSpacing.pagePadding.right,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tambah Material / Jasa', style: AppTypography.h6),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _nameController,
            label: 'Nama Barang / Jasa Tambahan',
            hint: 'Contoh: Semen 1 sak',
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _costController,
            label: 'Biaya (Rp)',
            hint: 'Contoh: 50000',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _descController,
            label: 'Keterangan (Opsional)',
            hint: 'Contoh: Dibeli di toko bangunan terdekat',
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            text: 'Tambah',
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
