import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/domain/entities/user.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

/// Page for editing user profile fields.
///
/// Provides form fields for full name (max 255 chars), phone (max 20 chars),
/// and address. Validates input lengths before submission.
/// Retains form data on failure as per requirement 2.7.
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({required this.user, super.key});

  /// The current user data to pre-fill the form.
  final User user;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  /// Maximum length for full name field.
  static const int _maxFullNameLength = 255;

  /// Maximum length for phone field.
  static const int _maxPhoneLength = 20;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.user.fullName);
    _phoneController = TextEditingController(text: widget.user.phone);
    _addressController = TextEditingController(text: widget.user.address ?? '');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();

    context.read<ProfileBloc>().add(UpdateProfile(
          fullName: fullName != widget.user.fullName ? fullName : null,
          phone: phone != widget.user.phone ? phone : null,
          address: address != (widget.user.address ?? '') ? address : null,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
        centerTitle: true,
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileLoaded) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profil berhasil diperbarui'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.of(context).pop();
          }
          if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.failure.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final isUpdating = state is ProfileUpdating;

          return SingleChildScrollView(
            padding: AppSpacing.pagePadding,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: _fullNameController,
                    label: 'Nama Lengkap',
                    hint: 'Masukkan nama lengkap',
                    maxLength: _maxFullNameLength,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(Icons.person_outline),
                    enabled: !isUpdating,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama lengkap tidak boleh kosong';
                      }
                      return InputLengthValidator.validate(
                        value,
                        _maxFullNameLength,
                        fieldName: 'Nama lengkap',
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    controller: _phoneController,
                    label: 'Nomor Telepon',
                    hint: 'Masukkan nomor telepon',
                    maxLength: _maxPhoneLength,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(Icons.phone_outlined),
                    enabled: !isUpdating,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nomor telepon tidak boleh kosong';
                      }
                      return InputLengthValidator.validate(
                        value,
                        _maxPhoneLength,
                        fieldName: 'Nomor telepon',
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    controller: _addressController,
                    label: 'Alamat',
                    hint: 'Masukkan alamat',
                    maxLines: 3,
                    minLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    enabled: !isUpdating,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    text: 'Simpan Perubahan',
                    onPressed: isUpdating ? null : _onSubmit,
                    isLoading: isUpdating,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
