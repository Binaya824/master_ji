import 'package:flutter/material.dart';

/// All brand color tokens for MasterJi. Use these constants everywhere —
/// never hardcode colors in widgets.
abstract final class AppColors {
  // Primary brand — fresh teal-green
  static const Color primary = Color(0xFF12A07A);
  static const Color primaryDark = Color(0xFF0B7A5C);
  static const Color primarySoft = Color(0xFFE3F5EE);

  // Accent — warm amber (badges, "new", highlights)
  static const Color accent = Color(0xFFFFB547);

  // Semantic
  static const Color correct = Color(0xFF22A06B);
  static const Color wrong = Color(0xFFE5484D);
  static const Color skipped = Color(0xFF9AA4B2);

  // Backgrounds and surfaces
  static const Color background = Color(0xFFF6FAF8);
  static const Color surface = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF1B2B26);
  static const Color textSecondary = Color(0xFF5C6B66);

  // Utility
  static const Color divider = Color(0xFFE0EAE5);
  static const Color cardBorder = Color(0xFFD6EBE2);

  // Subject colors
  static const List<Color> subjectPalette = [
    Color(0xFF12A07A), // teal
    Color(0xFF5B6AF0), // indigo
    Color(0xFFFF7A45), // orange
    Color(0xFF9B59B6), // purple
    Color(0xFF2E86C1), // blue
    Color(0xFFE74C3C), // red
    Color(0xFF27AE60), // green
    Color(0xFFD35400), // deep orange
  ];

  // Shimmer / loading
  static const Color shimmerBase = Color(0xFFECF3F0);
  static const Color shimmerHighlight = Color(0xFFF6FAF8);
}
