import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:omr_scanner/app/router.dart';
import 'package:omr_scanner/data/local_repository.dart';
import 'package:omr_scanner/l10n/app_localizations.dart';
import 'package:omr_scanner/models/exam.dart';
import 'package:omr_scanner/theme/app_colors.dart';
import 'package:omr_scanner/theme/app_text.dart';
import 'package:omr_scanner/theme/app_theme.dart';
import 'package:omr_scanner/widgets/app_card.dart';
import 'package:omr_scanner/widgets/primary_button.dart';

/// 3-step wizard for creating an exam:
/// Step 1: Exam Name
/// Step 2: Subjects multi-select
/// Step 3: Classes & Sections
class CreateExamWizard extends StatefulWidget {
  const CreateExamWizard({super.key});

  @override
  State<CreateExamWizard> createState() => _CreateExamWizardState();
}

class _CreateExamWizardState extends State<CreateExamWizard> {
  int _currentStep = 0;
  bool _saving = false;
  bool _saved = false;

  // Step 1: Exam Name
  final TextEditingController _nameController = TextEditingController();
  static const List<String> _quickNames = [
    'Unit Test 1',
    'Unit Test 2',
    'Half Yearly',
    'Annual',
    'Weekly Test',
  ];

  // Step 2: Subjects
  final Set<String> _selectedSubjects = {};
  final List<String> _customSubjects = [];

