import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../bloc/auth_bloc.dart';

/// Forgot password page with email input.
///
/// Allows users to request a password reset link sent to their email.
/// Shows a success message on [PasswordResetEmailSent] state.
///
/// Validates:
/// - Requirement 1.12: Send reset link to registered email
class ForgotPasswordPage extends StatefulWidget {
  /// Creates a [ForgotPasswordPage].
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lupa Password'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: _authStateListener,
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            if (_emailSent) {
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
                    _buildEmailField(isLoading),
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
          Icons.lock_reset_outlined,
          size: AppSizing.iconXl,
          color: AppColors.primary,
        ),
        const SizedBox(height: AppSpacing.md),
        const Text(
          'Reset Password',
          style: AppTypography.h3,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Masukkan email yang terdaftar. Kami akan mengirimkan link untuk mereset password Anda.',
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

  Widget _buildEmailField(bool isLoading) {
    return AppTextField(
      controller: _emailController,
      label: 'Email',
      hint: 'Masukkan email terdaftar',
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.done,
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
      onFieldSubmitted: (_) => _onSubmit(),
    );
  }

  Widget _buildSubmitButton(bool isLoading) {
    return AppButton(
      text: 'Kirim Link Reset',
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
            Icons.mark_email_read_outlined,
            size: AppSizing.iconXxl,
            color: AppColors.success,
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Email Terkirim!',
            style: AppTypography.h3,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Kami telah mengirimkan link reset password ke ${_emailController.text.trim()}. Silakan cek inbox Anda.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            text: 'Kembali ke Login',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _authStateListener(BuildContext context, AuthState state) {
    if (state is PasswordResetEmailSent) {
      setState(() {
        _emailSent = true;
      });
    }
  }

  void _onSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            ForgotPasswordRequested(email: _emailController.text.trim()),
          );
    }
  }
}
