import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:omr_scanner/app/router.dart';
import 'package:omr_scanner/data/account_state.dart';
import 'package:omr_scanner/data/local_repository.dart';
import 'package:omr_scanner/features/premium/premium_gate.dart';
import 'package:omr_scanner/l10n/app_localizations.dart';
import 'package:omr_scanner/logic/scoring.dart';
import 'package:omr_scanner/models/exam.dart';
import 'package:omr_scanner/theme/app_colors.dart';
import 'package:omr_scanner/theme/app_text.dart';
import 'package:omr_scanner/theme/app_theme.dart';
import 'package:omr_scanner/widgets/app_card.dart';
import 'package:omr_scanner/widgets/empty_state.dart';
import 'package:omr_scanner/widgets/primary_button.dart';

/// Summary screen displaying aggregated statistics, score list, and
/// most-missed questions for a scanning session (Quick Scan or Exam Paper).
class SessionSummaryScreen extends StatelessWidget {
  final List<SheetResult> results;
  final int questionCount;
  final bool isQuickScan;
  final String? sessionId;

  const SessionSummaryScreen({
    super.key,
    required this.results,
    required this.questionCount,
    this.isQuickScan = false,
    this.sessionId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final account = context.watch<AccountState>();

    if (results.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(l10n.sessionSummary),
        ),
        body: EmptyState(
          icon: Icons.assignment_outlined,
          title: l10n.noSheetsYet,
          actionLabel: l10n.continueScanning,
          onAction: () => Navigator.of(context).pop(),
        ),
      );
    }

    // Compute basic statistics
    final totalSheets = results.length;
    final totalMarks = results.fold<double>(0.0, (acc, r) => acc + r.marks);
    final avgMarks = totalMarks / totalSheets;
    final highestMarks = results.map((r) => r.marks).reduce(max);
    final lowestMarks = results.map((r) => r.marks).reduce(min);

    // Compute top 5 most missed questions
    final topMissed = _computeTopMissed(results, questionCount);

