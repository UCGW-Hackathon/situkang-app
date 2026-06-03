import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/theme.dart';

/// A reusable text field widget with consistent styling and validation support.
///
/// Wraps [TextFormField] with SITUKANG app styling, supports obscure text,
/// prefix/suffix icons, max length counter, and validation error display.
class AppTextField extends StatelessWidget {
  /// Creates an [AppTextField].
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
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

  /// Error text displayed below the field. Overrides validator errors.
  final String? errorText;

  /// Whether to obscure the text (for passwords).
  final bool obscureText;

  /// Icon displayed at the start of the field.
  final Widget? prefixIcon;

  /// Icon/widget displayed at the end of the field.
  final Widget? suffixIcon;

  /// Maximum character length with counter display.
  final int? maxLength;

  /// Maximum number of lines for multiline input.
  final int? maxLines;

  /// Minimum number of lines for multiline input.
  final int? minLines;

  /// Keyboard type for the input.
  final TextInputType? keyboardType;

  /// Action button on the keyboard.
  final TextInputAction? textInputAction;

  /// Validation function returning an error string or null.
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTypography.label,
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          maxLength: maxLength,
          maxLines: maxLines,
          minLines: minLines,
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
          style: AppTypography.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            counterText: maxLength != null ? null : '',
          ),
        ),
      ],
    );
  }
}
