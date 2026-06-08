import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/app_constants.dart';
import '../theme/theme.dart';
import '../utils/validators.dart';

/// A widget that provides image picking from gallery or camera with preview
/// and file validation.
///
/// Validates selected files using [FileUploadValidator] for format and size.
class ImagePickerWidget extends StatefulWidget {
  /// Creates an [ImagePickerWidget].
  const ImagePickerWidget({
    super.key,
    this.imageFile,
    this.onImageSelected,
    this.onError,
    this.maxFileSize = AppConstants.maxAvatarFileSize,
    this.label,
    this.previewSize = 120.0,
  });

  /// The currently selected image file.
  final File? imageFile;

  /// Callback when an image is successfully selected and validated.
  final ValueChanged<File>? onImageSelected;

  /// Callback when a validation error occurs.
  final ValueChanged<String>? onError;

  /// Maximum file size in bytes. Defaults to 5MB.
  final int maxFileSize;

  /// Optional label displayed above the picker.
  final String? label;

  /// Size of the image preview.
  final double previewSize;

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final ImagePicker _picker = ImagePicker();
  String? _errorMessage;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile == null) return;

      final file = File(pickedFile.path);
      final fileSize = await file.length();
      final fileName = pickedFile.name;

      final validationError = FileUploadValidator.validate(
        fileName,
        fileSize,
        maxSize: widget.maxFileSize,
      );

      if (validationError != null) {
        setState(() {
          _errorMessage = validationError;
        });
        widget.onError?.call(validationError);
        return;
      }

      setState(() {
        _errorMessage = null;
      });
      widget.onImageSelected?.call(file);
    } on Exception catch (e) {
      final errorMsg = 'Gagal memilih gambar: $e';
      setState(() {
        _errorMessage = errorMsg;
      });
      widget.onError?.call(errorMsg);
    }
  }

  void _showPickerOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ambil Foto'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: AppTypography.label),
          const SizedBox(height: AppSpacing.sm),
        ],
        GestureDetector(
          onTap: _showPickerOptions,
          child: widget.imageFile != null
              ? _buildPreview()
              : _buildPlaceholder(),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            _errorMessage!,
            style: AppTypography.caption.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }

  Widget _buildPreview() {
    return Stack(
      children: [
        ClipRoundedRect(
          borderRadius: BorderRadius.circular(AppSizing.radiusSm),
          child: Image.file(
            widget.imageFile!,
            width: widget.previewSize,
            height: widget.previewSize,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(4),
            child: const Icon(
              Icons.edit,
              size: AppSizing.iconXs,
              color: AppColors.onPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: widget.previewSize,
      height: widget.previewSize,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSizing.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_a_photo_outlined,
            size: AppSizing.iconLg,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            'Pilih Foto',
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }
}

/// Helper widget for clipping with rounded corners.
class ClipRoundedRect extends StatelessWidget {
  const ClipRoundedRect({
    required this.borderRadius, required this.child, super.key,
  });

  final BorderRadius borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: child,
    );
  }
}
