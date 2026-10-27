import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:omr_scanner/data/local_repository.dart';
import 'package:omr_scanner/l10n/app_localizations.dart';
import 'package:omr_scanner/models/exam.dart';
import 'package:omr_scanner/theme/app_colors.dart';
import 'package:omr_scanner/theme/app_text.dart';
import 'package:omr_scanner/theme/app_theme.dart';
import 'package:omr_scanner/widgets/app_card.dart';
import 'package:omr_scanner/widgets/empty_state.dart';
import 'package:omr_scanner/widgets/primary_button.dart';

/// Screen for configuring paper settings (question count, marks, negative marking, sets).
class PaperSettingsScreen extends StatefulWidget {
  final String examId;
  final String subjectId;
  final String paperId;

  const PaperSettingsScreen({
    super.key,
    required this.examId,
    required this.subjectId,
    required this.paperId,
  });

  @override
  State<PaperSettingsScreen> createState() => _PaperSettingsScreenState();
}

class _PaperSettingsScreenState extends State<PaperSettingsScreen> {
  Exam? _exam;
  Paper? _paper;
  bool _loading = true;
  bool _saving = false;

  // Question count
  int _selectedCountPreset = 50; // 50, 100, or -1 (custom)
  final TextEditingController _customCountController = TextEditingController();

  // Marks per correct
  double _marksPerCorrect = 1.0;

  // Negative marking
  bool _negativeMarking = false;
  double _negativeValue = 0.25;
  bool _isCustomPenalty = false;
  final TextEditingController _customPenaltyController =
      TextEditingController();

  // Sets
  bool _hasSets = false;
  final Set<String> _activeSetLabels = {'A'};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _customCountController.dispose();
    _customPenaltyController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final repo = context.read<LocalRepository>();
    final exam = await repo.loadExam(widget.examId);
    if (!mounted) return;

    Paper? foundPaper;
    if (exam != null) {
      try {
        final subject =
            exam.subjects.firstWhere((s) => s.id == widget.subjectId);
        foundPaper = subject.papers.firstWhere((p) => p.id == widget.paperId);
      } catch (_) {
        foundPaper = null;
      }
    }

    if (foundPaper != null) {
      final qCount = foundPaper.questionCount;
      if (qCount == 50 || qCount == 100) {
        _selectedCountPreset = qCount;
      } else {
        _selectedCountPreset = -1;
        _customCountController.text = qCount.toString();
      }

      _marksPerCorrect = foundPaper.marksPerCorrect;
      _negativeMarking = foundPaper.negativeMarking;

      final neg = foundPaper.negativeValue;
      if (neg == 0.25 || neg == 0.5 || neg == 1.0) {
        _negativeValue = neg;
        _isCustomPenalty = false;
      } else if (neg > 0) {
        _negativeValue = neg;
        _isCustomPenalty = true;
        _customPenaltyController.text = neg.toString();
      } else {
        _negativeValue = 0.25;
      }

      _hasSets = foundPaper.hasMultipleSets;
      _activeSetLabels.clear();
      _activeSetLabels.addAll(foundPaper.sets.map((s) => s.setLabel));
      if (_activeSetLabels.isEmpty) {
        _activeSetLabels.add('A');
      }
    }

    setState(() {
      _exam = exam;
      _paper = foundPaper;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final exam = _exam;
    final paper = _paper;
    if (exam == null || paper == null) return;

    // Determine final question count
    int finalQuestionCount = _selectedCountPreset;
    if (_selectedCountPreset == -1) {
      final parsed = int.tryParse(_customCountController.text.trim());
      if (parsed == null || parsed < 1 || parsed > 200) {
        _showErrorSnackBar('Please enter a valid question count between 1 and 200');
        return;
      }
      finalQuestionCount = parsed;
    }

    // Determine final penalty
    double finalPenalty = 0.0;
    if (_negativeMarking) {
      if (_isCustomPenalty) {
        final parsed = double.tryParse(_customPenaltyController.text.trim());
        if (parsed == null || parsed <= 0) {
          _showErrorSnackBar('Please enter a valid penalty value');
          return;
        }
        finalPenalty = parsed;
      } else {
        finalPenalty = _negativeValue;
      }
    }

    setState(() => _saving = true);

    paper.questionCount = finalQuestionCount;
    paper.marksPerCorrect = _marksPerCorrect;
    paper.negativeMarking = _negativeMarking;
    paper.negativeValue = finalPenalty;

    // Update sets
    final targetLabels = _hasSets ? _activeSetLabels.toList() : ['A'];
    targetLabels.sort();

    final updatedSets = <AnswerSet>[];
    for (final label in targetLabels) {
      final existingIndex = paper.sets.indexWhere((s) => s.setLabel == label);
      if (existingIndex >= 0) {
        updatedSets.add(paper.sets[existingIndex]);
      } else {
        updatedSets.add(AnswerSet(setLabel: label));
      }
    }
    paper.sets.clear();
    paper.sets.addAll(updatedSets);

    final repo = context.read<LocalRepository>();
    await repo.saveExam(exam);

    if (!mounted) return;
    setState(() => _saving = false);

    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${l10n.paperSettings} updated'),
        backgroundColor: AppColors.primary,
      ),
    );

