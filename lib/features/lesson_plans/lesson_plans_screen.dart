import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:omr_scanner/data/settings_store.dart';
import 'package:omr_scanner/l10n/app_localizations.dart';
import 'package:omr_scanner/theme/app_colors.dart';
import 'package:omr_scanner/theme/app_text.dart';
import 'package:omr_scanner/theme/app_theme.dart';
import 'package:omr_scanner/widgets/primary_button.dart';

/// Screen displayed for the upcoming "Lesson Plans" feature.
/// Allows teachers to express interest ("Notify me") and vote on which subjects they need most.
class LessonPlansScreen extends StatelessWidget {
  const LessonPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = context.watch<SettingsStore>();
    final isNotified = store.lessonPlanNotifyMe;
    final selectedPoll = store.lessonPlanPollSelection;

    final subjectOptions = [
      (key: 'Odia', label: l10n.oriya),
      (key: 'English', label: l10n.english),
      (key: 'Math', label: l10n.math),
      (key: 'Science', label: l10n.science),
      (key: 'Social Science', label: l10n.socialScience),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.lessonPlans),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.sp24,
              vertical: AppTheme.sp24,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Big Icon ────────────────────────────────────────────────
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    size: 48,
                    color: AppColors.primary,
                  ),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.7, 0.7),
                      duration: 450.ms,
                      curve: Curves.easeOutBack,
                    )
                    .fadeIn(duration: 400.ms),

                const SizedBox(height: AppTheme.sp16),

                // ── Coming Soon Badge ───────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.sp16,
                    vertical: AppTheme.sp8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    l10n.lessonPlansComingSoon,
                    style: AppTextStyles.labelMedium(color: AppColors.accent),
                  ),
                ).animate(delay: 150.ms).fadeIn(duration: 350.ms),

                const SizedBox(height: AppTheme.sp16),

                // ── Title & Description ─────────────────────────────────────
                Text(
                  l10n.lessonPlans,
                  style: AppTextStyles.headlineLarge(),
                  textAlign: TextAlign.center,
                ).animate(delay: 250.ms).fadeIn(duration: 350.ms),

                const SizedBox(height: AppTheme.sp8),

                Text(
                  l10n.lessonPlansDescription,
                  style: AppTextStyles.bodyLarge(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ).animate(delay: 350.ms).fadeIn(duration: 350.ms),

                const SizedBox(height: AppTheme.sp24),

                // ── Notify Me Action ────────────────────────────────────────
                if (isNotified)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.sp16,
                      vertical: AppTheme.sp12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.correct.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                      border: Border.all(
                        color: AppColors.correct.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.correct,
                          size: 20,
                        ),
                        const SizedBox(width: AppTheme.sp8),
                        Text(
                          l10n.wellLetYouKnow,
                          style: AppTextStyles.titleMedium(
                            color: AppColors.correct,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 350.ms)
                else
                  SizedBox(
                    width: 240,
                    child: PrimaryButton(
                      label: l10n.notifyMe,
                      icon: const Icon(
                        Icons.notifications_active_outlined,
                        size: 18,
                      ),
                      onPressed: () async {
                        await context
                            .read<SettingsStore>()
                            .setLessonPlanNotifyMe(true);
                      },
                    ),
                  ).animate(delay: 450.ms).fadeIn(duration: 350.ms),

                const SizedBox(height: AppTheme.sp32),

                // ── Poll Section ────────────────────────────────────────────
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.whichSubjectMost,
                    style: AppTextStyles.titleMedium(),
                  ),
                ).animate(delay: 550.ms).fadeIn(duration: 350.ms),

                const SizedBox(height: AppTheme.sp12),

                Wrap(
                  spacing: AppTheme.sp8,
                  runSpacing: AppTheme.sp8,
                  children: subjectOptions.map((opt) {
                    final isSelected = selectedPoll == opt.key;
                    return FilterChip(
                      label: Text(opt.label),
                      selected: isSelected,
                      onSelected: (selected) async {
                        final newSelection = selected ? opt.key : '';
                        await context
                            .read<SettingsStore>()
                            .setLessonPlanPollSelection(newSelection);
                      },
                      selectedColor: AppColors.primary,
                      checkmarkColor: Colors.white,
                      labelStyle: AppTextStyles.labelMedium(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    );
                  }).toList(),
                ).animate(delay: 650.ms).fadeIn(duration: 350.ms),

                const SizedBox(height: AppTheme.sp24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
