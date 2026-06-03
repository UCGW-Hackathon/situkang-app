import 'package:flutter/material.dart';

/// Spacing constants for consistent layout throughout the app.
///
/// Uses a 4px base unit scale for predictable spacing.
class AppSpacing {
  AppSpacing._();

  // ─── Spacing Values ──────────────────────────────────────────────────────────
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // ─── Page Padding ────────────────────────────────────────────────────────────
  static const double pagePaddingHorizontal = 16.0;
  static const double pagePaddingVertical = 16.0;
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: pagePaddingHorizontal,
    vertical: pagePaddingVertical,
  );
  static const EdgeInsets pageHorizontalPadding = EdgeInsets.symmetric(
    horizontal: pagePaddingHorizontal,
  );

  // ─── Card Padding ────────────────────────────────────────────────────────────
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets cardPaddingSmall = EdgeInsets.all(sm);

  // ─── Section Spacing ─────────────────────────────────────────────────────────
  static const double sectionSpacing = 24.0;
  static const double itemSpacing = 12.0;
  static const double listItemSpacing = 8.0;

  // ─── Form Spacing ────────────────────────────────────────────────────────────
  static const double formFieldSpacing = 16.0;
  static const double formSectionSpacing = 24.0;
}
