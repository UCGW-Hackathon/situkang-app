import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/widgets.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/password_strength_indicator.dart';

/// Reset password page with new password and confirmation fields.
///
/// Allows users to set a new password using a valid reset token.
/// Shows success on [PasswordResetSuccess] state.
///
/// Validates:
/// - Requirement 1.13: Reset password with valid token
/// - Requirement 1.14: Expired/used token error display
class ResetPasswordPage extends StatefulWidget {
  /// Creates a [ResetPasswordPage].
  const ResetPasswordPage({
    required this.token,
    super.key,
    this.onSuccess,
  });

  /// The password reset token received via email/deep link.
  final String token;

  /// Callback when password reset is successful.
  final VoidCallback? onSuccess;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _resetSuccess = false;
  String _currentPassword = '';

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: _authStateListener,
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            if (_resetSuccess) {
              return _buildSuccessView();
            }

            return SingleChildScrollView(
              padding: AppSpacing.pagePadding,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    _buildHeader(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildErrorBanner(state),
                    _buildPasswordField(isLoading),
                    PasswordStrengthIndicator(password: _currentPassword),
                    const SizedBox(height: AppSpacing.formFieldSpacing),
                    _buildConfirmPasswordField(isLoading),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSubmitButton(isLoading),
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
        const Icon(
          Icons.lock_outlined,
          size: AppSizing.iconXl,
          color: AppColors.primary,
        ),
        const SizedBox(height: AppSpacing.md),
        const Text(
          'Buat Password Baru',
          style: AppTypography.h3,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Masukkan password baru Anda. Pastikan password memenuhi persyaratan keamanan.',
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

  Widget _buildPasswordField(bool isLoading) {
    return AppTextField(
      controller: _passwordController,
      label: 'Password Baru',
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
      label: 'Konfirmasi Password Baru',
      hint: 'Masukkan ulang password baru',
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
      onFieldSubmitted: (_) => _onSubmit(),
    );
  }

  Widget _buildSubmitButton(bool isLoading) {
    return AppButton(
      text: 'Reset Password',
      onPressed: _onSubmit,
      isLoading: isLoading,
    );
  }

  Widget _buildSuccessView() {
    return Padding(
      padding: AppSpacing.pagePadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: AppSpacing.xxl),
          const Icon(
            Icons.check_circle_outline,
            size: AppSizing.iconXxl,
            color: AppColors.success,
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Password Berhasil Direset!',
            style: AppTypography.h3,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Password Anda telah berhasil diperbarui. Silakan masuk dengan password baru Anda.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            text: 'Masuk',
            onPressed: () {
              widget.onSuccess?.call();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
    );
  }

  void _authStateListener(BuildContext context, AuthState state) {
    if (state is PasswordResetSuccess) {
      setState(() {
        _resetSuccess = true;
      });
    }
  }

  void _onSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            ResetPasswordRequested(
              token: widget.token,
              password: _passwordController.text,
            ),
          );
    }
  }
}
