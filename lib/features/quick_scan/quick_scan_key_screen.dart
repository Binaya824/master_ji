import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:omr_scanner/app/router.dart';
import 'package:omr_scanner/data/local_repository.dart';
import 'package:omr_scanner/features/answer_key/answer_grid.dart';
import 'package:omr_scanner/l10n/app_localizations.dart';
import 'package:omr_scanner/models/quick_scan_state.dart';
import 'package:omr_scanner/services/scan_service.dart';
import 'package:omr_scanner/theme/app_colors.dart';
import 'package:omr_scanner/theme/app_text.dart';
import 'package:omr_scanner/theme/app_theme.dart';
import 'package:omr_scanner/widgets/primary_button.dart';

/// Screen for scanning or manually entering the answer key for Quick Scan.
class QuickScanKeyScreen extends StatefulWidget {
  const QuickScanKeyScreen({super.key});

  @override
  State<QuickScanKeyScreen> createState() => _QuickScanKeyScreenState();
}

class _QuickScanKeyScreenState extends State<QuickScanKeyScreen> {
  bool _loading = true;
  bool _scanning = false;
  bool _editingGrid = false;
  QuickScanState? _state;
  Map<int, int> _answers = {};

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
      if (state?.answerKey != null && state!.answerKey!.isNotEmpty) {
        _answers = Map<int, int>.from(state.answerKey!);
        _editingGrid = true;
      }
    });
  }

  Future<void> _handleScan() async {
    final state = _state;
    if (state == null) return;

    setState(() {
      _scanning = true;
    });

    final scanService = context.read<ScanService>();
    final scanned = await scanService.scanSheet(
      context,
      questionCount: state.questionCount,
    );

    if (!mounted) return;

    setState(() {
      _scanning = false;
      if (scanned != null) {
        _answers = Map<int, int>.from(scanned);
        _editingGrid = true;
      }
    });
  }

  void _handleManualEntry() {
    setState(() {
      _editingGrid = true;
    });
  }

  Future<void> _handleUseKey() async {
    final state = _state;
    if (state == null) return;

    final updatedState = state.copyWith(
      answerKey: Map<int, int>.from(_answers),
    );

    final repo = context.read<LocalRepository>();
    await repo.saveQuickScan(updatedState);

    if (!mounted) return;
    context.go(AppRoutes.quickScanSession);
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

    final state = _state;
    if (state == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.scanAnswerKey)),
        body: Center(
          child: PrimaryButton(
            label: l10n.back,
            onPressed: () => context.go(AppRoutes.quickScanSetup),
          ),
        ),
      );
    }

    final total = state.questionCount;
    final filledCount = _answers.values.where((v) => v > 0).length;
    final isAllFilled = filledCount == total;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scanAnswerKey),
        actions: [
          if (_editingGrid)
            IconButton(
              icon: const Icon(Icons.document_scanner_rounded),
              tooltip: l10n.scanAnswerKey,
              onPressed: _scanning ? null : _handleScan,
            ),
        ],
      ),
      body: SafeArea(
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
            : _editingGrid
                ? Column(
                    children: [
                      Expanded(
                        child: AnswerGrid.edit(
                          key: ValueKey('qs_key_grid_${_answers.length}_$total'),
                          questionCount: total,
                          initialAnswers: _answers,
                          onChanged: (updated) {
                            setState(() {
                              _answers = updated;
                            });
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(AppTheme.sp16),
                        decoration: const BoxDecoration(
                          color: AppColors.surface,
                          border: Border(
                            top: BorderSide(
                              color: AppColors.divider,
                              width: 1,
                            ),
                          ),
                        ),
                        child: PrimaryButton(
                          label: l10n.useThisKey,
                          onPressed: isAllFilled ? _handleUseKey : null,
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.sp24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: _handleScan,
                            child: Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 44,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.sp24),
                          Text(
                            l10n.scanAnswerKey,
                            style: AppTextStyles.headlineSmall(),
                          ),
                          const SizedBox(height: AppTheme.sp8),
                          Text(
                            l10n.quickScanSubtitle,
                            style: AppTextStyles.bodyMedium(),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppTheme.sp24),
                          TextButton.icon(
                            onPressed: _handleManualEntry,
                            icon: const Icon(Icons.edit_note_rounded),
                            label: Text(l10n.enterManually),
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}
