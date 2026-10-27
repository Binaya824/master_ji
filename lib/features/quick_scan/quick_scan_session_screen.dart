import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
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
import 'package:omr_scanner/services/scan_service.dart';
import 'package:omr_scanner/theme/app_colors.dart';
import 'package:omr_scanner/theme/app_text.dart';
import 'package:omr_scanner/theme/app_theme.dart';
import 'package:omr_scanner/widgets/app_card.dart';
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

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final repo = context.read<LocalRepository>();
    final state = await repo.loadQuickScan();
    if (!mounted) return;

    setState(() {
      _state = state;
      _loading = false;
    });
  }

  int get _nextSheetNumber {
    final results = _state?.results ?? [];
    if (results.isEmpty) return 1;
    return results.map((r) => r.sheetNumber).reduce((a, b) => a > b ? a : b) + 1;
  }

  Future<void> _handleScan() async {
    final state = _state;
    final account = context.read<AccountState>();

    if (!account.canQuickScan) {
      await PremiumSheet.show(context);
      return;
    }

    if (state == null || state.answerKey == null) {
      context.go(AppRoutes.quickScanKey);
      return;
    }

    setState(() {
      _scanning = true;
    });

    final scanService = context.read<ScanService>();
    final answers = await scanService.scanSheet(
      context,
      questionCount: state.questionCount,
    );

    if (!mounted) return;

    if (answers != null) {
      final scoreResult = score(
        answers,
        state.answerKey!,
        marksPerCorrect: state.marksPerCorrect,
        negativeMarking: state.negativeMarking,
        negativeValue: state.negativeValue,
      );

      final sheetResult = SheetResult(
        sheetNumber: _nextSheetNumber,
        correct: scoreResult.correct,
        wrong: scoreResult.wrong,
        skipped: scoreResult.skipped,
        marks: scoreResult.marks,
        answers: answers,
        scannedAt: DateTime.now(),
      );

      setState(() {
        _scanning = false;
        _pendingResult = sheetResult;
      });
    } else {
      setState(() {
        _scanning = false;
      });
    }
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
    });
  }

  void _handleRescanThisSheet() {
    setState(() {
      _pendingResult = null;
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
          questionCount: state.questionCount,
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
        appBar: AppBar(title: Text(l10n.quickScan)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final state = _state;
    if (state == null || state.answerKey == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.quickScan)),
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
              onTap: _handleScan,
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
              onPressed: _handleScan,
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
                        '${formatMarks(r.marks)} / ${state.questionCount}',
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.sp16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                      '${formatMarks(value)} / ${state.questionCount}',
                      style: AppTextStyles.numberHuge(
                        color: AppColors.primary,
                      ),
                    );
                  },
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

                // Negative marking formula
                if (state.negativeMarking) ...[
                  const SizedBox(height: AppTheme.sp12),
                  Text(
                    l10n.scoreFormula(
                      result.correct,
                      formatMarks(state.marksPerCorrect),
                      result.wrong,
                      formatMarks(state.negativeValue),
                      formatMarks(result.marks),
                    ),
                    style: AppTextStyles.bodySmall(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],

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
                        questionCount: state.questionCount,
                        studentAnswers: result.answers,
                        answerKey: state.answerKey,
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
