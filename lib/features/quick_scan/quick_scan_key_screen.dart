import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:omr_scanner/app/router.dart';
import 'package:omr_scanner/data/local_repository.dart';
import 'package:omr_scanner/features/answer_key/answer_grid.dart';
import 'package:omr_scanner/l10n/app_localizations.dart';
import 'package:omr_scanner/models/quick_scan_state.dart';
import 'package:omr_scanner/services/omr_service.dart';
import 'package:omr_scanner/services/storage_service.dart';
import 'package:omr_scanner/theme/app_colors.dart';
import 'package:omr_scanner/theme/app_text.dart';
import 'package:omr_scanner/theme/app_theme.dart';
import 'package:omr_scanner/widgets/image_source_sheet.dart';
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
  bool _hasOutputImage = false;
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
    final hasImg = await StorageService.hasAnswerKey();
    if (!mounted) return;

    Map<int, int> initial = {};
    if (state?.answerKey != null && state!.answerKey!.isNotEmpty) {
      initial = Map<int, int>.from(state.answerKey!);
    } else {
      // Restore from device's local storage (like browser localStorage)
      final localAnswers = await StorageService.loadAnswerKeyMap();
      if (localAnswers != null && localAnswers.isNotEmpty) {
        initial = localAnswers;
      }
    }

    setState(() {
      _state = state;
      _loading = false;
      _hasOutputImage = hasImg;
      if (initial.isNotEmpty) {
        _answers = initial;
        _editingGrid = true;
      }
    });
  }

  Future<void> _handleScan() async {
    final state = _state;
    if (state == null) return;

    final picked = await pickImageFromSource(context);
    if (picked == null) return;

    setState(() {
      _scanning = true;
    });

    try {
      // Parse photo using the exact OmrService
      final omrResult = await OmrService.process(picked);

      // Save both the output image and answer key json (including zero values)
      await StorageService.saveAnswerKey(omrResult);

      final Map<int, int> scannedAnswers = {};
      omrResult.results.forEach((key, val) {
        final q = int.tryParse(key);
        if (q != null) {
          scannedAnswers[q] = val;
        }
      });

      final totalDetected = scannedAnswers.length;
      final qCount = totalDetected > 0 ? totalDetected : state.questionCount;
      for (int i = 1; i <= qCount; i++) {
        scannedAnswers.putIfAbsent(i, () => 0);
      }

      final updatedState = state.copyWith(
        questionCount: qCount,
        answerKey: Map<int, int>.from(scannedAnswers),
      );

      final repo = context.read<LocalRepository>();
      await repo.saveQuickScan(updatedState);
      await StorageService.saveAnswersJson(scannedAnswers, total: qCount);

      if (!mounted) return;

      setState(() {
        _answers = scannedAnswers;
        _state = updatedState;
        _editingGrid = true;
        _hasOutputImage = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Answer key scanned successfully (${omrResult.filledCount} answers detected)',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      debugPrint('Error scanning answer key: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to process OMR sheet: ${e.toString().replaceAll('Exception: ', '')}',
          ),
          backgroundColor: AppColors.wrong,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _scanning = false;
        });
      }
    }
  }

  Future<void> _handlePreviewImage() async {
    final bytes = await StorageService.loadAnswerKeyImage();
    if (!mounted) return;
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No output image available to preview.')),
      );
      return;
    }

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
                title: const Text('Output Image Preview'),
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

  void _handleManualEntry() {
    setState(() {
      _editingGrid = true;
    });
  }

  Future<void> _handleUseKey() async {
    final state = _state;
    if (state == null) return;

    // Use exact length of the answer key json (including zero values)
    final qCount = _answers.isNotEmpty ? _answers.length : state.questionCount;
    final updatedState = state.copyWith(
      questionCount: qCount,
      answerKey: Map<int, int>.from(_answers),
    );

    final repo = context.read<LocalRepository>();
    await repo.saveQuickScan(updatedState);
    await StorageService.saveAnswersJson(_answers, total: qCount);

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
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.quickScanSetup);
            }
          },
        ),
        title: Text(l10n.scanAnswerKey),
        actions: [
          if (_hasOutputImage)
            IconButton(
              icon: const Icon(Icons.image_outlined),
              tooltip: 'Preview output image',
              onPressed: _handlePreviewImage,
            ),
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
                          key: ValueKey('qs_key_grid_$total'),
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
                          label: isAllFilled ? 'Save and use the key' : l10n.useThisKey,
                          onPressed: _answers.values.any((v) => v > 0) ? _handleUseKey : null,
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
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: AppTheme.sp12,
                            runSpacing: AppTheme.sp8,
                            children: [
                              if (_hasOutputImage)
                                OutlinedButton.icon(
                                  onPressed: _handlePreviewImage,
                                  icon: const Icon(Icons.image_outlined),
                                  label: const Text('Preview output image'),
                                ),
                              ElevatedButton.icon(
                                onPressed: _scanning ? null : _handleScan,
                                icon: const Icon(Icons.camera_alt_rounded),
                                label: Text(l10n.scanAnswerKey),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _handleManualEntry,
                                icon: const Icon(Icons.edit_note_rounded),
                                label: Text(l10n.enterManually),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}