    // Sort sheets by sheet number ascending
    final sortedSheets = List<SheetResult>.from(results)
      ..sort((a, b) => a.sheetNumber.compareTo(b.sheetNumber));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.sessionSummary),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.sp16,
            vertical: AppTheme.sp16,
          ),
          children: [
            // ── 2x2 Stats Card ──────────────────────────────────────────────
            AppCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatCell(
                          label: l10n.sheets(totalSheets),
                          value: totalSheets.toString(),
                          icon: Icons.layers_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      Container(
                        height: 48,
                        width: 1,
                        color: AppColors.divider,
                      ),
                      Expanded(
                        child: _StatCell(
                          label: l10n.average,
                          value: formatMarks(avgMarks),
                          icon: Icons.analytics_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCell(
                          label: l10n.highest,
                          value: formatMarks(highestMarks),
                          icon: Icons.arrow_upward_rounded,
                          color: AppColors.correct,
                        ),
                      ),
                      Container(
                        height: 48,
                        width: 1,
                        color: AppColors.divider,
                      ),
                      Expanded(
                        child: _StatCell(
                          label: l10n.lowest,
                          value: formatMarks(lowestMarks),
                          icon: Icons.arrow_downward_rounded,
                          color: AppColors.wrong,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.sp24),

            // ── Most Missed Questions ───────────────────────────────────────
            if (topMissed.isNotEmpty) ...[
              Text(
                l10n.mostMissed,
                style: AppTextStyles.titleMedium(),
              ),
              const SizedBox(height: AppTheme.sp8),
              Wrap(
                spacing: AppTheme.sp8,
                runSpacing: AppTheme.sp8,
                children: topMissed.map((item) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.sp12,
                      vertical: AppTheme.sp8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.wrong.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                      border: Border.all(
                        color: AppColors.wrong.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cancel_outlined,
                          size: 16,
                          color: AppColors.wrong,
                        ),
                        const SizedBox(width: AppTheme.sp4),
                        Text(
                          'Q.${item.question} (${item.misses}/$totalSheets)',
                          style: AppTextStyles.labelMedium(
                            color: AppColors.wrong,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppTheme.sp24),
            ],

            // ── Score List Section ──────────────────────────────────────────
            Text(
              l10n.marks,
              style: AppTextStyles.titleMedium(),
            ),
            const SizedBox(height: AppTheme.sp8),

            AppCard(
              padding: EdgeInsets.zero,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedSheets.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final sheet = sortedSheets[index];
                  final maxPossible = questionCount > 0 ? questionCount : 1;
                  final ratio = (sheet.marks / maxPossible).clamp(0.0, 1.0);
                  final barColor = ratio >= 0.6
                      ? AppColors.correct
                      : ratio >= 0.35
                          ? AppColors.accent
                          : AppColors.wrong;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.sp16,
                      vertical: AppTheme.sp12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${l10n.sheetNumber(sheet.sheetNumber)}: ${formatMarks(sheet.marks)} / $questionCount',
                              style: AppTextStyles.titleMedium(),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _BreakdownPill(
                                  label: '${sheet.correct}',
                                  icon: Icons.check,
                                  color: AppColors.correct,
                                ),
                                const SizedBox(width: 4),
                                _BreakdownPill(
                                  label: '${sheet.wrong}',
                                  icon: Icons.close,
                                  color: AppColors.wrong,
                                ),
                                const SizedBox(width: 4),
                                _BreakdownPill(
                                  label: '${sheet.skipped}',
                                  icon: Icons.remove,
                                  color: AppColors.skipped,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.sp8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 5,
                            backgroundColor: AppColors.primarySoft,
                            color: barColor,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: AppTheme.sp24),

            // ── Bottom Action Buttons ───────────────────────────────────────
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.continueScanning),
            ),

            if (isQuickScan) ...[
              const SizedBox(height: AppTheme.sp12),
              PrimaryButton(
                label: l10n.saveAsExam,
                icon: Icon(
                  account.isPremium
                      ? Icons.bookmark_add_outlined
                      : Icons.lock_outline_rounded,
                  size: 18,
                ),
                onPressed: () {
                  PremiumGate.examOrSheet(context, () {
                    context.go(AppRoutes.examCreate);
                  });
                },
              ),
            ],

            const SizedBox(height: AppTheme.sp8),

            Center(
              child: TextButton(
                style: TextButton.styleFrom(foregroundColor: AppColors.wrong),
                onPressed: () => _handleClearSession(context, l10n),
                child: Text(l10n.clearSession),
              ),
            ),

            const SizedBox(height: AppTheme.sp24),
          ],
        ),
      ),
    );
  }

  Future<void> _handleClearSession(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.clearSession),
        content: Text(l10n.confirmDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.wrong),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final repo = context.read<LocalRepository>();
    if (isQuickScan) {
      await repo.clearQuickScan();
      if (context.mounted) {
        context.go(AppRoutes.home);
      }
    } else {
      if (sessionId != null && sessionId!.isNotEmpty) {
        await repo.deleteSession(sessionId!);
      }
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  /// Calculates top missed questions by detecting non-consensus choices and blanks.
  static List<({int question, int misses})> _computeTopMissed(
    List<SheetResult> sheets,
    int qCount,
  ) {
    if (sheets.isEmpty || qCount <= 0) return [];

    final missesList = <({int question, int misses})>[];

    for (int q = 1; q <= qCount; q++) {
      // Find distribution of choices for question q
      final freq = <int, int>{};
      for (final s in sheets) {
        final choice = s.answers[q] ?? 0;
        if (choice > 0) {
          freq[choice] = (freq[choice] ?? 0) + 1;
        }
      }

      // If everyone skipped or left blank
      if (freq.isEmpty) {
        missesList.add((question: q, misses: sheets.length));
        continue;
      }

      // Consensus choice is the most picked non-zero option
      int consensusChoice = 0;
      int maxFreq = 0;
      for (final entry in freq.entries) {
        if (entry.value > maxFreq) {
          maxFreq = entry.value;
          consensusChoice = entry.key;
        }
      }

      // Count students who missed it (answered 0 or picked different option)
      int missCount = 0;
      for (final s in sheets) {
        final choice = s.answers[q] ?? 0;
        if (choice == 0 || choice != consensusChoice) {
          missCount++;
        }
      }

      if (missCount > 0) {
        missesList.add((question: q, misses: missCount));
      }
    }

    missesList.sort((a, b) => b.misses.compareTo(a.misses));
    return missesList.take(5).toList();
  }
}

// ── Stat Grid Cell ──────────────────────────────────────────────────────────

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCell({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.sp12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: AppTheme.sp4),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.labelSmall(
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.sp4),
          Text(
            value,
            style: AppTextStyles.numberMedium(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

// ── Breakdown Pill (Correct / Wrong / Skipped) ──────────────────────────────

class _BreakdownPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _BreakdownPill({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 2),
          Text(
            label,
            style: AppTextStyles.labelSmall(color: color),
          ),
        ],
      ),
    );
  }
}
