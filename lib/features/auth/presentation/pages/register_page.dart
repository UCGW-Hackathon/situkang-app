import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/repositories/auth_repository.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/password_strength_indicator.dart';

/// Registration page with full form validation.
///
/// Collects full_name (max 255), email, phone (max 20), password,
/// password confirmation, and role selection (user/worker).
/// Validates all fields before submission.
///
/// Validates:
/// - Requirement 1.1: Registration with valid data
/// - Requirement 1.2: Duplicate email error
/// - Requirement 1.3: Duplicate phone error
/// - Requirement 1.4: Password strength requirements
/// - Requirement 1.5: Password confirmation match
class RegisterPage extends StatefulWidget {
  /// Creates a [RegisterPage].
  const RegisterPage({
    super.key,
    this.onLoginTap,
  });

  /// Callback when the user taps "Login" link.
  final VoidCallback? onLoginTap;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  UserRole _selectedRole = UserRole.user;
  String _currentPassword = '';

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: _authStateListener,
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return SingleChildScrollView(
              padding: AppSpacing.pagePadding,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildErrorBanner(state),
                    _buildFullNameField(isLoading),
                    const SizedBox(height: AppSpacing.formFieldSpacing),
                    _buildEmailField(isLoading),
                    const SizedBox(height: AppSpacing.formFieldSpacing),
                    _buildPhoneField(isLoading),
                    const SizedBox(height: AppSpacing.formFieldSpacing),
                    _buildPasswordField(isLoading),
                    PasswordStrengthIndicator(password: _currentPassword),
                    const SizedBox(height: AppSpacing.formFieldSpacing),
                    _buildConfirmPasswordField(isLoading),
                    const SizedBox(height: AppSpacing.formFieldSpacing),
                    _buildRoleSelector(isLoading),
                    const SizedBox(height: AppSpacing.lg),
                    _buildRegisterButton(isLoading),
                    const SizedBox(height: AppSpacing.lg),
                    _buildLoginLink(),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Buat Akun Baru',
          style: AppTypography.h3,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Lengkapi data di bawah untuk mendaftar',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(AuthState state) {
    if (state is! AuthError) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: AppSpacing.cardPaddingSmall,
        decoration: BoxDecoration(
          color: AppColors.errorLight,
          borderRadius: BorderRadius.circular(AppSizing.radiusSm),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: AppSizing.iconMd),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                state.failure.message,
                style: AppTypography.bodySmall.copyWith(color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullNameField(bool isLoading) {
    return AppTextField(
      controller: _fullNameController,
      label: 'Nama Lengkap',
      hint: 'Masukkan nama lengkap Anda',
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.words,
      enabled: !isLoading,
      maxLength: 255,
      prefixIcon: const Icon(Icons.person_outlined),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Nama lengkap tidak boleh kosong';
        }
        final error = InputLengthValidator.validate(
          value,
          255,
          fieldName: 'Nama lengkap',
        );
        if (error != null) return error;
        return null;
      },
    );
  }

  Widget _buildEmailField(bool isLoading) {
    return AppTextField(
      controller: _emailController,
      label: 'Email',
      hint: 'Masukkan email Anda',
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      enabled: !isLoading,
      prefixIcon: const Icon(Icons.email_outlined),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Email tidak boleh kosong';
        }
        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
          return 'Format email tidak valid';
        }
        return null;
      },
    );
  }

  Widget _buildPhoneField(bool isLoading) {
    return AppTextField(
      controller: _phoneController,
      label: 'Nomor Telepon',
      hint: '+62812345678',
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      enabled: !isLoading,
      maxLength: 20,
      prefixIcon: const Icon(Icons.phone_outlined),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Nomor telepon tidak boleh kosong';
        }
        final error = InputLengthValidator.validate(
          value,
          20,
          fieldName: 'Nomor telepon',
        );
        if (error != null) return error;
        return null;
      },
    );
  }

  Widget _buildPasswordField(bool isLoading) {
    return AppTextField(
      controller: _passwordController,
      label: 'Password',
      hint: 'Minimal 8 karakter',
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.next,
      enabled: !isLoading,
      prefixIcon: const Icon(Icons.lock_outlined),
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        ),
        onPressed: () {
          setState(() {
            _obscurePassword = !_obscurePassword;
          });
        },
      ),
      onChanged: (value) {
        setState(() {
          _currentPassword = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Password tidak boleh kosong';
        }
        return PasswordValidator.validate(value);
      },
    );
  }

  Widget _buildConfirmPasswordField(bool isLoading) {
    return AppTextField(
      controller: _confirmPasswordController,
      label: 'Konfirmasi Password',
      hint: 'Masukkan ulang password',
      obscureText: _obscureConfirmPassword,
      textInputAction: TextInputAction.done,
      enabled: !isLoading,
      prefixIcon: const Icon(Icons.lock_outlined),
      suffixIcon: IconButton(
        icon: Icon(
          _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        ),
        onPressed: () {
          setState(() {
            _obscureConfirmPassword = !_obscureConfirmPassword;
          });
        },
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Konfirmasi password tidak boleh kosong';
        }
        return PasswordConfirmationValidator.validate(
          _passwordController.text,
          value,
        );
      },
    );
  }

  Widget _buildRoleSelector(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Daftar Sebagai',
          style: AppTypography.label,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _RoleOption(
                label: 'Pengguna',
                description: 'Cari tukang untuk kebutuhan Anda',
                icon: Icons.person_outlined,
                isSelected: _selectedRole == UserRole.user,
                isEnabled: !isLoading,
                onTap: () {
                  setState(() {
                    _selectedRole = UserRole.user;
                  });
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _RoleOption(
                label: 'Tukang',
                description: 'Tawarkan jasa Anda',
                icon: Icons.build_outlined,
                isSelected: _selectedRole == UserRole.worker,
                isEnabled: !isLoading,
                onTap: () {
                  setState(() {
                    _selectedRole = UserRole.worker;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRegisterButton(bool isLoading) {
    return AppButton(
      text: 'Daftar',
      onPressed: _onRegister,
      isLoading: isLoading,
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Sudah punya akun? ',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        TextButton(
          onPressed: widget.onLoginTap,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Masuk',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _authStateListener(BuildContext context, AuthState state) {
    // Navigation on Authenticated state is handled by the router/auth guard.
  }

  void _onRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            RegisterRequested(
              params: RegisterParams(
                fullName: _fullNameController.text.trim(),
                email: _emailController.text.trim(),
                phone: _phoneController.text.trim(),
                password: _passwordController.text,
                passwordConfirmation: _confirmPasswordController.text,
                role: _selectedRole,
              ),
            ),
          );
    }
  }
}

/// A selectable role option card for the registration form.
class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.label,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
  });

  final String label;
  final String description;
  final IconData icon;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: AppSpacing.cardPaddingSmall,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizing.radiusSm),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: AppSizing.iconLg,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.label.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              description,
              style: AppTypography.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
