import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:omr_scanner/app/router.dart';
import 'package:omr_scanner/data/local_repository.dart';
import 'package:omr_scanner/l10n/app_localizations.dart';
import 'package:omr_scanner/logic/scoring.dart';
import 'package:omr_scanner/models/quick_scan_state.dart';
import 'package:omr_scanner/theme/app_colors.dart';
import 'package:omr_scanner/theme/app_text.dart';
import 'package:omr_scanner/theme/app_theme.dart';
import 'package:omr_scanner/widgets/app_card.dart';
import 'package:omr_scanner/widgets/primary_button.dart';

/// Screen for configuring Quick Scan parameters (question count, marks, negative marking).
class QuickScanSetupScreen extends StatefulWidget {
  const QuickScanSetupScreen({super.key});

  @override
  State<QuickScanSetupScreen> createState() => _QuickScanSetupScreenState();
}

class _QuickScanSetupScreenState extends State<QuickScanSetupScreen> {
  int _selectedCountSegment = 50; // 50, 100, or -1 for custom
  int _customQuestionCount = 25;
  late final TextEditingController _customCountController;

  double _marksPerCorrect = 1.0;
  bool _negativeMarking = false;
  double _negativeValue = 0.25;
  bool _isCustomPenalty = false;
  late final TextEditingController _customPenaltyController;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _customCountController =
        TextEditingController(text: _customQuestionCount.toString());
    _customPenaltyController =
        TextEditingController(text: formatMarks(_negativeValue));
    _loadExistingState();
  }

  @override
  void dispose() {
    _customCountController.dispose();
    _customPenaltyController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingState() async {
    final repo = context.read<LocalRepository>();
    final existing = await repo.loadQuickScan();
    if (!mounted) return;

    if (existing != null) {
      final qCount = existing.questionCount;
      if (qCount == 50 || qCount == 100) {
        _selectedCountSegment = qCount;
      } else {
        _selectedCountSegment = -1;
        _customQuestionCount = qCount;
        _customCountController.text = qCount.toString();
      }

      _marksPerCorrect = existing.marksPerCorrect;
      _negativeMarking = existing.negativeMarking;
      _negativeValue = existing.negativeValue;

      if (_negativeValue != 0.25 &&
          _negativeValue != 0.5 &&
          _negativeValue != 1.0) {
        _isCustomPenalty = true;
        _customPenaltyController.text = formatMarks(_negativeValue);
      }
    }

    setState(() {
      _loading = false;
    });
  }

  int get _resolvedQuestionCount {
    if (_selectedCountSegment == -1) {
      final parsed = int.tryParse(_customCountController.text.trim());
      if (parsed != null && parsed >= 1 && parsed <= 200) {
        return parsed;
      }
      return _customQuestionCount;
    }
    return _selectedCountSegment;
  }

  double get _resolvedNegativeValue {
    if (!_negativeMarking) return 0.0;
    if (_isCustomPenalty) {
      final parsed = double.tryParse(_customPenaltyController.text.trim());
      if (parsed != null && parsed > 0) {
        return parsed;
      }
    }
    return _negativeValue;
  }

  Future<void> _handleNext() async {
    final repo = context.read<LocalRepository>();
    final existing = await repo.loadQuickScan();

    final count = _resolvedQuestionCount;
    final marks = _marksPerCorrect;
    final negMarking = _negativeMarking;
    final negVal = _resolvedNegativeValue;

    if (existing != null && existing.hasKey && existing.hasResults) {
      if (!mounted) return;
      final shouldContinue = await _showContinueDialog(context);
      if (!mounted) return;

      if (shouldContinue == true) {
        context.go(AppRoutes.quickScanSession);
        return;
      } else if (shouldContinue == false) {
        // Start new
        await repo.clearQuickScan();
        final newState = QuickScanState(
          questionCount: count,
          marksPerCorrect: marks,
          negativeMarking: negMarking,
          negativeValue: negVal,
          answerKey: null,
          results: const [],
        );
        await repo.saveQuickScan(newState);
        if (mounted) {
          context.go(AppRoutes.quickScanKey);
        }
        return;
      }
      // Cancelled dialog, stay here
      return;
    }

    final newState = QuickScanState(
      questionCount: count,
      marksPerCorrect: marks,
      negativeMarking: negMarking,
      negativeValue: negVal,
      answerKey: existing?.answerKey != null &&
              existing!.answerKey!.length == count
          ? existing.answerKey
          : null,
      results: const [],
    );
    await repo.saveQuickScan(newState);

    if (mounted) {
      context.go(AppRoutes.quickScanKey);
    }
  }

  Future<bool?> _showContinueDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.quickScanInProgress),
        content: Text(l10n.continueCurrentKey),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false), // Start new
            child: Text(
              l10n.startNew,
              style: const TextStyle(color: AppColors.wrong),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true), // Continue
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: Text(l10n.continue_),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.home);
              }
            },
          ),
          title: Text(l10n.quickScan),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        title: Text(l10n.quickScan),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.sp16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Section 1: Question Count
                    _buildQuestionCountSection(l10n),
                    const SizedBox(height: AppTheme.sp16),

                    // Section 2: Marks per Correct
                    _buildMarksSection(l10n),
                    const SizedBox(height: AppTheme.sp16),

                    // Section 3: Negative Marking
                    _buildNegativeMarkingSection(l10n),
                    const SizedBox(height: AppTheme.sp24),
                  ],
                ),
              ),
            ),

            // Sticky Next button
            Container(
              padding: const EdgeInsets.all(AppTheme.sp16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.divider, width: 1),
                ),
              ),
              child: PrimaryButton(
                label: l10n.next,
                onPressed: _handleNext,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCountSection(AppLocalizations l10n) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.format_list_numbered,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: AppTheme.sp8),
              Text(
                l10n.questionCount,
                style: AppTextStyles.titleLarge(),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.sp16),
          SegmentedButton<int>(
            segments: [
              const ButtonSegment<int>(value: 50, label: Text('50')),
              const ButtonSegment<int>(value: 100, label: Text('100')),
              ButtonSegment<int>(value: -1, label: Text(l10n.custom)),
            ],
            selected: {_selectedCountSegment},
            onSelectionChanged: (set) {
              setState(() {
                _selectedCountSegment = set.first;
              });
            },
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppColors.primarySoft,
              selectedForegroundColor: AppColors.primaryDark,
            ),
          ),
          if (_selectedCountSegment == -1) ...[
            const SizedBox(height: AppTheme.sp12),
            TextField(
              controller: _customCountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: l10n.enterQuestion,
                suffixText: '1–200',
              ),
              onChanged: (val) {
                final num = int.tryParse(val.trim());
                if (num != null && num >= 1 && num <= 200) {
                  _customQuestionCount = num;
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMarksSection(AppLocalizations l10n) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.add_task_rounded,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: AppTheme.sp8),
              Expanded(
                child: Text(
                  l10n.marksPerCorrect,
                  style: AppTextStyles.titleLarge(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.sp16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                onPressed: _marksPerCorrect > 0.5
                    ? () {
                        setState(() {
                          _marksPerCorrect =
                              ((_marksPerCorrect - 0.5) * 10).round() / 10;
                        });
                      }
                    : null,
                icon: const Icon(Icons.remove),
              ),
              Container(
                width: 90,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.sp12),
                child: Text(
                  formatMarks(_marksPerCorrect),
                  style: AppTextStyles.headlineLarge(color: AppColors.primary),
                ),
              ),
              IconButton.filledTonal(
                onPressed: _marksPerCorrect < 10.0
                    ? () {
                        setState(() {
                          _marksPerCorrect =
                              ((_marksPerCorrect + 0.5) * 10).round() / 10;
                        });
                      }
                    : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNegativeMarkingSection(AppLocalizations l10n) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          SwitchListTile(
            title: Text(
              l10n.negativeMarking,
              style: AppTextStyles.titleLarge(),
            ),
            value: _negativeMarking,
            onChanged: (val) {
              setState(() {
                _negativeMarking = val;
              });
            },
          ),
          if (_negativeMarking) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(AppTheme.sp16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.penaltyPerWrong,
                    style: AppTextStyles.bodyMedium(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.sp12),
                  Wrap(
                    spacing: AppTheme.sp8,
                    runSpacing: AppTheme.sp8,
                    children: [
                      ChoiceChip(
                        label: const Text('0.25'),
                        selected: !_isCustomPenalty && _negativeValue == 0.25,
                        onSelected: (sel) {
                          if (sel) {
                            setState(() {
                              _isCustomPenalty = false;
                              _negativeValue = 0.25;
                            });
                          }
                        },
                      ),
                      ChoiceChip(
                        label: const Text('0.5'),
                        selected: !_isCustomPenalty && _negativeValue == 0.5,
                        onSelected: (sel) {
                          if (sel) {
                            setState(() {
                              _isCustomPenalty = false;
                              _negativeValue = 0.5;
                            });
                          }
                        },
                      ),
                      ChoiceChip(
                        label: const Text('1'),
                        selected: !_isCustomPenalty && _negativeValue == 1.0,
                        onSelected: (sel) {
                          if (sel) {
                            setState(() {
                              _isCustomPenalty = false;
                              _negativeValue = 1.0;
                            });
                          }
                        },
                      ),
                      ChoiceChip(
                        label: Text(l10n.custom),
                        selected: _isCustomPenalty,
                        onSelected: (sel) {
                          if (sel) {
                            setState(() {
                              _isCustomPenalty = true;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  if (_isCustomPenalty) ...[
                    const SizedBox(height: AppTheme.sp12),
                    TextField(
                      controller: _customPenaltyController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        hintText: l10n.penaltyPerWrong,
                        suffixText: l10n.marks,
                      ),
                      onChanged: (val) {
                        final parsed = double.tryParse(val.trim());
                        if (parsed != null && parsed > 0) {
                          _negativeValue = parsed;
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
