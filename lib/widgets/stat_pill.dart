import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Coloured pill badge for Correct / Wrong / Skipped counts.
class StatPill extends StatelessWidget {
  final String label;
  final int count;
  final _PillVariant variant;

  const StatPill.correct({super.key, required this.count})
      : label = '',
        variant = _PillVariant.correct;

  const StatPill.wrong({super.key, required this.count})
      : label = '',
        variant = _PillVariant.wrong;

  const StatPill.skipped({super.key, required this.count})
      : label = '',
        variant = _PillVariant.skipped;

  const StatPill({
    super.key,
    required this.label,
    required this.count,
    required this.variant,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon, pillLabel) = switch (variant) {
      _PillVariant.correct => (
          AppColors.correct.withOpacity(0.12),
          AppColors.correct,
          '✓',
          label.isEmpty ? 'Correct' : label,
        ),
      _PillVariant.wrong => (
          AppColors.wrong.withOpacity(0.12),
          AppColors.wrong,
          '✗',
          label.isEmpty ? 'Wrong' : label,
        ),
      _PillVariant.skipped => (
          AppColors.skipped.withOpacity(0.15),
          AppColors.skipped,
          '–',
          label.isEmpty ? 'Skipped' : label,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.sp12,
        vertical: AppTheme.sp8,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            icon,
            style: TextStyle(
              color: fg,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$pillLabel $count',
            style: GoogleFonts.balooBhaina2(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

enum _PillVariant { correct, wrong, skipped }
