import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:omr_scanner/data/local_repository.dart';
import 'package:omr_scanner/l10n/app_localizations.dart';
import 'package:omr_scanner/models/exam.dart';
import 'package:omr_scanner/services/scan_service.dart';
import 'package:omr_scanner/services/storage_service.dart';
import 'package:omr_scanner/theme/app_colors.dart';
import 'package:omr_scanner/theme/app_text.dart';
import 'package:omr_scanner/theme/app_theme.dart';
import 'package:omr_scanner/widgets/primary_button.dart';

import 'answer_grid.dart';

enum _KeyScreenState { initial, scanning, reviewing }

/// Screen for adding or editing an answer key for one AnswerSet of a Paper.
class AnswerKeyScreen extends StatefulWidget {
  final String examId;
  final String subjectId;
  final String paperId;
  final String setId;

  const AnswerKeyScreen({
    super.key,
    required this.examId,
    required this.subjectId,
    required this.paperId,
    required this.setId,
  });

  @override
  State<AnswerKeyScreen> createState() => _AnswerKeyScreenState();
}

class _AnswerKeyScreenState extends State<AnswerKeyScreen> {
  bool _loading = true;
  Exam? _exam;
  Subject? _subject;
  Paper? _paper;
  AnswerSet? _answerSet;

  _KeyScreenState _screenState = _KeyScreenState.initial;
  Map<int, int> _answers = {};

  @override
  void initState() {
    super.initState();
    _loadExamData();
  }

  Future<void> _loadExamData() async {
    final repo = context.read<LocalRepository>();
    final exam = await repo.loadExam(widget.examId);
    if (!mounted) return;

    if (exam != null) {
      Subject? foundSubject;
      Paper? foundPaper;
      AnswerSet? foundSet;

      for (final s in exam.subjects) {
        if (s.id == widget.subjectId) {
          foundSubject = s;
          for (final p in s.papers) {
            if (p.id == widget.paperId) {
              foundPaper = p;
              for (final aSet in p.sets) {
                if (aSet.id == widget.setId) {
                  foundSet = aSet;
                  break;
                }
              }
              break;
            }
          }
          break;
        }
      }

      setState(() {
        _exam = exam;
        _subject = foundSubject;
        _paper = foundPaper;
        _answerSet = foundSet;
        _loading = false;

        if (foundSet?.answerKey != null && foundSet!.answerKey!.isNotEmpty) {
          _answers = Map<int, int>.from(foundSet.answerKey!);
          _screenState = _KeyScreenState.reviewing;
        } else {
          _screenState = _KeyScreenState.initial;
        }
      });
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _handleScan() async {
    final paper = _paper;
    if (paper == null) return;

    setState(() {
      _screenState = _KeyScreenState.scanning;
    });

    final scanService = context.read<ScanService>();
    final scannedAnswers = await scanService.scanSheet(
      context,
      questionCount: paper.questionCount,
    );

    if (!mounted) return;

    if (scannedAnswers != null) {
      setState(() {
        _answers = Map<int, int>.from(scannedAnswers);
        _screenState = _KeyScreenState.reviewing;
      });
    } else {
      // User cancelled or scan failed, return to previous state
      setState(() {
        _screenState =
            _answers.isNotEmpty ? _KeyScreenState.reviewing : _KeyScreenState.initial;
      });
    }
  }

  void _handleEnterManually() {
    setState(() {
      _screenState = _KeyScreenState.reviewing;
    });
  }

  Future<void> _handleSave() async {
    final exam = _exam;
    final answerSet = _answerSet;
    final paper = _paper;
    if (exam == null || answerSet == null || paper == null) return;

    final l10n = AppLocalizations.of(context);

    // Update set with filled answers
    answerSet.answerKey = Map<int, int>.from(_answers);

    final repo = context.read<LocalRepository>();
    await repo.saveExam(exam);
    await StorageService.saveAnswersJson(_answers, total: paper.questionCount);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.answerKeyAdded),
      ),
    );

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.scanAnswerKey)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_exam == null || _paper == null || _answerSet == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.scanAnswerKey)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.noAnswerKey, style: AppTextStyles.headlineSmall()),
              const SizedBox(height: AppTheme.sp16),
              PrimaryButton(
                label: l10n.back,
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ),
      );
    }

    final totalQuestions = _paper!.questionCount;
    final filledCount = _answers.values.where((v) => v > 0).length;
    final isAllFilled = filledCount == totalQuestions;
    final setLabelText = l10n.setLabel(_answerSet!.setLabel);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$setLabelText – ${l10n.addAnswerKey}',
              style: AppTextStyles.headlineSmall(),
            ),
            Text(
              l10n.filledCount(filledCount, totalQuestions),
              style: AppTextStyles.labelMedium(
                color: isAllFilled ? AppColors.correct : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top action buttons
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.sp16,
                vertical: AppTheme.sp12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _screenState == _KeyScreenState.scanning
                          ? null
                          : _handleScan,
                      icon: const Icon(Icons.document_scanner_rounded, size: 20),
                      label: Text(l10n.scanAnswerKey),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.sp12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusButton),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.sp12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _screenState == _KeyScreenState.scanning
                          ? null
                          : _handleEnterManually,
                      icon: const Icon(Icons.edit_note_rounded, size: 20),
                      label: Text(l10n.enterManually),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.sp12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusButton),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main body area based on state
            Expanded(
              child: switch (_screenState) {
                _KeyScreenState.scanning => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: AppTheme.sp16),
                        Text(
                          l10n.checking,
                          style: AppTextStyles.titleMedium(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                _KeyScreenState.initial => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.sp24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              color: AppColors.primarySoft,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.fact_check_outlined,
                              size: 40,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: AppTheme.sp16),
                          Text(
                            l10n.addAnswerKeyFirst,
                            style: AppTextStyles.titleLarge(),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppTheme.sp8),
                          Text(
                            l10n.quickScanSubtitle,
                            style: AppTextStyles.bodyMedium(),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                _KeyScreenState.reviewing => AnswerGrid.edit(
                    key: ValueKey('grid_$totalQuestions'),
                    questionCount: totalQuestions,
                    initialAnswers: _answers,
                    onChanged: (updated) {
                      setState(() {
                        _answers = updated;
                      });
                    },
                  ),
              },
            ),

            // Bottom sticky Save button
            Container(
              padding: const EdgeInsets.all(AppTheme.sp16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.divider, width: 1),
                ),
              ),
              child: PrimaryButton(
                label: l10n.save,
                onPressed: isAllFilled ? _handleSave : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
