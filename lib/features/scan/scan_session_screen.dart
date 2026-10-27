import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:omr_scanner/app/router.dart';
import 'package:omr_scanner/data/local_repository.dart';
import 'package:omr_scanner/features/scan/result_card.dart';
import 'package:omr_scanner/features/scan/session_summary_screen.dart';
import 'package:omr_scanner/l10n/app_localizations.dart';
import 'package:omr_scanner/logic/scoring.dart';
import 'package:omr_scanner/models/exam.dart';
import 'package:omr_scanner/services/scan_service.dart';
import 'package:omr_scanner/theme/app_colors.dart';
import 'package:omr_scanner/theme/app_text.dart';
import 'package:omr_scanner/theme/app_theme.dart';
import 'package:omr_scanner/widgets/empty_state.dart';

/// Screen for running an active OMR scan session on an exam paper.
class ScanSessionScreen extends StatefulWidget {
  final String examId;
  final String subjectId;
  final String paperId;
  final String initialSection;
  final String? initialSetId;

  const ScanSessionScreen({
    super.key,
    required this.examId,
    required this.subjectId,
    required this.paperId,
    required this.initialSection,
    this.initialSetId,
  });

  @override
  State<ScanSessionScreen> createState() => _ScanSessionScreenState();
}

class _ScanSessionScreenState extends State<ScanSessionScreen> {
  Exam? _exam;
  Subject? _subject;
  Paper? _paper;
  ScanSession? _session;

  late String _currentSection;
  String? _currentSetId;

  bool _loading = true;
  bool _scanning = false;
  SheetResult? _currentResult;

  @override
  void initState() {
    super.initState();
    _currentSection = widget.initialSection;
    _currentSetId = widget.initialSetId;
    _loadData();
  }

  AnswerSet? get _currentSet {
    final sets = _paper?.sets;
    if (sets == null || sets.isEmpty) return null;
    return sets.firstWhere(
      (s) => s.id == _currentSetId,
      orElse: () => sets.first,
    );
  }

  Future<void> _loadData() async {
    final repo = context.read<LocalRepository>();
    final exam = await repo.loadExam(widget.examId);
    if (!mounted) return;

    Subject? foundSubject;
    Paper? foundPaper;

    if (exam != null) {
      try {
        foundSubject =
            exam.subjects.firstWhere((s) => s.id == widget.subjectId);
        foundPaper = foundSubject.papers.firstWhere((p) => p.id == widget.paperId);
      } catch (_) {
        foundSubject = null;
        foundPaper = null;
      }
    }

    if (foundPaper != null) {
      if (_currentSetId == null ||
          !foundPaper.sets.any((s) => s.id == _currentSetId)) {
        _currentSetId = foundPaper.sets.first.id;
      }

      final sessions = await repo.loadSessionsForPaper(widget.paperId);
      final matching = sessions.where(
        (s) => s.section == _currentSection && s.setId == _currentSetId,
      );

      if (matching.isNotEmpty) {
        _session = matching.first;
      } else {
        _session = ScanSession(
          paperId: widget.paperId,
          section: _currentSection,
          setId: _currentSetId!,
        );
      }
    }

    setState(() {
      _exam = exam;
      _subject = foundSubject;
      _paper = foundPaper;
      _loading = false;
    });
  }

  Future<void> _switchSet(String newSetId) async {
    if (_currentSetId == newSetId) return;

    final repo = context.read<LocalRepository>();
    if (_session != null && _session!.results.isNotEmpty) {
      await repo.saveSession(_session!);
    }

    final newSet = _paper?.sets.firstWhere((s) => s.id == newSetId);

    setState(() {
      _currentSetId = newSetId;
      _currentResult = null;
    });

    final sessions = await repo.loadSessionsForPaper(widget.paperId);
    final matching = sessions.where(
      (s) => s.section == _currentSection && s.setId == newSetId,
    );

    setState(() {
      if (matching.isNotEmpty) {
        _session = matching.first;
      } else {
        _session = ScanSession(
          paperId: widget.paperId,
          section: _currentSection,
          setId: newSetId,
        );
      }
    });

    if (mounted && newSet != null) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.nowScanningSet(newSet.setLabel)),
          duration: const Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _startScan() async {
    final paper = _paper;
    final currentSet = _currentSet;
    if (paper == null || currentSet == null || currentSet.answerKey == null) {
      return;
    }

    setState(() {
      _scanning = true;
    });

    final scanService = context.read<ScanService>();
    final answers = await scanService.scanSheet(
      context,
      questionCount: paper.questionCount,
    );

    if (!mounted) return;

    if (answers == null) {
      setState(() {
        _scanning = false;
      });
      return;
    }

    final scoreResult = score(
      answers,
      currentSet.answerKey!,
      marksPerCorrect: paper.marksPerCorrect,
      negativeMarking: paper.negativeMarking,
      negativeValue: paper.negativeValue,
    );

    final currentSheetNumber = (_session?.results.length ?? 0) + 1;

    final sheetResult = SheetResult(
      sheetNumber: currentSheetNumber,
      correct: scoreResult.correct,
      wrong: scoreResult.wrong,
      skipped: scoreResult.skipped,
      marks: scoreResult.marks,
      answers: answers,
      scannedAt: DateTime.now(),
    );

    setState(() {
      _currentResult = sheetResult;
      _scanning = false;
    });
  }

