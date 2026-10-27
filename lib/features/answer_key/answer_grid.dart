import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:omr_scanner/l10n/app_localizations.dart';
import 'package:omr_scanner/theme/app_colors.dart';
import 'package:omr_scanner/theme/app_text.dart';
import 'package:omr_scanner/theme/app_theme.dart';

/// Reusable widget for displaying, entering, and reviewing OMR answer keys.
class AnswerGrid extends StatefulWidget {
  final int questionCount;
  final Map<int, int> initialAnswers;
  final bool readOnly;
  final Map<int, int>? answerKey; // for review mode coloring
  final void Function(Map<int, int>)? onChanged;

  const AnswerGrid.edit({
    super.key,
    required this.questionCount,
    Map<int, int>? initialAnswers,
    required this.onChanged,
  })  : readOnly = false,
        answerKey = null,
        initialAnswers = initialAnswers ?? const {};

  const AnswerGrid.review({
    super.key,
    required this.questionCount,
    required Map<int, int> studentAnswers,
    required this.answerKey,
  })  : readOnly = true,
        onChanged = null,
        initialAnswers = studentAnswers;

  @override
  State<AnswerGrid> createState() => _AnswerGridState();
}

class _AnswerGridState extends State<AnswerGrid> {
  static const double _rowHeight = 56.0;
  static const List<String> _optionLetters = ['A', 'B', 'C', 'D'];

  late Map<int, int> _answers;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _jumpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _answers = Map<int, int>.from(widget.initialAnswers);
  }

  @override
  void didUpdateWidget(covariant AnswerGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialAnswers != oldWidget.initialAnswers) {
      setState(() {
        _answers = Map<int, int>.from(widget.initialAnswers);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _jumpController.dispose();
    super.dispose();
  }

  void _handleOptionTap(int q, int option) {
    if (widget.readOnly) return;

    setState(() {
      _answers[q] = option;
    });
    widget.onChanged?.call(Map<int, int>.from(_answers));
  }

  void _jumpToQuestion(String text) {
    final q = int.tryParse(text.trim());
    if (q != null && q >= 1 && q <= widget.questionCount) {
      if (_scrollController.hasClients) {
        final targetOffset = max(0.0, (q - 1) * _rowHeight);
        final maxOffset = _scrollController.position.maxScrollExtent;
        _scrollController.animateTo(
          min(targetOffset, maxOffset),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
    _jumpController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filledCount = _answers.values.where((v) => v > 0).length;

    return Column(
      children: [
        if (!widget.readOnly) _buildTopBar(l10n, filledCount),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: widget.questionCount,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.sp16,
              vertical: AppTheme.sp8,
            ),
            itemExtent: _rowHeight,
            itemBuilder: (context, index) {
              final q = index + 1;
              return _buildRow(q);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(AppLocalizations l10n, int filledCount) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.sp16,
        vertical: AppTheme.sp8,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.sp12,
              vertical: AppTheme.sp4,
            ),
            decoration: BoxDecoration(
              color: filledCount == widget.questionCount
                  ? AppColors.primarySoft
                  : AppColors.divider.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppTheme.radiusChip),
            ),
            child: Text(
              l10n.filledCount(filledCount, widget.questionCount),
              style: AppTextStyles.labelMedium(
                color: filledCount == widget.questionCount
                    ? AppColors.primaryDark
                    : AppColors.textPrimary,
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 100,
            height: 36,
            child: TextField(
              controller: _jumpController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.go,
              onSubmitted: _jumpToQuestion,
              style: AppTextStyles.bodyMedium(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: l10n.jumpToQuestion,
                hintStyle: AppTextStyles.labelSmall(
                  color: AppColors.textSecondary,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.sp8,
                  vertical: AppTheme.sp4,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _jumpToQuestion(_jumpController.text),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(int q) {
    if (widget.readOnly) {
      return _buildReviewRow(q);
    }
    return _buildEditRow(q);
  }

  Widget _buildEditRow(int q) {
    final selectedOption = _answers[q] ?? 0;
    final isAnswered = selectedOption > 0;

    return Container(
      height: _rowHeight,
      margin: const EdgeInsets.symmetric(vertical: 2.0),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: isAnswered
            ? AppColors.primarySoft.withValues(alpha: 0.6)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        border: isAnswered
            ? Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1,
              )
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isAnswered
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$q',
              style: AppTextStyles.titleMedium(
                color: isAnswered
                    ? AppColors.primaryDark
                    : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: AppTheme.sp12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (index) {
                final optionNum = index + 1;
                final isSelected = selectedOption == optionNum;
                final letter = _optionLetters[index];

                Widget bubble = Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.cardBorder,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    letter,
                    style: AppTextStyles.titleMedium(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                );

                if (isSelected) {
                  bubble = bubble
                      .animate(key: ValueKey('sel_${q}_$optionNum'))
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1.0, 1.0),
                        duration: const Duration(milliseconds: 140),
                        curve: Curves.easeOutBack,
                      );
                }

                return GestureDetector(
                  onTap: () => _handleOptionTap(q, optionNum),
                  behavior: HitTestBehavior.opaque,
                  child: bubble,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewRow(int q) {
    final studentAns = widget.initialAnswers[q] ?? 0;
    final keyAns = widget.answerKey?[q];
    final isSkipped = studentAns == 0;
    final isCorrect = !isSkipped && studentAns == keyAns;
    final isWrong = !isSkipped && studentAns != keyAns;

    return Container(
      height: _rowHeight,
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        color: isSkipped
            ? AppColors.skipped.withValues(alpha: 0.05)
            : isWrong
                ? AppColors.wrong.withValues(alpha: 0.04)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '$q',
              style: AppTextStyles.titleMedium(
                color: isCorrect
                    ? AppColors.correct
                    : isWrong
                        ? AppColors.wrong
                        : AppColors.skipped,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: AppTheme.sp12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (index) {
                final optionNum = index + 1;
                final letter = _optionLetters[index];

                Color bgColor = AppColors.surface;
                Color borderColor = AppColors.cardBorder;
                Color textColor = AppColors.textPrimary;
                Widget? overlayIcon;

                if (optionNum == studentAns) {
                  if (isCorrect) {
                    bgColor = AppColors.correct;
                    borderColor = AppColors.correct;
                    textColor = Colors.white;
                    overlayIcon = const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    );
                  } else {
                    bgColor = AppColors.wrong;
                    borderColor = AppColors.wrong;
                    textColor = Colors.white;
                    overlayIcon = const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    );
                  }
                } else if (optionNum == keyAns && (isWrong || isSkipped)) {
                  // Subtle hint for the key option on wrong/skipped
                  borderColor = AppColors.correct;
                  bgColor = AppColors.primarySoft;
                  textColor = AppColors.primaryDark;
                }

                return Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: borderColor,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: overlayIcon ??
                      Text(
                        letter,
                        style: AppTextStyles.titleMedium(color: textColor),
                      ),
                );
              }),
            ),
          ),
          if (keyAns != null && (isWrong || isSkipped))
            Container(
              width: 36,
              height: 26,
              margin: const EdgeInsets.only(left: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.divider.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _optionLetters[(keyAns - 1).clamp(0, 3)],
                style: AppTextStyles.labelSmall(
                  color: AppColors.textPrimary,
                ),
              ),
            )
          else
            const SizedBox(width: 40),
        ],
      ),
    );
  }
}
