import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../bloc/worker_purchase_bloc.dart';
import 'ai_assist_page.dart';
import 'receipt_scan_page.dart';

class AddPurchasePage extends StatefulWidget {
  const AddPurchasePage({
    super.key,
    required this.orderId,
  });

  final String orderId;

  @override
  State<AddPurchasePage> createState() => _AddPurchasePageState();
}

class _AddPurchasePageState extends State<AddPurchasePage> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController(text: 'pcs');
  final _unitPriceController = TextEditingController();
  final _reasonController = TextEditingController();

  String _selectedCategory = 'Material Dasar';
  final List<String> _categories = [
    'Material Dasar',
    'Material Finishing',
    'Peralatan',
    'Lainnya',
  ];

  File? _receiptPhoto;

  @override
  void dispose() {
    _itemNameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _unitPriceController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _receiptPhoto = File(pickedFile.path);
      });
    }
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final quantity = int.tryParse(_quantityController.text) ?? 1;
      final unitPriceText = _unitPriceController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final unitPrice = int.tryParse(unitPriceText) ?? 0;
      final totalPrice = quantity * unitPrice;

      context.read<WorkerPurchaseBloc>().add(
        AddManualPurchase(
          orderId: widget.orderId,
          itemName: _itemNameController.text.trim(),
          category: _selectedCategory,
          quantity: quantity,
          unit: _unitController.text.trim(),
          unitPrice: unitPrice,
          totalPrice: totalPrice,
          reason: _reasonController.text.trim().isNotEmpty ? _reasonController.text.trim() : null,
          receiptPhotoPath: _receiptPhoto?.path,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Pembelian'),
      ),
      body: BlocConsumer<WorkerPurchaseBloc, WorkerPurchaseState>(
        listener: (context, state) {
          if (state is WorkerPurchaseError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.failure.message),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state is WorkerPurchaseSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pembelian berhasil ditambahkan ke draf.'),
                backgroundColor: AppColors.success,
              ),
            );
            context.pop();
          }
        },
        builder: (context, state) {
          final isLoading = state is WorkerPurchaseLoading;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: AppSpacing.pagePadding,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSmartTools(context),
                      const SizedBox(height: AppSpacing.xl),
                      
                      const Divider(),
                      const SizedBox(height: AppSpacing.lg),
                      
                      Text('Input Manual', style: AppTypography.h6),
                      const SizedBox(height: AppSpacing.md),
                      
                      AppTextField(
                        controller: _itemNameController,
                        label: 'Nama Barang',
                        hint: 'Contoh: Semen Gresik 40kg',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama barang tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                          border: OutlineInputBorder(),
                        ),
                        items: _categories.map((cat) {
                          return DropdownMenuItem(value: cat, child: Text(cat));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCategory = val);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: AppTextField(
                              controller: _quantityController,
                              label: 'Jumlah',
                              hint: '1',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || int.tryParse(value) == null) {
                                  return 'Angka valid';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            flex: 3,
                            child: AppTextField(
                              controller: _unitController,
                              label: 'Satuan',
                              hint: 'sak, pcs, liter',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      
                      AppTextField(
                        controller: _unitPriceController,
                        label: 'Harga Satuan (Rp)',
                        hint: '50000',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Harga satuan wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      
                      AppTextField(
                        controller: _reasonController,
                        label: 'Alasan Pembelian (Opsional)',
                        hint: 'Mengapa butuh barang ini?',
                        maxLines: 2,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      
                      Text('Foto Nota / Struk', style: AppTypography.label),
                      const SizedBox(height: AppSpacing.sm),
                      
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                            border: Border.all(color: AppColors.border),
                            image: _receiptPhoto != null
                                ? DecorationImage(
                                    image: FileImage(_receiptPhoto!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _receiptPhoto == null
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.camera_alt, color: AppColors.primary, size: 32),
                                    SizedBox(height: AppSpacing.xs),
                                    Text('Ambil Foto Nota', style: AppTypography.caption),
                                  ],
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      
                      AppButton(
                        text: 'Simpan ke Draf',
                        onPressed: _submit,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
              if (isLoading)
                Container(
                  color: Colors.black12,
                  child: const Center(child: LoadingIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSmartTools(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Alat Pintar', style: AppTypography.h6),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: AppCard(
                color: AppColors.primaryContainer.withValues(alpha: 0.5),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AiAssistPage(orderId: widget.orderId),
                    ),
                  );
                },
                child: Column(
                  children: [
                    const Icon(Icons.auto_awesome, color: AppColors.primary),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Bantu Rapikan\ndengan AI',
                      style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppCard(
                color: AppColors.accent.withValues(alpha: 0.1),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReceiptScanPage(orderId: widget.orderId),
                    ),
                  );
                },
                child: Column(
                  children: [
                    const Icon(Icons.document_scanner, color: AppColors.accent),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Scan Nota\nOtomatis',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