  Future<void> _handleNextSheet() async {
    final res = _currentResult;
    final session = _session;
    if (res == null || session == null) return;

    session.results.add(res);

    final repo = context.read<LocalRepository>();
    await repo.saveSession(session);

    if (!mounted) return;
    setState(() {
      _currentResult = null;
    });
  }

  void _handleRescan() {
    setState(() {
      _currentResult = null;
    });
    _startScan();
  }

  Future<void> _finishSession() async {
    final session = _session;
    final repo = context.read<LocalRepository>();

    if (session != null && session.results.isNotEmpty) {
      await repo.saveSession(session);
    }

    if (!mounted) return;

    if (session == null || session.results.isEmpty) {
      context.pop();
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SessionSummaryScreen(
          results: List.from(session.results),
          questionCount: _paper?.questionCount ?? 50,
          isQuickScan: false,
          sessionId: session.id,
        ),
      ),
    );

    _loadData();
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

    final paper = _paper;
    final subject = _subject;
    final exam = _exam;

    if (paper == null || subject == null || exam == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.scanOMR)),
        body: Center(
          child: EmptyState(
            icon: Icons.error_outline,
            title: 'Paper not found',
            actionLabel: l10n.back,
            onAction: () => context.pop(),
          ),
        ),
      );
    }

    final currentSet = _currentSet;
    final hasKey = currentSet?.hasKey ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${subject.name} · ${l10n.classLabel(paper.classNumber)}-$_currentSection',
              style: AppTextStyles.titleLarge(),
            ),
            Text(
              exam.name,
              style: AppTextStyles.bodySmall(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _finishSession,
            child: Text(
              l10n.finish,
              style: AppTextStyles.titleMedium(color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Set switcher if multiple sets exist
            if (paper.hasMultipleSets)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.sp16,
                  vertical: AppTheme.sp8,
                ),
                color: AppColors.surface,
                child: Row(
                  children: [
                    Text(l10n.set_, style: AppTextStyles.labelMedium()),
                    const SizedBox(width: AppTheme.sp12),
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: paper.sets.map((s) {
                          return ButtonSegment<String>(
                            value: s.id,
                            label: Text(s.setLabel),
                          );
                        }).toList(),
                        selected: {_currentSetId ?? paper.sets.first.id},
                        onSelectionChanged: (val) {
                          _switchSet(val.first);
                        },
                      ),
                    ),
                  ],
                ),
              ),

            // Main body area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.sp16),
                child: _buildBody(l10n, paper, currentSet, hasKey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    AppLocalizations l10n,
    Paper paper,
    AnswerSet? currentSet,
    bool hasKey,
  ) {
    if (!hasKey && currentSet != null) {
      return Center(
        child: EmptyState(
          icon: Icons.vpn_key_outlined,
          title: l10n.noAnswerKey,
          subtitle: l10n.addAnswerKeyFirst,
          actionLabel: l10n.addAnswerKey,
          onAction: () async {
            await context.push(
              AppRoutes.answerKeyPath(
                widget.examId,
                widget.subjectId,
                widget.paperId,
                currentSet.id,
              ),
            );
            _loadData();
          },
        ),
      );
    }

    if (_scanning) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                minHeight: 6,
                backgroundColor: AppColors.primarySoft,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: AppTheme.sp20),
            Text(l10n.checking, style: AppTextStyles.headlineSmall()),
          ],
        ),
      );
    }

    if (_currentResult != null && currentSet != null) {
      return SingleChildScrollView(
        child: ResultCard(
          result: _currentResult!,
          questionCount: paper.questionCount,
          answerKey: currentSet.answerKey!,
          negativeMarking: paper.negativeMarking,
          marksPerCorrect: paper.marksPerCorrect,
          negativeValue: paper.negativeValue,
          onNextSheet: _handleNextSheet,
          onRescan: _handleRescan,
        ),
      );
    }

    // Ready to scan state
    final sheetNum = (_session?.results.length ?? 0) + 1;
    final totalScanned = _session?.results.length ?? 0;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.sheetNumber(sheetNum),
            style: AppTextStyles.headlineMedium(),
          ),
          const SizedBox(height: AppTheme.sp8),
          Text(
            l10n.sheetsChecked(totalScanned),
            style: AppTextStyles.bodyMedium(),
          ),
          const SizedBox(height: AppTheme.sp32),

          // Big circular pulsing scan button
          GestureDetector(
            onTap: _startScan,
            child: Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x3312A07A),
                    blurRadius: 18,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 40,
              ),
            )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.06, 1.06),
                  duration: 900.ms,
                  curve: Curves.easeInOut,
                ),
          ),

          const SizedBox(height: AppTheme.sp20),
          TextButton.icon(
            icon: const Icon(Icons.photo_library_outlined, size: 18),
            label: Text(l10n.gallery),
            onPressed: _startScan,
          ),
        ],
      ),
    );
  }
}