    context.pop();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.wrong,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.paperSettings)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_exam == null || _paper == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.paperSettings)),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.paperSettings, style: AppTextStyles.headlineMedium()),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.sp16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Question count
                    _buildQuestionCountSection(l10n),
                    const SizedBox(height: AppTheme.sp16),

                    // Section 2: Marks per correct
                    _buildMarksPerCorrectSection(l10n),
                    const SizedBox(height: AppTheme.sp16),

                    // Section 3: Negative marking
                    _buildNegativeMarkingSection(l10n),
                    const SizedBox(height: AppTheme.sp16),

                    // Section 4: Sets switch
                    _buildSetsSection(l10n),
                    const SizedBox(height: AppTheme.sp24),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(AppTheme.sp16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: PrimaryButton(
                label: l10n.save,
                loading: _saving,
                onPressed: _save,
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
          Text(l10n.questionCount, style: AppTextStyles.titleMedium()),
          const SizedBox(height: AppTheme.sp12),
          SegmentedButton<int>(
            segments: [
              const ButtonSegment(value: 50, label: Text('50')),
              const ButtonSegment(value: 100, label: Text('100')),
              ButtonSegment(value: -1, label: Text(l10n.custom)),
            ],
            selected: {_selectedCountPreset},
            onSelectionChanged: (newSelection) {
              setState(() {
                _selectedCountPreset = newSelection.first;
              });
            },
          ),
          if (_selectedCountPreset == -1) ...[
            const SizedBox(height: AppTheme.sp12),
            TextField(
              controller: _customCountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter number of questions (1-200)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusInput),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMarksPerCorrectSection(AppLocalizations l10n) {
    return AppCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              l10n.marksPerCorrect,
              style: AppTextStyles.titleMedium(),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                color: _marksPerCorrect > 0.5
                    ? AppColors.primary
                    : AppColors.skipped,
                onPressed: _marksPerCorrect > 0.5
                    ? () {
                        setState(() {
                          _marksPerCorrect = (_marksPerCorrect - 0.5)
                              .clamp(0.5, 10.0);
                        });
                      }
                    : null,
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 40),
                alignment: Alignment.center,
                child: Text(
                  _marksPerCorrect == _marksPerCorrect.truncateToDouble()
                      ? _marksPerCorrect.toInt().toString()
                      : _marksPerCorrect.toStringAsFixed(1),
                  style: AppTextStyles.headlineSmall(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                color: _marksPerCorrect < 10.0
                    ? AppColors.primary
                    : AppColors.skipped,
                onPressed: _marksPerCorrect < 10.0
                    ? () {
                        setState(() {
                          _marksPerCorrect = (_marksPerCorrect + 0.5)
                              .clamp(0.5, 10.0);
                        });
                      }
                    : null,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: Text(
              l10n.negativeMarking,
              style: AppTextStyles.titleMedium(),
            ),
            subtitle: Text(
              l10n.penaltyPerWrong,
              style: AppTextStyles.bodySmall(),
            ),
            value: _negativeMarking,
            activeColor: AppColors.primary,
            onChanged: (val) {
              setState(() {
                _negativeMarking = val;
              });
            },
          ),
          if (_negativeMarking) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.sp16,
                0,
                AppTheme.sp16,
                AppTheme.sp16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: AppTheme.sp12),
                  Text('Penalty value', style: AppTextStyles.labelMedium()),
                  const SizedBox(height: AppTheme.sp8),
                  Wrap(
                    spacing: AppTheme.sp8,
                    runSpacing: AppTheme.sp8,
                    children: [
                      ...[0.25, 0.5, 1.0].map((v) {
                        final isSel = !_isCustomPenalty && _negativeValue == v;
                        return ChoiceChip(
                          label: Text('-$v'),
                          selected: isSel,
                          selectedColor: AppColors.primarySoft,
                          side: BorderSide(
                            color: isSel
                                ? AppColors.primary
                                : AppColors.cardBorder,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _isCustomPenalty = false;
                                _negativeValue = v;
                              });
                            }
                          },
                        );
                      }),
                      ChoiceChip(
                        label: Text(l10n.custom),
                        selected: _isCustomPenalty,
                        selectedColor: AppColors.primarySoft,
                        side: BorderSide(
                          color: _isCustomPenalty
                              ? AppColors.primary
                              : AppColors.cardBorder,
                        ),
                        onSelected: (selected) {
                          if (selected) {
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
                        labelText: 'Custom penalty (e.g. 0.33)',
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusInput),
                        ),
                      ),
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

  Widget _buildSetsSection(AppLocalizations l10n) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: Text(
              l10n.paperHasSets,
              style: AppTextStyles.titleMedium(),
            ),
            subtitle: Text(
              'Supports Set A, B, C, D with independent answer keys',
              style: AppTextStyles.bodySmall(),
            ),
            value: _hasSets,
            activeColor: AppColors.primary,
            onChanged: (val) {
              setState(() {
                _hasSets = val;
                if (!val) {
                  _activeSetLabels.clear();
                  _activeSetLabels.add('A');
                } else if (_activeSetLabels.length < 2) {
                  _activeSetLabels.addAll(['A', 'B']);
                }
              });
            },
          ),
          if (_hasSets) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.sp16,
                0,
                AppTheme.sp16,
                AppTheme.sp16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: AppTheme.sp12),
                  Text('Active Sets', style: AppTextStyles.labelMedium()),
                  const SizedBox(height: AppTheme.sp8),
                  Wrap(
                    spacing: AppTheme.sp8,
                    runSpacing: AppTheme.sp8,
                    children: ['A', 'B', 'C', 'D'].map((letter) {
                      final isSelected = _activeSetLabels.contains(letter);
                      return FilterChip(
                        label: Text(l10n.setLabel(letter)),
                        selected: isSelected,
                        selectedColor: AppColors.primarySoft,
                        checkmarkColor: AppColors.primary,
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.cardBorder,
                        ),
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _activeSetLabels.add(letter);
                            } else if (_activeSetLabels.length > 1) {
                              _activeSetLabels.remove(letter);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
