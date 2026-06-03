import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/image_picker_widget.dart';

/// Widget for uploading and displaying the user's avatar.
///
/// Uses [ImagePickerWidget] with a 5MB file size limit and JPG/PNG validation.
/// Displays the current avatar (from URL) or a selected file preview.
class AvatarUploadWidget extends StatelessWidget {
  const AvatarUploadWidget({
    required this.onImageSelected,
    super.key,
    this.currentAvatarUrl,
    this.selectedFile,
    this.onError,
    this.isUploading = false,
  });

  /// The current avatar URL from the server, if available.
  final String? currentAvatarUrl;

  /// The locally selected file awaiting upload.
  final File? selectedFile;

  /// Callback when a valid image is selected.
  final ValueChanged<File> onImageSelected;

  /// Callback when a validation error occurs.
  final ValueChanged<String>? onError;

  /// Whether an upload is currently in progress.
  final bool isUploading;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Show selected file, current avatar URL, or placeholder
            if (selectedFile != null)
              _buildFilePreview()
            else if (currentAvatarUrl != null)
              _buildNetworkAvatar()
            else
              _buildPlaceholder(),
            // Upload progress overlay
            if (isUploading)
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.4),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Image picker trigger
        ImagePickerWidget(
          imageFile: selectedFile,
          onImageSelected: onImageSelected,
          onError: onError,
          label: 'Ubah Foto Profil',
          previewSize: 0, // We handle preview ourselves above
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Maks. 5MB, format JPG/PNG',
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFilePreview() {
    return CircleAvatar(
      radius: 60,
      backgroundColor: AppColors.surfaceVariant,
      backgroundImage: FileImage(selectedFile!),
    );
  }

  Widget _buildNetworkAvatar() {
    return CircleAvatar(
      radius: 60,
      backgroundColor: AppColors.surfaceVariant,
      backgroundImage: CachedNetworkImageProvider(currentAvatarUrl!),
    );
  }

  Widget _buildPlaceholder() {
    return const CircleAvatar(
      radius: 60,
      backgroundColor: AppColors.surfaceVariant,
      child: Icon(
        Icons.person,
        size: 60,
        color: AppColors.textSecondary,
      ),
    );
  }
}
