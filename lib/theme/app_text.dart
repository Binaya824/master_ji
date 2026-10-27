import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography for MasterJi.
/// • Headings / display numbers → Baloo Bhaina 2 (rounded, supports Odia + Latin)
/// • Body / labels → Noto Sans (for English) / Noto Sans Oriya (for Odia)
///
/// google_fonts caches fonts to device storage after first download.
/// For full offline deployment, replace these calls with bundled font assets.
abstract final class AppTextStyles {
  // ── Display (large numbers like marks) ──────────────────────────────────
  static TextStyle displayLarge({Color color = AppColors.textPrimary}) =>
      GoogleFonts.balooBhaina2(
        fontSize: 56,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.1,
      );

  static TextStyle displayMedium({Color color = AppColors.textPrimary}) =>
      GoogleFonts.balooBhaina2(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.2,
      );

  // ── Headings ─────────────────────────────────────────────────────────────
  static TextStyle headlineLarge({Color color = AppColors.textPrimary}) =>
      GoogleFonts.balooBhaina2(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.3,
      );

  static TextStyle headlineMedium({Color color = AppColors.textPrimary}) =>
      GoogleFonts.balooBhaina2(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.35,
      );

  static TextStyle headlineSmall({Color color = AppColors.textPrimary}) =>
      GoogleFonts.balooBhaina2(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.4,
      );

  // ── Title / label ────────────────────────────────────────────────────────
  static TextStyle titleLarge({Color color = AppColors.textPrimary}) =>
      GoogleFonts.notoSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.45,
      );

  static TextStyle titleMedium({Color color = AppColors.textPrimary}) =>
      GoogleFonts.notoSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.45,
      );

  // ── Body ─────────────────────────────────────────────────────────────────
  static TextStyle bodyLarge({Color color = AppColors.textPrimary}) =>
      GoogleFonts.notoSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.5,
      );

  static TextStyle bodyMedium({Color color = AppColors.textSecondary}) =>
      GoogleFonts.notoSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.5,
      );

  static TextStyle bodySmall({Color color = AppColors.textSecondary}) =>
      GoogleFonts.notoSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.5,
      );

  // ── Label / chip ─────────────────────────────────────────────────────────
  static TextStyle labelMedium({Color color = AppColors.textSecondary}) =>
      GoogleFonts.notoSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.4,
        letterSpacing: 0.2,
      );

  static TextStyle labelSmall({Color color = AppColors.textSecondary}) =>
      GoogleFonts.notoSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.4,
        letterSpacing: 0.2,
      );

  // ── Button ───────────────────────────────────────────────────────────────
  static TextStyle button({Color color = Colors.white}) =>
      GoogleFonts.balooBhaina2(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.2,
      );

  // ── Number (scan counts, marks) ──────────────────────────────────────────
  static TextStyle numberHuge({Color color = AppColors.textPrimary}) =>
      GoogleFonts.balooBhaina2(
        fontSize: 72,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.0,
      );

  static TextStyle numberMedium({Color color = AppColors.textPrimary}) =>
      GoogleFonts.balooBhaina2(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.2,
      );
}
