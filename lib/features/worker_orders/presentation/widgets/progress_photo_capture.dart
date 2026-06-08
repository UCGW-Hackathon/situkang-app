import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';

class ProgressPhotoCapture extends StatefulWidget {
  const ProgressPhotoCapture({
    required this.onPhotoCaptured, super.key,
  });

  final void Function(String filePath, String? caption) onPhotoCaptured;

  @override
  State<ProgressPhotoCapture> createState() => _ProgressPhotoCaptureState();
}

class _ProgressPhotoCaptureState extends State<ProgressPhotoCapture> {
  String? _mockFilePath;
  final _captionController = TextEditingController();

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  void _simulateCapture() {
    // Simulate picking a file
    setState(() {
      _mockFilePath = '/path/to/simulated/photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    });
  }

  void _submit() {
    if (_mockFilePath != null) {
      widget.onPhotoCaptured(_mockFilePath!, _captionController.text.trim());
      Navigator.of(context).pop();
    }
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
              const Text('Unggah Bukti Progres', style: AppTypography.h6),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          
          if (_mockFilePath == null)
            GestureDetector(
              onTap: _simulateCapture,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, size: 48, color: AppColors.primary),
                    SizedBox(height: AppSpacing.sm),
                    Text('Ambil Foto Progres', style: AppTypography.bodyMedium),
                  ],
                ),
              ),
            )
          else
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(AppSizing.radiusMd),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, size: 48, color: AppColors.primary),
                        const SizedBox(height: AppSpacing.sm),
                        Text('Foto Tersimpan', style: AppTypography.bodyMedium.copyWith(color: AppColors.primary)),
                      ],
                    ),
                  ),
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: IconButton(
                      icon: const Icon(Icons.refresh, color: AppColors.primary),
                      onPressed: _simulateCapture,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _captionController,
            label: 'Keterangan (Opsional)',
            hint: 'Contoh: Sudah selesai pemasangan pipa',
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            text: 'Unggah',
            onPressed: _mockFilePath != null ? _submit : null,
          ),
        ],
      ),
    );
  }
}
