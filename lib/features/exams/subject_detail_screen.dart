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

/// Screen displaying the papers (by class) for a selected subject in an exam.
class SubjectDetailScreen extends StatefulWidget {
  final String examId;
  final String subjectId;

  const SubjectDetailScreen({
    super.key,
    required this.examId,
    required this.subjectId,
  });

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {
  Exam? _exam;
  Subject? _subject;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final repo = context.read<LocalRepository>();
    final exam = await repo.loadExam(widget.examId);
    if (!mounted) return;

    Subject? foundSubject;
    if (exam != null) {
      try {
        foundSubject = exam.subjects.firstWhere((s) => s.id == widget.subjectId);
      } catch (_) {
        foundSubject = null;
      }
    }

    setState(() {
      _exam = exam;
      _subject = foundSubject;
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
    final subject = _subject;

    if (exam == null || subject == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.subject)),
        body: Center(
          child: EmptyState(
            icon: Icons.error_outline,
            title: 'Subject not found',
            actionLabel: l10n.back,
            onAction: () => context.pop(),
          ),
        ),
      );
    }

    final papers = List<Paper>.from(subject.papers)
      ..sort((a, b) => a.classNumber.compareTo(b.classNumber));

    return Scaffold(
      appBar: AppBar(
        title: Text(subject.name, style: AppTextStyles.headlineMedium()),
      ),
      body: papers.isEmpty
          ? Center(
              child: EmptyState(
                icon: Icons.class_outlined,
                title: 'No classes added',
                subtitle: 'Add classes to start scanning OMR sheets',
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.separated(
                padding: const EdgeInsets.all(AppTheme.sp16),
                itemCount: papers.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppTheme.sp16),
                itemBuilder: (context, index) {
                  final paper = papers[index];
                  return _PaperCard(
                    examId: widget.examId,
                    subjectId: widget.subjectId,
                    paper: paper,
                    onRefresh: _loadData,
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

class _PaperCard extends StatelessWidget {
  final String examId;
  final String subjectId;
  final Paper paper;
  final VoidCallback onRefresh;

  const _PaperCard({
    required this.examId,
    required this.subjectId,
    required this.paper,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sectionsText = paper.sections.join(', ');

    return AppCard(
      padding: const EdgeInsets.all(AppTheme.sp16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with class & sections and settings gear
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.classLabel(paper.classNumber),
                  style: AppTextStyles.titleMedium(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: AppTheme.sp8),
              Expanded(
                child: Text(
                  '${l10n.sections}: $sectionsText',
                  style: AppTextStyles.bodyMedium(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.settings_outlined,
                  color: AppColors.textSecondary,
                ),
                tooltip: l10n.paperSettings,
                onPressed: () async {
                  await context.push(
                    AppRoutes.paperSettingsPath(
                      examId,
                      subjectId,
                      paper.id,
                    ),
                  );
                  onRefresh();
                },
              ),
            ],
          ),
          const SizedBox(height: AppTheme.sp12),
          const Divider(height: 1),
          const SizedBox(height: AppTheme.sp12),

          // Sets list
          ...paper.sets.map((answerSet) {
            final hasKey = answerSet.hasKey;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasKey ? AppColors.correct : AppColors.skipped,
                    ),
                  ),
                  const SizedBox(width: AppTheme.sp8),
                  if (hasKey)
                    Text(
                      '${l10n.setLabel(answerSet.setLabel)} ✓',
                      style: AppTextStyles.titleMedium(
                        color: AppColors.correct,
                      ),
                    )
                  else
                    Text(
                      l10n.setLabel(answerSet.setLabel),
                      style: AppTextStyles.bodyMedium(),
                    ),
                  const Spacer(),
                  if (!hasKey)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(l10n.addAnswerKey),
                      onPressed: () async {
                        await context.push(
                          AppRoutes.answerKeyPath(
                            examId,
                            subjectId,
                            paper.id,
                            answerSet.id,
                          ),
                        );
                        onRefresh();
                      },
                    ),
                ],
              ),
            );
          }),

          const SizedBox(height: AppTheme.sp12),
          const Divider(height: 1),
          const SizedBox(height: AppTheme.sp12),

          // Bottom scan actions
          Text('Scan OMR sheets', style: AppTextStyles.labelMedium()),
          const SizedBox(height: AppTheme.sp8),
          Wrap(
            spacing: AppTheme.sp8,
            runSpacing: AppTheme.sp8,
            children: paper.sections.map((section) {
              return FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primarySoft,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.sp12,
                    vertical: AppTheme.sp8,
                  ),
                ),
                icon: const Icon(Icons.document_scanner_rounded, size: 18),
                label: Text('${l10n.scanOMR} ($section)'),
                onPressed: () => _handleScanForSection(context, section),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _handleScanForSection(
    BuildContext context,
    String section,
  ) async {
    String? selectedSetId;

    if (paper.hasMultipleSets) {
      selectedSetId = await _showSetPickerDialog(context);
      if (selectedSetId == null) return;
    } else {
      selectedSetId = paper.sets.first.id;
    }

    if (context.mounted) {
      final path =
          '${AppRoutes.scanSessionPath(examId, subjectId, paper.id)}?section=$section&setId=$selectedSetId';
      await context.push(path);
      onRefresh();
    }
  }

  Future<String?> _showSetPickerDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.selectSet, style: AppTextStyles.headlineSmall()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: paper.sets.map((s) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                s.hasKey ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: s.hasKey ? AppColors.correct : AppColors.skipped,
              ),
              title: Text(
                l10n.setLabel(s.setLabel),
                style: AppTextStyles.titleMedium(),
              ),
              subtitle: Text(
                s.hasKey ? l10n.answerKeyAdded : l10n.answerKeyMissing,
                style: AppTextStyles.bodySmall(),
              ),
              onTap: () => Navigator.of(ctx).pop(s.id),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }
}
