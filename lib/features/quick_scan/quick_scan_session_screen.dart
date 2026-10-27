import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:omr_scanner/app/router.dart';
import 'package:omr_scanner/data/account_state.dart';
import 'package:omr_scanner/data/local_repository.dart';
import 'package:omr_scanner/features/answer_key/answer_grid.dart';
import 'package:omr_scanner/features/premium/premium_sheet.dart';
import 'package:omr_scanner/features/scan/session_summary_screen.dart';
import 'package:omr_scanner/l10n/app_localizations.dart';
import 'package:omr_scanner/logic/scoring.dart';
import 'package:omr_scanner/models/exam.dart';
import 'package:omr_scanner/models/quick_scan_state.dart';
import 'package:omr_scanner/services/omr_service.dart';
import 'package:omr_scanner/services/scan_service.dart';
import 'package:omr_scanner/services/storage_service.dart';
import 'package:omr_scanner/theme/app_colors.dart';
import 'package:omr_scanner/theme/app_text.dart';
import 'package:omr_scanner/theme/app_theme.dart';
import 'package:omr_scanner/widgets/app_card.dart';
import 'package:omr_scanner/widgets/image_source_sheet.dart';
import 'package:omr_scanner/widgets/primary_button.dart';
import 'package:omr_scanner/widgets/stat_pill.dart';

/// Screen for scanning student OMR sheets during a Quick Scan session.
class QuickScanSessionScreen extends StatefulWidget {
  const QuickScanSessionScreen({super.key});

  @override
  State<QuickScanSessionScreen> createState() => _QuickScanSessionScreenState();
}

class _QuickScanSessionScreenState extends State<QuickScanSessionScreen> {
  bool _loading = true;
  bool _scanning = false;
  QuickScanState? _state;
  SheetResult? _pendingResult;
  Uint8List? _scannedImageBytes;
  Map<int, int> _fullAnswerKey = {};
  Map<int, int> _nonZeroAnswerKey = {};
  int _totalAnswerKeyQuestions = 0;
  String _calculationExplanation = '';

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final repo = context.read<LocalRepository>();
    var state = await repo.loadQuickScan();

    // Ensure full answer key is loaded from local storage (including zero values)
    Map<String, int> storedKey = await StorageService.loadAnswerKeyResults() ?? {};
    if (storedKey.isEmpty && state?.answerKey != null && state!.answerKey!.isNotEmpty) {
      storedKey = state!.answerKey!.map((k, v) => MapEntry('$k', v));
    }

    final fullKey = <int, int>{};
    final nonZeroKey = <int, int>{};
    storedKey.forEach((k, v) {
      final q = int.tryParse(k);
      if (q != null) {
        fullKey[q] = v;
        if (v > 0) nonZeroKey[q] = v;
      }
    });

    // Exact length of the answer key json (including zero values)
    final totalActual = fullKey.isNotEmpty ? fullKey.length : (state?.questionCount ?? 50);

    if (state != null) {
      state = state.copyWith(
        answerKey: fullKey.isNotEmpty ? fullKey : state.answerKey,
        questionCount: totalActual,
      );
      await repo.saveQuickScan(state);
    }

    if (!mounted) return;

