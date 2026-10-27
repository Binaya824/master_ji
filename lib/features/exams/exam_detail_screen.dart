import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:omr_scanner/app/router.dart';
import 'package:omr_scanner/data/local_repository.dart';
import 'package:omr_scanner/l10n/app_localizations.dart';
import 'package:omr_scanner/models/exam.dart';
import 'package:omr_scanner/theme/app_colors.dart';
import 'package:omr_scanner/theme/app_text.dart';
import 'package:omr_scanner/theme/app_theme.dart';
import 'package:omr_scanner/widgets/app_card.dart';
import 'package:omr_scanner/widgets/empty_state.dart';

/// Screen displaying the details of an exam, showing all subjects and progress.
class ExamDetailScreen extends StatefulWidget {
  final String examId;

  const ExamDetailScreen({
    super.key,
    required this.examId,
  });

  @override
  State<ExamDetailScreen> createState() => _ExamDetailScreenState();
}

class _ExamDetailScreenState extends State<ExamDetailScreen> {
  Exam? _exam;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadExam();
  }

  Future<void> _loadExam() async {
    final repo = context.read<LocalRepository>();
    final exam = await repo.loadExam(widget.examId);
    if (!mounted) return;
    setState(() {
      _exam = exam;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final exam = _exam;
    if (exam == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.exams)),
        body: Center(
          child: EmptyState(
            icon: Icons.error_outline,
            title: 'Exam not found',
            actionLabel: l10n.back,
            onAction: () => context.pop(),
          ),
        ),
      );
    }

    final subjects = exam.subjects;

    return Scaffold(
      appBar: AppBar(
        title: Text(exam.name, style: AppTextStyles.headlineMedium()),
      ),
      body: subjects.isEmpty
          ? Center(
              child: EmptyState(
                icon: Icons.menu_book_outlined,
                title: 'No subjects in this exam',
                subtitle: 'Tap back to edit or create a new exam',
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadExam,
              child: ListView.separated(
                padding: const EdgeInsets.all(AppTheme.sp16),
                itemCount: subjects.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppTheme.sp12),
                itemBuilder: (context, index) {
                  final subject = subjects[index];
                  final accentColor = AppColors.subjectPalette[
                      index % AppColors.subjectPalette.length];

                  final allSets =
                      subject.papers.expand((p) => p.sets).toList();
                  final totalSets = allSets.length;
                  final doneSets = allSets.where((s) => s.hasKey).length;
                  final progress =
                      totalSets > 0 ? doneSets / totalSets : 0.0;

                  return _SubjectCard(
                    subject: subject,
                    accentColor: accentColor,
                    doneSets: doneSets,
                    totalSets: totalSets,
                    progress: progress,
                    onTap: () async {
                      await context.push(
                        AppRoutes.subjectDetailPath(
                          widget.examId,
                          subject.id,
                        ),
                      );
                      _loadExam();
                    },
                  )
                      .animate()
                      .fade(duration: 300.ms, delay: (40 * index).ms)
                      .slideY(
                        begin: 0.08,
                        end: 0,
                        duration: 300.ms,
                        delay: (40 * index).ms,
                        curve: Curves.easeOutQuad,
                      );
                },
              ),
            ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final Subject subject;
  final Color accentColor;
  final int doneSets;
  final int totalSets;
  final double progress;
  final VoidCallback onTap;

  const _SubjectCard({
    required this.subject,
    required this.accentColor,
    required this.doneSets,
    required this.totalSets,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paperCount = subject.papers.length;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left color accent bar
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radiusCard),
                  bottomLeft: Radius.circular(AppTheme.radiusCard),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.sp16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.auto_stories_rounded,
                            color: accentColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppTheme.sp12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                subject.name,
                                style: AppTextStyles.titleLarge(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$paperCount ${paperCount == 1 ? "class" : "classes"}',
                                style: AppTextStyles.bodyMedium(),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.sp12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: accentColor.withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.answerKeysProgress(doneSets, totalSets),
                      style: AppTextStyles.bodySmall(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
