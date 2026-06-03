import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/app_text_field.dart';

/// A thin wrapper around [AppTextField] for auth-specific styling.
///
/// Provides consistent styling for authentication forms with
/// optional password visibility toggle and validation feedback.
class AuthFormField extends StatelessWidget {
  /// Creates an [AuthFormField].
  const AuthFormField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.enabled = true,
    this.autofocus = false,
    this.inputFormatters,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
  });

  /// Controller for the text field.
  final TextEditingController? controller;

  /// Label text displayed above the field.
  final String? label;

  /// Hint text displayed when the field is empty.
  final String? hint;

  /// Error text displayed below the field.
  final String? errorText;

  /// Whether to obscure the text (for passwords).
  final bool obscureText;

  /// Icon displayed at the start of the field.
  final Widget? prefixIcon;

  /// Icon/widget displayed at the end of the field.
  final Widget? suffixIcon;

  /// Maximum character length.
  final int? maxLength;

  /// Keyboard type for the input.
  final TextInputType? keyboardType;

  /// Action button on the keyboard.
  final TextInputAction? textInputAction;

  /// Validation function.
  final String? Function(String?)? validator;

  /// Callback when the text changes.
  final ValueChanged<String>? onChanged;

  /// Callback when the field is submitted.
  final ValueChanged<String>? onFieldSubmitted;

  /// Whether the field is enabled.
  final bool enabled;

  /// Whether to autofocus this field.
  final bool autofocus;

  /// Input formatters for restricting input.
  final List<TextInputFormatter>? inputFormatters;

  /// Focus node for managing focus.
  final FocusNode? focusNode;

  /// Text capitalization behavior.
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.formFieldSpacing),
      child: AppTextField(
        controller: controller,
        label: label,
        hint: hint,
        errorText: errorText,
        obscureText: obscureText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        maxLength: maxLength,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        validator: validator,
        onChanged: onChanged,
        onFieldSubmitted: onFieldSubmitted,
        enabled: enabled,
        autofocus: autofocus,
        inputFormatters: inputFormatters,
        focusNode: focusNode,
        textCapitalization: textCapitalization,
      ),
    );
  }
}