    setState(() {
      _state = state;
      _fullAnswerKey = fullKey;
      _nonZeroAnswerKey = nonZeroKey;
      _totalAnswerKeyQuestions = totalActual;
      _loading = false;
    });
  }

  int get _nextSheetNumber {
    final results = _state?.results ?? [];
    if (results.isEmpty) return 1;
    return results.map((r) => r.sheetNumber).reduce((a, b) => a > b ? a : b) + 1;
  }

  Future<void> _handleScan({ImageSource? source}) async {
    final state = _state;
    final account = context.read<AccountState>();

    if (!account.canQuickScan) {
      await PremiumSheet.show(context);
      return;
    }

    // Load full answer key json from StorageService or state (including zero values)
    Map<String, int> storedKey = await StorageService.loadAnswerKeyResults() ?? {};
    if (storedKey.isEmpty && state?.answerKey != null && state!.answerKey!.isNotEmpty) {
      storedKey = state!.answerKey!.map((k, v) => MapEntry('$k', v));
    }

    final fullKey = <int, int>{};
    final nonZeroKey = <String, int>{};
    storedKey.forEach((k, v) {
      final q = int.tryParse(k);
      if (q != null) {
        fullKey[q] = v;
        if (v > 0) nonZeroKey[k] = v;
      }
    });

    if (storedKey.isEmpty && (state?.answerKey == null || state!.answerKey!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please scan or set an answer key first.')),
      );
      context.go(AppRoutes.quickScanKey);
      return;
    }

    final picked = await pickImageFromSource(
      context,
      directSource: source,
      title: 'Scan Student Sheet',
    );
    if (picked == null) return;

    setState(() {
      _scanning = true;
    });

    try {
      final omrResult = await OmrService.process(picked);

      // Exact length of the answer key json, even though they have zero values
      final totalQuestions = fullKey.isNotEmpty
          ? fullKey.length
          : (storedKey.isNotEmpty ? storedKey.length : (state?.questionCount ?? 50));

      // Correct answer: first drop all the zero values keys from the output json
      // and compare the rest keys value with answer key find how many matched.
      final nonZeroOutput = Map<String, int>.fromEntries(
        omrResult.results.entries.where((e) => e.value > 0),
      );

      int correctCount = 0;
      int wrongCount = 0;

      for (final entry in nonZeroOutput.entries) {
        final expected = nonZeroKey[entry.key];
        if (expected != null && expected == entry.value) {
          correctCount++;
        } else {
          wrongCount++;
        }
      }

      // Skipped: subtract the length of the non-zero output json from the exact length of the answer key json
      final skippedCount = math.max(0, totalQuestions - nonZeroOutput.length);

      // Marks calculation
      final marksPerCorrect = state?.marksPerCorrect ?? 1.0;
      final isNegative = state?.negativeMarking ?? false;
      final negativeVal = isNegative ? (state?.negativeValue ?? 0.0) : 0.0;

      final earnedMarks = correctCount * marksPerCorrect;
      final penaltyMarks = wrongCount * negativeVal;
      final rawMarks = earnedMarks - penaltyMarks;
      final finalMarks = math.max(0.0, rawMarks);

      // Calculation explanation string
      final String explanation;
      if (isNegative && negativeVal > 0) {
        explanation =
            '• Correct Marks: $correctCount × ${formatMarks(marksPerCorrect)} = +${formatMarks(earnedMarks)}\n'
            '• Negative Penalty: $wrongCount × ${formatMarks(negativeVal)} = -${formatMarks(penaltyMarks)}\n'
            '• Final Marks: ${formatMarks(earnedMarks)} - ${formatMarks(penaltyMarks)} = ${formatMarks(finalMarks)}'
            '${rawMarks < 0 ? ' (clamped to 0)' : ''}';
      } else {
        explanation =
            '• Correct Marks: $correctCount × ${formatMarks(marksPerCorrect)} = ${formatMarks(finalMarks)}\n'
            '• Wrong: $wrongCount (negative marking disabled)';
      }

      final studentAnswersIntMap = <int, int>{};
      omrResult.results.forEach((k, v) {
        final q = int.tryParse(k);
        if (q != null) studentAnswersIntMap[q] = v;
      });

      final sheetResult = SheetResult(
        sheetNumber: _nextSheetNumber,
        correct: correctCount,
        wrong: wrongCount,
        skipped: skippedCount,
        marks: finalMarks,
        answers: studentAnswersIntMap,
        scannedAt: DateTime.now(),
      );

      final updatedState = (state ??
              QuickScanState(
                questionCount: totalQuestions,
                marksPerCorrect: marksPerCorrect,
                negativeMarking: isNegative,
                negativeValue: negativeVal,
                results: const [],
              ))
          .copyWith(
        questionCount: totalQuestions,
        answerKey: fullKey,
      );

      final repo = context.read<LocalRepository>();
      await repo.saveQuickScan(updatedState);

      if (!mounted) return;

      setState(() {
        _scanning = false;
        _pendingResult = sheetResult;
        _scannedImageBytes = omrResult.imageBytes;
        _fullAnswerKey = fullKey;
        _nonZeroAnswerKey = nonZeroKey.map((k, v) => MapEntry(int.parse(k), v));
        _totalAnswerKeyQuestions = totalQuestions;
        _calculationExplanation = explanation;
        _state = updatedState;
      });
    } catch (e) {
      debugPrint('Error scanning OMR sheet: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to process OMR sheet: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppColors.wrong,
          duration: const Duration(seconds: 4),
        ),
      );
      setState(() {
        _scanning = false;
      });
    }
  }

  void _showImagePreviewDialog(Uint8List bytes) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Scanned Sheet Preview'),
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.textPrimary,
                elevation: 0,
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Flexible(
                child: InteractiveViewer(
                  maxScale: 5.0,
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleNextSheet() async {
    final state = _state;
    final pending = _pendingResult;
    if (state == null || pending == null) return;

    final updatedResults = List<SheetResult>.from(state.results)..add(pending);
    final updatedState = state.copyWith(results: updatedResults);

    final repo = context.read<LocalRepository>();
    await repo.saveQuickScan(updatedState);

    final account = context.read<AccountState>();
    await account.decrementFreeScan();

    if (!mounted) return;

    setState(() {
      _state = updatedState;
      _pendingResult = null;
      _scannedImageBytes = null;
    });
  }

  void _handleRescanThisSheet() {
    setState(() {
      _pendingResult = null;
      _scannedImageBytes = null;
    });
    _handleScan();
  }

  void _handleFinish() {
    final state = _state;
    if (state == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SessionSummaryScreen(
          results: state.results,
          questionCount: _totalAnswerKeyQuestions > 0 ? _totalAnswerKeyQuestions : state.questionCount,
          isQuickScan: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final account = context.watch<AccountState>();

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.quickScan),
          leading: BackButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.quickScanKey);
              }
            },
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final state = _state;
    if (state == null || (state.answerKey == null && _nonZeroAnswerKey.isEmpty)) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.quickScan),
          leading: BackButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.quickScanKey);
              }
            },
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.noAnswerKey, style: AppTextStyles.headlineSmall()),
              const SizedBox(height: AppTheme.sp16),
              PrimaryButton(
                label: l10n.scanAnswerKey,
                onPressed: () => context.go(AppRoutes.quickScanKey),
              ),
            ],
          ),
        ),
      );
    }

    final isLimitReached = !account.isPremium && account.freeScansLeft <= 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.quickScan),
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.quickScanKey);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: (state.results.isNotEmpty || _pendingResult != null)
                ? _handleFinish
                : null,
            child: Text(
              l10n.finish,
              style: TextStyle(
                color: (state.results.isNotEmpty || _pendingResult != null)
                    ? AppColors.primary
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Banner if not premium
            if (!account.isPremium) _buildFreeScansBanner(l10n, account),

            // Scanning progress indicator
            if (_scanning) const LinearProgressIndicator(),

            // Main Content Area
            Expanded(
              child: _scanning
                  ? Center(
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
                    )
                  : _pendingResult != null
                      ? _buildResultCard(l10n, state, _pendingResult!)
                      : isLimitReached
                          ? _buildLimitReachedView(l10n, state)
                          : _buildScanPromptView(l10n, state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFreeScansBanner(AppLocalizations l10n, AccountState account) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.sp16,
        vertical: AppTheme.sp8,
      ),
      color: AppColors.accent.withValues(alpha: 0.15),
      child: Row(
        children: [
          const Icon(
            Icons.bolt_rounded,
            size: 18,
            color: Color(0xFFD68000),
          ),
          const SizedBox(width: AppTheme.sp8),
          Text(
            l10n.freeScansLeft(account.freeScansLeft),
            style: AppTextStyles.labelMedium(
              color: const Color(0xFF8F5300),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => PremiumSheet.show(context),
            child: Text(
              l10n.goPremium,
              style: AppTextStyles.labelMedium(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanPromptView(AppLocalizations l10n, QuickScanState state) {
    final nextNum = _nextSheetNumber;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.sp24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.sheetNumber(nextNum),
              style: AppTextStyles.headlineMedium(),
            ),
            const SizedBox(height: AppTheme.sp32),
            GestureDetector(
              onTap: () => _handleScan(),
              child: Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x3312A07A),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 44,
                  color: Colors.white,
                ),
              ),
            )
                .animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                )
                .scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.08, 1.08),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeInOut,
                ),
            const SizedBox(height: AppTheme.sp24),
            TextButton.icon(
              onPressed: () => _handleScan(source: ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: Text(l10n.gallery),
            ),
            if (state.results.isNotEmpty) ...[
              const SizedBox(height: AppTheme.sp32),
              Text(
                l10n.sheetsChecked(state.results.length),
                style: AppTextStyles.bodyMedium(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLimitReachedView(AppLocalizations l10n, QuickScanState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.sp24),
      child: Column(
        children: [
          AppCard(
            color: const Color(0xFFFFF3D6),
            borderColor: AppColors.accent,
            child: Column(
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 40,
                  color: Color(0xFFB87000),
                ),
                const SizedBox(height: AppTheme.sp12),
                Text(
                  l10n.used20Scans,
                  style: AppTextStyles.bodyMedium(
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.sp16),
                PrimaryButton(
                  label: l10n.goPremium,
                  onPressed: () => PremiumSheet.show(context),
                ),
              ],
            ),
          ),
          if (state.results.isNotEmpty) ...[
            const SizedBox(height: AppTheme.sp24),
            Text(
              l10n.sheetsChecked(state.results.length),
              style: AppTextStyles.titleLarge(),
            ),
            const SizedBox(height: AppTheme.sp12),
            ...state.results.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.sp8),
                child: AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.sp16,
                    vertical: AppTheme.sp12,
                  ),
                  child: Row(
                    children: [
                      Text(
                        l10n.sheetNumber(r.sheetNumber),
                        style: AppTextStyles.titleMedium(),
                      ),
                      const Spacer(),
                      Text(
                        '${formatMarks(r.marks)} / ${_totalAnswerKeyQuestions > 0 ? formatMarks(_totalAnswerKeyQuestions * state.marksPerCorrect) : formatMarks(state.questionCount * state.marksPerCorrect)}',
                        style: AppTextStyles.titleMedium(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultCard(
    AppLocalizations l10n,
    QuickScanState state,
    SheetResult result,
  ) {
    final totalQ = _totalAnswerKeyQuestions > 0 ? _totalAnswerKeyQuestions : state.questionCount;
    final maxMarks = totalQ * state.marksPerCorrect;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.sp16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Scanned Image Preview Card
          if (_scannedImageBytes != null) ...[
            AppCard(
              padding: const EdgeInsets.all(AppTheme.sp12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.image_outlined, size: 20, color: AppColors.primary),
                      const SizedBox(width: AppTheme.sp8),
                      Text('Scanned Sheet Preview', style: AppTextStyles.titleMedium()),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.fullscreen_rounded),
                        tooltip: 'View Fullscreen',
                        onPressed: () => _showImagePreviewDialog(_scannedImageBytes!),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.sp8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                    child: GestureDetector(
                      onTap: () => _showImagePreviewDialog(_scannedImageBytes!),
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 220),
                        width: double.infinity,
                        color: Colors.black12,
                        child: Image.memory(
                          _scannedImageBytes!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.sp16),
          ],

          // 2. Marks and Scoring Summary Card
          AppCard(
            child: Column(
              children: [
                Text(
                  l10n.sheetNumber(result.sheetNumber),
                  style: AppTextStyles.titleMedium(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppTheme.sp8),

                // Animated marks counter
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: result.marks),
                  duration: const Duration(milliseconds: 600),
                  builder: (context, value, child) {
                    return Text(
                      '${formatMarks(value)} / ${formatMarks(maxMarks)}',
                      style: AppTextStyles.numberHuge(
                        color: AppColors.primary,
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppTheme.sp4),
                Text(
                  'Total Questions: $totalQ',
                  style: AppTextStyles.bodySmall(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppTheme.sp16),

                // Stat Pills
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    StatPill.correct(count: result.correct),
                    const SizedBox(width: AppTheme.sp8),
                    StatPill.wrong(count: result.wrong),
                    const SizedBox(width: AppTheme.sp8),
                    StatPill.skipped(count: result.skipped),
                  ],
                ),

                const SizedBox(height: AppTheme.sp16),
                const Divider(),

                // Detailed Marks Calculation
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.sp12),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(color: AppColors.primarySoft),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calculate_outlined, size: 18, color: AppColors.primary),
                          const SizedBox(width: AppTheme.sp8),
                          Text('Marks Calculation', style: AppTextStyles.titleMedium(color: AppColors.primary)),
                        ],
                      ),
                      const SizedBox(height: AppTheme.sp8),
                      Text(
                        _calculationExplanation,
                        style: AppTextStyles.bodySmall(color: AppColors.textPrimary).copyWith(height: 1.5),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppTheme.sp16),
                const Divider(),

                // Expansion tile for review
                ExpansionTile(
                  title: Text(
                    l10n.seeAnswers,
                    style: AppTextStyles.titleMedium(
                      color: AppColors.primary,
                    ),
                  ),
                  children: [
                    SizedBox(
                      height: 320,
                      child: AnswerGrid.review(
                        questionCount: totalQ,
                        studentAnswers: result.answers,
                        answerKey: _fullAnswerKey.isNotEmpty ? _fullAnswerKey : (_nonZeroAnswerKey.isNotEmpty ? _nonZeroAnswerKey : state.answerKey),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
              .animate()
              .slideY(
                begin: 0.2,
                end: 0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              )
              .fadeIn(duration: const Duration(milliseconds: 250)),
          const SizedBox(height: AppTheme.sp16),

          // Action buttons
          PrimaryButton(
            label: l10n.nextSheet,
            onPressed: _handleNextSheet,
          ),
          const SizedBox(height: AppTheme.sp8),
          TextButton(
            onPressed: _handleRescanThisSheet,
            child: Text(
              l10n.rescanThisSheet,
              style: const TextStyle(color: AppColors.wrong),
            ),
          ),
        ],
      ),
    );
  }
}
