import 'package:flutter/material.dart';
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
import 'package:omr_scanner/widgets/primary_button.dart';

/// Bottom sheet for picking:
/// 1. Exam
/// 2. Subject
/// 3. Class & Section
/// 4. Set (if paper has multiple sets)
/// and launching the scan session.
class ExamScanPickerSheet extends StatefulWidget {
  const ExamScanPickerSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const ExamScanPickerSheet(),
      );

  @override
  State<ExamScanPickerSheet> createState() => _ExamScanPickerSheetState();
}

class _ExamScanPickerSheetState extends State<ExamScanPickerSheet> {
  int _step = 0; // 0: Exam, 1: Subject, 2: Class & Section, 3: Set
  bool _loading = true;
  List<Exam> _exams = [];

  Exam? _selectedExam;
  Subject? _selectedSubject;
  Paper? _selectedPaper;
  String? _selectedSection;
  String? _selectedSetId;

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    final repo = context.read<LocalRepository>();
    final exams = await repo.loadExams();
    if (!mounted) return;
    setState(() {
      _exams = exams;
      _loading = false;
    });
  }

  void _onBack() {
    if (_step > 0) {
      setState(() {
        _step--;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  bool get _canStartScanning {
    if (_selectedExam == null ||
        _selectedSubject == null ||
        _selectedPaper == null ||
        _selectedSection == null) {
      return false;
    }
    if (_selectedPaper!.hasMultipleSets && _selectedSetId == null) {
      return false;
    }
    return true;
  }

  void _startScanning() {
    if (!_canStartScanning) return;

    final exam = _selectedExam!;
    final subject = _selectedSubject!;
    final paper = _selectedPaper!;
    final section = _selectedSection!;
    final setId = _selectedSetId ?? paper.sets.first.id;

    Navigator.of(context).pop();

    final path =
        '${AppRoutes.scanSessionPath(exam.id, subject.id, paper.id)}?section=$section&setId=$setId';
    context.push(path);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusSheet),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: AppTheme.sp12, bottom: 4),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Sheet Header with title and back button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.sp16,
                vertical: AppTheme.sp8,
              ),
              child: Row(
                children: [
                  if (_step > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _onBack,
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: Text(
                      _stepTitle(l10n),
                      style: AppTextStyles.headlineSmall(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Step Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.sp16),
                child: _buildCurrentStep(l10n),
              ),
            ),

            // Start Scanning Action Button
            if (_step >= 2)
              Container(
                padding: const EdgeInsets.all(AppTheme.sp16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: PrimaryButton(
                  label: l10n.startScanning,
                  onPressed: _canStartScanning ? _startScanning : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _stepTitle(AppLocalizations l10n) {
    switch (_step) {
      case 0:
        return l10n.selectExam;
      case 1:
        return l10n.selectSubject;
      case 2:
        return l10n.selectClass;
      case 3:
        return l10n.selectSet;
      default:
        return l10n.scanOMR;
    }
  }

  Widget _buildCurrentStep(AppLocalizations l10n) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    switch (_step) {
      case 0:
        return _buildExamStep(l10n);
      case 1:
        return _buildSubjectStep(l10n);
      case 2:
        return _buildClassAndSectionStep(l10n);
      case 3:
        return _buildSetStep(l10n);
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Step 0: Select Exam ───────────────────────────────────────────────────

  Widget _buildExamStep(AppLocalizations l10n) {
    if (_exams.isEmpty) {
      return EmptyState(
        icon: Icons.folder_outlined,
        title: l10n.noExamsYet,
        actionLabel: l10n.createFirstExam,
        onAction: () {
          Navigator.of(context).pop();
          context.push(AppRoutes.examCreate);
        },
      );
    }

    return Column(
      children: _exams.map((exam) {
        final isSelected = _selectedExam?.id == exam.id;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.sp8),
          child: AppCard(
            color: isSelected ? AppColors.primarySoft : AppColors.surface,
            borderColor: isSelected ? AppColors.primary : AppColors.cardBorder,
            onTap: () {
              setState(() {
                _selectedExam = exam;
                _selectedSubject = null;
                _selectedPaper = null;
                _selectedSection = null;
                _selectedSetId = null;
                _step = 1;
              });
            },
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.folder_rounded,
                    color: isSelected ? Colors.white : AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppTheme.sp12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exam.name, style: AppTextStyles.titleMedium()),
                      const SizedBox(height: 2),
                      Text(
                        l10n.subjectCount(exam.subjects.length),
                        style: AppTextStyles.bodySmall(),
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
          ),
        );
      }).toList(),
    );
  }

  // ── Step 1: Select Subject ────────────────────────────────────────────────

  Widget _buildSubjectStep(AppLocalizations l10n) {
    final subjects = _selectedExam?.subjects ?? [];

    if (subjects.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No subjects in this exam'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Exam: ${_selectedExam?.name}',
          style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppTheme.sp16),
        Wrap(
          spacing: AppTheme.sp8,
          runSpacing: AppTheme.sp8,
          children: subjects.map((subj) {
            final isSelected = _selectedSubject?.id == subj.id;
            return ChoiceChip(
              label: Text(subj.name),
              selected: isSelected,
              selectedColor: AppColors.primarySoft,
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.cardBorder,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedSubject = subj;
                    _selectedPaper = null;
                    _selectedSection = null;
                    _selectedSetId = null;
                    _step = 2;
                  });
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Step 2: Select Class & Section ────────────────────────────────────────

  Widget _buildClassAndSectionStep(AppLocalizations l10n) {
    final papers = List<Paper>.from(_selectedSubject?.papers ?? [])
      ..sort((a, b) => a.classNumber.compareTo(b.classNumber));

    if (papers.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No classes found for this subject'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_selectedExam?.name} · ${_selectedSubject?.name}',
          style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppTheme.sp16),

        // Class selection
        Text(l10n.class_, style: AppTextStyles.titleMedium()),
        const SizedBox(height: AppTheme.sp8),
        Wrap(
          spacing: AppTheme.sp8,
          runSpacing: AppTheme.sp8,
          children: papers.map((p) {
            final isSelected = _selectedPaper?.id == p.id;
            return ChoiceChip(
              label: Text(l10n.classLabel(p.classNumber)),
              selected: isSelected,
              selectedColor: AppColors.primarySoft,
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.cardBorder,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedPaper = p;
                    _selectedSection =
                        p.sections.isNotEmpty ? p.sections.first : null;
                    if (!p.hasMultipleSets) {
                      _selectedSetId = p.sets.first.id;
                    } else {
                      _selectedSetId = null;
                    }
                  });
                }
              },
            );
          }).toList(),
        ),

        // Section selection
        if (_selectedPaper != null) ...[
          const SizedBox(height: AppTheme.sp20),
          Text(l10n.sections, style: AppTextStyles.titleMedium()),
          const SizedBox(height: AppTheme.sp8),
          Wrap(
            spacing: AppTheme.sp8,
            runSpacing: AppTheme.sp8,
            children: _selectedPaper!.sections.map((sec) {
              final isSelected = _selectedSection == sec;
              return ChoiceChip(
                label: Text(l10n.sectionLabel(sec)),
                selected: isSelected,
                selectedColor: AppColors.primarySoft,
                side: BorderSide(
                  color:
                      isSelected ? AppColors.primary : AppColors.cardBorder,
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedSection = sec;
                      if (_selectedPaper!.hasMultipleSets &&
                          _selectedSetId == null) {
                        _step = 3;
                      }
                    });
                  }
                },
              );
            }).toList(),
          ),

          // Multiple sets picker inline if class and section are selected
          if (_selectedPaper!.hasMultipleSets) ...[
            const SizedBox(height: AppTheme.sp20),
            Text(l10n.selectSet, style: AppTextStyles.titleMedium()),
            const SizedBox(height: AppTheme.sp8),
            Wrap(
              spacing: AppTheme.sp8,
              runSpacing: AppTheme.sp8,
              children: _selectedPaper!.sets.map((s) {
                final isSelected = _selectedSetId == s.id;
                return ChoiceChip(
                  label: Text(
                    '${l10n.setLabel(s.setLabel)}${s.hasKey ? " ✓" : ""}',
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primarySoft,
                  side: BorderSide(
                    color:
                        isSelected ? AppColors.primary : AppColors.cardBorder,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedSetId = s.id;
                      });
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ],
    );
  }

  // ── Step 3: Select Set ────────────────────────────────────────────────────

  Widget _buildSetStep(AppLocalizations l10n) {
    final sets = _selectedPaper?.sets ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_selectedSubject?.name} · ${l10n.classLabel(_selectedPaper?.classNumber ?? 0)}-$_selectedSection',
          style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppTheme.sp16),
        Text(l10n.selectSet, style: AppTextStyles.titleMedium()),
        const SizedBox(height: AppTheme.sp8),
        Wrap(
          spacing: AppTheme.sp8,
          runSpacing: AppTheme.sp8,
          children: sets.map((s) {
            final isSelected = _selectedSetId == s.id;
            return ChoiceChip(
              label: Text(
                '${l10n.setLabel(s.setLabel)}${s.hasKey ? " ✓" : ""}',
              ),
              selected: isSelected,
              selectedColor: AppColors.primarySoft,
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.cardBorder,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedSetId = s.id;
                  });
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
