import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../bloc/worker_purchase_bloc.dart';

class ReceiptScanPage extends StatefulWidget {
  const ReceiptScanPage({
    super.key,
    required this.orderId,
  });

  final String orderId;

  @override
  State<ReceiptScanPage> createState() => _ReceiptScanPageState();
}

class _ReceiptScanPageState extends State<ReceiptScanPage> {
  File? _receiptPhoto;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _receiptPhoto = File(pickedFile.path);
      });
    }
  }

  void _scanReceipt() {
    if (_receiptPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan ambil atau pilih foto nota terlebih dahulu')),
      );
      return;
    }

    context.read<WorkerPurchaseBloc>().add(
      ScanReceiptPurchase(
        orderId: widget.orderId,
        photoPath: _receiptPhoto!.path,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Nota Otomatis'),
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
          } else if (state is WorkerPurchaseBatchSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Berhasil memproses ${state.purchases.length} item dari nota.'),
                backgroundColor: AppColors.success,
              ),
            );
            context.pop(); // Go back to draft list
          }
        },
        builder: (context, state) {
          final isProcessing = state is WorkerPurchaseOcrProcessing;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: AppSpacing.pagePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.document_scanner, color: AppColors.accent),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              'Foto nota belanjamu, dan AI akan otomatis membaca nama barang serta harganya.',
                              style: AppTypography.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    if (_receiptPhoto != null)
                      Container(
                        height: 300,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                          border: Border.all(color: AppColors.border),
                          image: DecorationImage(
                            image: FileImage(_receiptPhoto!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    else
                      Container(
                        height: 300,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                          border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.receipt_long, size: 64, color: AppColors.textSecondary),
                            const SizedBox(height: AppSpacing.md),
                            Text('Belum ada foto', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: AppSpacing.xl),

                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            text: 'Kamera',
                            icon: Icons.camera_alt,
                            variant: AppButtonVariant.outline,
                            onPressed: isProcessing ? null : () => _pickImage(ImageSource.camera),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: AppButton(
                            text: 'Galeri',
                            icon: Icons.photo_library,
                            variant: AppButtonVariant.outline,
                            onPressed: isProcessing ? null : () => _pickImage(ImageSource.gallery),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(
                      text: 'Proses Nota',
                      icon: Icons.document_scanner,
                      onPressed: isProcessing ? null : _scanReceipt,
                    ),
                  ],
                ),
              ),
              if (isProcessing)
                Container(
                  color: Colors.black12,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const LoadingIndicator(),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Membaca teks dari nota...',
                          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
