import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/storage/cache_manager.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../bloc/auth_bloc.dart';

/// Login page with email/password fields, validation, and error display.
///
/// Allows users to authenticate with their email and password credentials.
/// Shows error messages from [AuthError] state and provides navigation
/// to register and forgot password pages.
///
/// Validates:
/// - Requirement 1.6: Login with valid credentials
/// - Requirement 1.7: Invalid credentials error display
class LoginPage extends StatefulWidget {
  /// Creates a [LoginPage].
  const LoginPage({
    super.key,
    this.onRegisterTap,
    this.onForgotPasswordTap,
  });

  /// Callback when the user taps "Register" link.
  final VoidCallback? onRegisterTap;

  /// Callback when the user taps "Forgot Password" link.
  final VoidCallback? onForgotPasswordTap;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  Timer? _autoLoginTimer;
  bool _isAutoLoggingIn = false;
  String? _bypassEmail;
  String? _bypassPassword;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDevConfig();
    });
  }

  Future<void> _loadDevConfig() async {
    if (DevConfig.bypassEnabled && DevConfig.bypassRole.isNotEmpty) {
      final String email;
      final String password;

      if (DevConfig.bypassRole == 'worker') {
        email = DevConfig.workerEmail;
        password = DevConfig.workerPassword;
      } else {
        email = DevConfig.userEmail;
        password = DevConfig.userPassword;
      }

      if (email.isNotEmpty && password.isNotEmpty) {
        setState(() {
          _bypassEmail = email;
          _bypassPassword = password;
          _isAutoLoggingIn = true;
        });
        _startAutoLoginTimer();
      }
    }
  }

  void _startAutoLoginTimer() {
    _autoLoginTimer = Timer(const Duration(milliseconds: 1500), () {
      if (_isAutoLoggingIn && _bypassEmail != null && _bypassPassword != null) {
        context.read<AuthBloc>().add(
          LoginRequested(
            email: _bypassEmail!,
            password: _bypassPassword!,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _autoLoginTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    const SizedBox(height: AppSpacing.xxl),
                    _buildHeader(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildAutoLoginBanner(),
                    _buildErrorBanner(state),
                    _buildEmailField(isLoading),
                    const SizedBox(height: AppSpacing.formFieldSpacing),
                    _buildPasswordField(isLoading),
                    const SizedBox(height: AppSpacing.sm),
                    _buildForgotPasswordLink(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildLoginButton(isLoading),
                    const SizedBox(height: AppSpacing.lg),
                    _buildRegisterLink(),
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
          'Masuk',
          style: AppTypography.h2,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Masuk ke akun Anda untuk melanjutkan',
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

  Widget _buildPasswordField(bool isLoading) {
    return AppTextField(
      controller: _passwordController,
      label: 'Password',
      hint: 'Masukkan password Anda',
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
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
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Password tidak boleh kosong';
        }
        return null;
      },
      onFieldSubmitted: (_) => _onLogin(),
    );
  }

  Widget _buildForgotPasswordLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: widget.onForgotPasswordTap,
        child: Text(
          'Lupa Password?',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(bool isLoading) {
    return AppButton(
      text: 'Masuk',
      onPressed: _onLogin,
      isLoading: isLoading,
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Belum punya akun? ',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        TextButton(
          onPressed: widget.onRegisterTap,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Daftar',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAutoLoginBanner() {
    if (!_isAutoLoggingIn) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizing.radiusSm),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Bypass Login Developer ke ${_bypassEmail ?? ''}...',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _isAutoLoggingIn = false;
                });
                _autoLoginTimer?.cancel();
              },
              child: const Text('Batal'),
            ),
          ],
        ),
      ),
    );
  }

  void _authStateListener(BuildContext context, AuthState state) {
    // Navigation on Authenticated state is handled by the router/auth guard.
  }

  void _onLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            LoginRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }
}