  // Step 3: Classes & Sections
  final Set<int> _selectedClasses = {};
  final Map<int, Set<String>> _sectionsByClass = {};

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _isStep1Valid => _nameController.text.trim().isNotEmpty;
  bool get _isStep2Valid => _selectedSubjects.isNotEmpty;
  bool get _isStep3Valid =>
      _selectedClasses.isNotEmpty &&
      _selectedClasses.every(
        (c) => (_sectionsByClass[c]?.isNotEmpty ?? false),
      );

  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        return _isStep1Valid;
      case 1:
        return _isStep2Valid;
      case 2:
        return _isStep3Valid;
      default:
        return false;
    }
  }

  void _onNext() {
    if (!_canProceed) return;

    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
    } else {
      _finish();
    }
  }

  void _onBack() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      context.pop();
    }
  }

  Future<void> _finish() async {
    setState(() {
      _saving = true;
    });

    final sortedClasses = _selectedClasses.toList()..sort();
    final sortedSubjects = _selectedSubjects.toList();

    final exam = Exam(
      name: _nameController.text.trim(),
      subjects: sortedSubjects.map((subjectName) {
        final subjectId = const Uuid().v4();
        final papers = sortedClasses.map((classNum) {
          final sections = (_sectionsByClass[classNum]?.toList() ?? ['A'])
            ..sort();
          return Paper(
            subjectId: subjectId,
            classNumber: classNum,
            sections: sections,
            questionCount: 50,
            marksPerCorrect: 1.0,
            negativeMarking: false,
            negativeValue: 0.0,
            sets: [AnswerSet(setLabel: 'A')],
          );
        }).toList();

        return Subject(
          id: subjectId,
          name: subjectName,
          papers: papers,
        );
      }).toList(),
    );

    final repo = context.read<LocalRepository>();
    await repo.saveExam(exam);

    if (!mounted) return;

    setState(() {
      _saving = false;
      _saved = true;
    });

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    context.go(AppRoutes.examDetailPath(exam.id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_saved) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: AppColors.correct,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 56,
                  color: Colors.white,
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1.0, 1.0),
                    duration: 400.ms,
                    curve: Curves.elasticOut,
                  ),
              const SizedBox(height: AppTheme.sp24),
              Text(
                l10n.successExamCreated,
                style: AppTextStyles.headlineMedium(),
              )
                  .animate()
                  .fadeIn(duration: 300.ms, delay: 200.ms),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _onBack,
        ),
        title: Text(l10n.createExam, style: AppTextStyles.headlineMedium()),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 3.0,
            minHeight: 4,
            backgroundColor: AppColors.primarySoft,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.sp20),
                child: _buildCurrentStep(l10n),
              ),
            ),
            _buildBottomBar(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep(AppLocalizations l10n) {
    switch (_currentStep) {
      case 0:
        return _buildStep1(l10n);
      case 1:
        return _buildStep2(l10n);
      case 2:
        return _buildStep3(l10n);
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Step 1: Exam Name ─────────────────────────────────────────────────────

  Widget _buildStep1(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.examName, style: AppTextStyles.headlineSmall()),
        const SizedBox(height: AppTheme.sp8),
        TextField(
          controller: _nameController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.examNameHint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusInput),
            ),
            filled: true,
            fillColor: AppColors.surface,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppTheme.sp20),
        Text('Quick suggestions', style: AppTextStyles.titleMedium()),
        const SizedBox(height: AppTheme.sp12),
        Wrap(
          spacing: AppTheme.sp8,
          runSpacing: AppTheme.sp8,
          children: _quickNames.map((name) {
            final isSelected = _nameController.text == name;
            return ActionChip(
              label: Text(name),
              backgroundColor:
                  isSelected ? AppColors.primarySoft : AppColors.surface,
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.cardBorder,
              ),
              onPressed: () {
                setState(() {
                  _nameController.text = name;
                });
              },
            );
          }).toList(),
        ),
      ],
    ).animate().fadeIn(duration: 250.ms);
  }

  // ── Step 2: Subjects ──────────────────────────────────────────────────────

  Widget _buildStep2(AppLocalizations l10n) {
    final predefined = [
      l10n.oriya,
      l10n.english,
      l10n.hindi,
      l10n.math,
      l10n.science,
      l10n.socialScience,
      l10n.sanskrit,
    ];

    final allSubjects = [...predefined, ..._customSubjects];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.subjects, style: AppTextStyles.headlineSmall()),
        const SizedBox(height: 4),
        Text(
          'Select the subjects included in this exam',
          style: AppTextStyles.bodyMedium(),
        ),
        const SizedBox(height: AppTheme.sp16),
        Wrap(
          spacing: AppTheme.sp8,
          runSpacing: AppTheme.sp8,
          children: [
            ...allSubjects.map((subject) {
              final selected = _selectedSubjects.contains(subject);
              return FilterChip(
                label: Text(subject),
                selected: selected,
                selectedColor: AppColors.primarySoft,
                checkmarkColor: AppColors.primary,
                side: BorderSide(
                  color: selected ? AppColors.primary : AppColors.cardBorder,
                ),
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _selectedSubjects.add(subject);
                    } else {
                      _selectedSubjects.remove(subject);
                    }
                  });
                },
              );
            }),
            ActionChip(
              avatar: const Icon(Icons.add, size: 18),
              label: Text(l10n.addOther),
              side: const BorderSide(color: AppColors.cardBorder),
              onPressed: () => _showAddSubjectDialog(l10n),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 250.ms);
  }

  Future<void> _showAddSubjectDialog(AppLocalizations l10n) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.addOther, style: AppTextStyles.headlineSmall()),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.subject,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusInput),
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return l10n.subject;
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(ctx).pop(controller.text.trim());
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      setState(() {
        if (!_customSubjects.contains(result)) {
          _customSubjects.add(result);
        }
        _selectedSubjects.add(result);
      });
    }
  }

  // ── Step 3: Classes & Sections ────────────────────────────────────────────

  Widget _buildStep3(AppLocalizations l10n) {
    const classes = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.classesAndSections, style: AppTextStyles.headlineSmall()),
        const SizedBox(height: 4),
        Text(
          'Choose the classes and sections appearing for this exam',
          style: AppTextStyles.bodyMedium(),
        ),
        const SizedBox(height: AppTheme.sp16),
        Text(l10n.class_, style: AppTextStyles.titleMedium()),
        const SizedBox(height: AppTheme.sp8),
        Wrap(
          spacing: AppTheme.sp8,
          runSpacing: AppTheme.sp8,
          children: classes.map((c) {
            final isSelected = _selectedClasses.contains(c);
            return FilterChip(
              label: Text(l10n.classLabel(c)),
              selected: isSelected,
              selectedColor: AppColors.primarySoft,
              checkmarkColor: AppColors.primary,
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.cardBorder,
              ),
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _selectedClasses.add(c);
                    _sectionsByClass.putIfAbsent(c, () => {'A'});
                  } else {
                    _selectedClasses.remove(c);
                    _sectionsByClass.remove(c);
                  }
                });
              },
            );
          }).toList(),
        ),
        if (_selectedClasses.isNotEmpty) ...[
          const SizedBox(height: AppTheme.sp24),
          Text(l10n.sections, style: AppTextStyles.titleMedium()),
          const SizedBox(height: AppTheme.sp12),
          ...((_selectedClasses.toList()..sort()).map((classNum) {
            final sections = _sectionsByClass[classNum] ?? {'A'};
            return AppCard(
              padding: const EdgeInsets.all(AppTheme.sp12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          l10n.classLabel(classNum),
                          style: AppTextStyles.titleMedium(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sections',
                        style: AppTextStyles.bodyMedium(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.sp8),
                  Wrap(
                    spacing: AppTheme.sp8,
                    runSpacing: AppTheme.sp8,
                    children: [
                      ...['A', 'B', 'C', 'D'].map((letter) {
                        final isSel = sections.contains(letter);
                        return FilterChip(
                          label: Text(letter),
                          selected: isSel,
                          selectedColor: AppColors.primarySoft,
                          checkmarkColor: AppColors.primary,
                          side: BorderSide(
                            color: isSel
                                ? AppColors.primary
                                : AppColors.cardBorder,
                          ),
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                sections.add(letter);
                              } else if (sections.length > 1) {
                                sections.remove(letter);
                              }
                            });
                          },
                        );
                      }),
                      ActionChip(
                        avatar: const Icon(Icons.add, size: 16),
                        label: const Text('Add'),
                        side: const BorderSide(color: AppColors.cardBorder),
                        onPressed: () =>
                            _showAddSectionDialog(classNum, sections),
                      ),
                    ],
                  ),
                ],
              ),
            );
          })),
        ],
      ],
    ).animate().fadeIn(duration: 250.ms);
  }

  Future<void> _showAddSectionDialog(
    int classNum,
    Set<String> currentSections,
  ) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Add section to ${l10n.classLabel(classNum)}',
          style: AppTextStyles.headlineSmall(),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            maxLength: 2,
            decoration: InputDecoration(
              labelText: 'Section letter (e.g. E)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusInput),
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Please enter a section name';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(ctx).pop(controller.text.trim().toUpperCase());
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      setState(() {
        currentSections.add(result);
      });
    }
  }

  // ── Bottom Bar ────────────────────────────────────────────────────────────

  Widget _buildBottomBar(AppLocalizations l10n) {
    return Container(
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
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            OutlinedButton(
              onPressed: _onBack,
              child: Text(l10n.back),
            ),
            const SizedBox(width: AppTheme.sp12),
          ],
          Expanded(
            child: PrimaryButton(
              label: _currentStep == 2 ? l10n.createExam : l10n.next,
              loading: _saving,
              onPressed: (_canProceed && !_saving) ? _onNext : null,
            ),
          ),
        ],
      ),
    );
  }
}
