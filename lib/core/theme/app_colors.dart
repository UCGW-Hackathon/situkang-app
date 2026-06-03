import 'package:flutter/material.dart';

/// Brand color palette for SITUKANG marketplace app.
///
/// Uses a professional, trustworthy palette suitable for a service marketplace:
/// - Primary: Deep blue for trust and professionalism
/// - Secondary: Teal for reliability and service
/// - Accent: Amber for warmth and action
class AppColors {
  AppColors._();

  // ─── Brand Primary ───────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF5E92F3);
  static const Color primaryDark = Color(0xFF003C8F);
  static const Color primaryContainer = Color(0xFFD6E4FF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF001A41);

  // ─── Brand Secondary ─────────────────────────────────────────────────────────
  static const Color secondary = Color(0xFF00897B);
  static const Color secondaryLight = Color(0xFF4EBAAA);
  static const Color secondaryDark = Color(0xFF005B4F);
  static const Color secondaryContainer = Color(0xFFB2DFDB);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF002019);

  // ─── Accent ──────────────────────────────────────────────────────────────────
  static const Color accent = Color(0xFFFFA000);
  static const Color accentLight = Color(0xFFFFD149);
  static const Color accentDark = Color(0xFFC67100);
  static const Color onAccent = Color(0xFF000000);

  // ─── Background & Surface ────────────────────────────────────────────────────
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F3F5);
  static const Color scaffoldBackground = Color(0xFFF8F9FA);

  // ─── Error / Success / Warning / Info ────────────────────────────────────────
  static const Color error = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFFFCDD2);
  static const Color onError = Color(0xFFFFFFFF);

  static const Color success = Color(0xFF388E3C);
  static const Color successLight = Color(0xFFC8E6C9);
  static const Color onSuccess = Color(0xFFFFFFFF);

  static const Color warning = Color(0xFFF57C00);
  static const Color warningLight = Color(0xFFFFE0B2);
  static const Color onWarning = Color(0xFF000000);

  static const Color info = Color(0xFF1976D2);
  static const Color infoLight = Color(0xFFBBDEFB);
  static const Color onInfo = Color(0xFFFFFFFF);

  // ─── Text Colors ─────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF616161);
  static const Color textDisabled = Color(0xFF9E9E9E);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textOnDark = Color(0xFFFFFFFF);

  // ─── Border Colors ───────────────────────────────────────────────────────────
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFF5F5F5);
  static const Color borderFocused = Color(0xFF1565C0);
  static const Color borderError = Color(0xFFD32F2F);

  // ─── Divider ─────────────────────────────────────────────────────────────────
  static const Color divider = Color(0xFFEEEEEE);

  // ─── Shadow ──────────────────────────────────────────────────────────────────
  static const Color shadow = Color(0x1A000000);

  // ─── Status Colors (Order-specific) ──────────────────────────────────────────
  static const Color statusPending = Color(0xFFFFA000);
  static const Color statusAccepted = Color(0xFF1976D2);
  static const Color statusOnTheWay = Color(0xFF7B1FA2);
  static const Color statusArrived = Color(0xFF00897B);
  static const Color statusInProgress = Color(0xFF1565C0);
  static const Color statusCompleted = Color(0xFF388E3C);
  static const Color statusCancelled = Color(0xFFD32F2F);
  static const Color statusRejected = Color(0xFF616161);

  // ─── Rating Colors ───────────────────────────────────────────────────────────
  static const Color ratingStar = Color(0xFFFFC107);
  static const Color ratingStarEmpty = Color(0xFFE0E0E0);
}
