import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:omr_scanner/features/answer_key/answer_grid.dart';
import 'package:omr_scanner/l10n/app_localizations.dart';
import 'package:omr_scanner/logic/scoring.dart';
import 'package:omr_scanner/models/exam.dart';
import 'package:omr_scanner/theme/app_colors.dart';
import 'package:omr_scanner/theme/app_text.dart';
import 'package:omr_scanner/theme/app_theme.dart';
import 'package:omr_scanner/widgets/app_card.dart';
import 'package:omr_scanner/widgets/primary_button.dart';
import 'package:omr_scanner/widgets/stat_pill.dart';

/// Reusable result card showing marks, stat pills, optional penalty formula,
/// expandable review grid, and next/rescan action buttons.
class ResultCard extends StatefulWidget {
  final SheetResult result;
  final int questionCount;
  final Map<int, int> answerKey;
  final bool negativeMarking;
  final double marksPerCorrect;
  final double negativeValue;
  final VoidCallback onNextSheet;
  final VoidCallback onRescan;

  const ResultCard({
    super.key,
    required this.result,
    required this.questionCount,
    required this.answerKey,
    required this.negativeMarking,
    required this.marksPerCorrect,
    required this.negativeValue,
    required this.onNextSheet,
    required this.onRescan,
  });

  @override
  State<ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<ResultCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final totalPossibleMarks = widget.questionCount * widget.marksPerCorrect;

    return AppCard(
      padding: const EdgeInsets.all(AppTheme.sp20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sheet number header
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                l10n.sheetNumber(widget.result.sheetNumber),
                style: AppTextStyles.labelMedium(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.sp12),

          // Big marks display with count-up animation
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: widget.result.marks),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, animatedMarks, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    formatMarks(animatedMarks),
                    style: AppTextStyles.numberHuge(color: AppColors.primary),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '/ ${formatMarks(totalPossibleMarks)}',
                    style: AppTextStyles.headlineMedium(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppTheme.sp16),

          // Stat pills row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StatPill.correct(count: widget.result.correct),
              const SizedBox(width: AppTheme.sp8),
              StatPill.wrong(count: widget.result.wrong),
              const SizedBox(width: AppTheme.sp8),
              StatPill.skipped(count: widget.result.skipped),
            ],
          ),

          // Formula text if negative marking is enabled
          if (widget.negativeMarking) ...[
            const SizedBox(height: AppTheme.sp12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l10n.scoreFormula(
                  widget.result.correct,
                  formatMarks(widget.marksPerCorrect),
                  widget.result.wrong,
                  formatMarks(widget.negativeValue),
                  formatMarks(widget.result.marks),
                ),
                style: AppTextStyles.bodySmall(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          const SizedBox(height: AppTheme.sp16),
          const Divider(height: 1),

          // Expandable answers section
          Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
            ),
            child: ExpansionTile(
              initiallyExpanded: false,
              tilePadding: EdgeInsets.zero,
              title: Text(
                _expanded ? l10n.hideAnswers : l10n.seeAnswers,
                style: AppTextStyles.titleMedium(color: AppColors.primary),
              ),
              trailing: Icon(
                _expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: AppColors.primary,
              ),
              onExpansionChanged: (exp) {
                setState(() => _expanded = exp);
              },
              children: [
                SizedBox(
                  height: 300,
                  child: AnswerGrid.review(
                    questionCount: widget.questionCount,
                    studentAnswers: widget.result.answers,
                    answerKey: widget.answerKey,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.sp16),

          // Primary action: Next sheet
          PrimaryButton(
            label: l10n.nextSheet,
            onPressed: widget.onNextSheet,
          ),
          const SizedBox(height: AppTheme.sp8),

          // Secondary action: Rescan
          TextButton(
            onPressed: widget.onRescan,
            child: Text(
              l10n.rescanThisSheet,
              style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    )
        .animate()
        .slideY(
          begin: 0.15,
          end: 0,
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        )
        .fadeIn(duration: 300.ms);
  }
}
