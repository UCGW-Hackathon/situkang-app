import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../bloc/worker_profile_bloc.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  File? _ktpPhoto;
  File? _selfiePhoto;
  final List<File> _certificatePhotos = [];

  Future<void> _pickImage(
    ImageSource source,
    void Function(File) onPicked,
  ) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File cannot exceed 5MB')),
          );
        }
        return;
      }
      final pathLowerCase = pickedFile.path.toLowerCase();
      if (!pathLowerCase.endsWith('.jpg') &&
          !pathLowerCase.endsWith('.png') &&
          !pathLowerCase.endsWith('.jpeg')) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Only JPG/PNG allowed')));
        }
        return;
      }
      onPicked(File(pickedFile.path));
    }
  }

  void _submit() {
    if (_ktpPhoto == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Foto KTP wajib diunggah')));
      return;
    }

    context.read<WorkerProfileBloc>().add(
      SubmitVerification(
        ktpPath: _ktpPhoto!.path,
        certificatePaths: _certificatePhotos.map((f) => f.path).toList(),
        selfiePath: _selfiePhoto?.path,
      ),
    );
  }

  Widget _buildPhotoBox({
    required String title,
    required File? file,
    required VoidCallback onTap,
    VoidCallback? onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.label),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppSizing.radiusMd),
              border: Border.all(color: AppColors.border),
              image: file != null
                  ? DecorationImage(image: FileImage(file), fit: BoxFit.cover)
                  : null,
            ),
            child: file == null
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo,
                        color: AppColors.primary,
                        size: 32,
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text('Ambil / Pilih Foto', style: AppTypography.caption),
                    ],
                  )
                : Align(
                    alignment: Alignment.topRight,
                    child: onRemove != null
                        ? IconButton(
                            icon: const Icon(
                              Icons.cancel,
                              color: AppColors.error,
                            ),
                            onPressed: onRemove,
                          )
                        : null,
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomScrollPadding =
        AppSizing.bottomNavHeight +
        MediaQuery.paddingOf(context).bottom +
        AppSpacing.xl;

    return Scaffold(
      appBar: AppBar(title: const Text('Verifikasi Akun')),
      body: BlocConsumer<WorkerProfileBloc, WorkerProfileState>(
        listener: (context, state) {
          if (state is WorkerProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.failure.message),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state is WorkerProfileVerificationSubmitted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Data verifikasi berhasil dikirim. Harap tunggu proses persetujuan.',
                ),
                backgroundColor: AppColors.success,
              ),
            );
            context.pop();
          }
        },
        builder: (context, state) {
          final isLoading = state is WorkerProfileActionLoading;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: AppSpacing.pagePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AppCard(
                      color: AppColors.primaryContainer,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.security, color: AppColors.primary),
                              SizedBox(width: AppSpacing.md),
                              Text('Keamanan Data', style: AppTypography.h6),
                            ],
                          ),
                          SizedBox(height: AppSpacing.sm),
                          Text(
                            'Data identitas Anda akan dienkripsi dan disimpan dengan aman. Data ini hanya digunakan untuk keperluan verifikasi.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    _buildPhotoBox(
                      title: 'Foto KTP Asli (Wajib)',
                      file: _ktpPhoto,
                      onTap: () {
                        _pickImage(ImageSource.camera, (file) {
                          setState(() => _ktpPhoto = file);
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    _buildPhotoBox(
                      title: 'Foto Selfie dengan KTP (Opsional)',
                      file: _selfiePhoto,
                      onTap: () {
                        _pickImage(ImageSource.camera, (file) {
                          setState(() => _selfiePhoto = file);
                        });
                      },
                      onRemove: () {
                        setState(() => _selfiePhoto = null);
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    const Text(
                      'Sertifikat Keahlian (Opsional, max 5)',
                      style: AppTypography.label,
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: AppSpacing.md,
                            mainAxisSpacing: AppSpacing.md,
                            childAspectRatio: 1.5,
                          ),
                      itemCount: _certificatePhotos.length < 5
                          ? _certificatePhotos.length + 1
                          : 5,
                      itemBuilder: (context, index) {
                        if (index == _certificatePhotos.length) {
                          return GestureDetector(
                            onTap: () {
                              _pickImage(ImageSource.gallery, (file) {
                                setState(() {
                                  _certificatePhotos.add(file);
                                });
                              });
                            },
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(
                                  AppSizing.radiusMd,
                                ),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Icon(
                                Icons.add_photo_alternate,
                                color: AppColors.primary,
                              ),
                            ),
                          );
                        }

                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              AppSizing.radiusMd,
                            ),
                            image: DecorationImage(
                              image: FileImage(_certificatePhotos[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                          alignment: Alignment.topRight,
                          child: IconButton(
                            icon: const Icon(
                              Icons.cancel,
                              color: AppColors.error,
                            ),
                            onPressed: () {
                              setState(() {
                                _certificatePhotos.removeAt(index);
                              });
                            },
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: AppSpacing.xxl),
                    AppButton(text: 'Kirim Pengajuan', onPressed: _submit),
                    SizedBox(height: bottomScrollPadding),
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
}
