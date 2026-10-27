import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:omr_scanner/app/router.dart';
import 'package:omr_scanner/data/account_state.dart';
import 'package:omr_scanner/data/local_repository.dart';
import 'package:omr_scanner/features/premium/premium_sheet.dart';
import 'package:omr_scanner/l10n/app_localizations.dart';
import 'package:omr_scanner/models/exam.dart';
import 'package:omr_scanner/theme/app_colors.dart';
import 'package:omr_scanner/theme/app_text.dart';
import 'package:omr_scanner/theme/app_theme.dart';
import 'package:omr_scanner/widgets/app_card.dart';
import 'package:omr_scanner/widgets/empty_state.dart';
import 'package:omr_scanner/widgets/primary_button.dart';

/// Screen listing all exams or showing locked state for free users.
class ExamsListScreen extends StatefulWidget {
  const ExamsListScreen({super.key});

  @override
  State<ExamsListScreen> createState() => _ExamsListScreenState();
}

class _ExamsListScreenState extends State<ExamsListScreen> {
  bool _loading = true;
  List<Exam> _exams = [];

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final account = context.watch<AccountState>();

    if (!account.canUseExams) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.exams, style: AppTextStyles.headlineMedium()),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.sp24,
                vertical: AppTheme.sp16,
              ),
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
                      Icons.lock_rounded,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.sp20),
                  Text(
                    l10n.exams,
                    style: AppTextStyles.headlineMedium(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.sp8),
                  Text(
                    l10n.createExamsWithSets,
                    style: AppTextStyles.bodyMedium(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.sp24),
                  _BenefitRow(
                    icon: Icons.style_rounded,
                    label: l10n.examBenefitSets,
                  ),
                  _BenefitRow(
                    icon: Icons.groups_rounded,
                    label: l10n.examBenefitClass,
                  ),
                  _BenefitRow(
                    icon: Icons.vpn_key_rounded,
                    label: l10n.examBenefitKeys,
                  ),
                  const SizedBox(height: AppTheme.sp32),
                  PrimaryButton(
                    label: l10n.goPremium,
                    onPressed: () => PremiumSheet.show(context),
                  ),
                  const SizedBox(height: AppTheme.sp12),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.quickScanSetup),
                    child: Text(l10n.tryQuickScanInstead),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.exams, style: AppTextStyles.headlineMedium()),
      ),
      body: _buildContent(l10n),
      floatingActionButton: FloatingActionButton(
        heroTag: 'create_exam_fab',
        backgroundColor: AppColors.primary,
        onPressed: () async {
          await context.push(AppRoutes.examCreate);
          _loadExams();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_exams.isEmpty) {
      return EmptyState(
        icon: Icons.folder_outlined,
        title: l10n.noExamsYet,
        actionLabel: l10n.createFirstExam,
        onAction: () async {
          await context.push(AppRoutes.examCreate);
          _loadExams();
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _loadExams,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.sp16,
          AppTheme.sp16,
          AppTheme.sp16,
          88,
        ),
        itemCount: _exams.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppTheme.sp12),
        itemBuilder: (context, index) {
          final exam = _exams[index];
          return _ExamCard(
            exam: exam,
            onTap: () async {
              await context.push(AppRoutes.examDetailPath(exam.id));
              _loadExams();
            },
            onRename: () => _showRenameDialog(exam),
            onDelete: () => _showDeleteDialog(exam),
          )
              .animate()
              .fade(duration: 300.ms, delay: (40 * index).ms)
              .slideY(
                begin: 0.08,
                end: 0,
                duration: 300.ms,
                delay: (40 * index).ms,
                curve: Curves.easeOutQuad,
              );
        },
      ),
    );
  }

  Future<void> _showRenameDialog(Exam exam) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: exam.name);
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.rename, style: AppTextStyles.headlineSmall()),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.examName,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusInput),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.examName;
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final newName = controller.text.trim();
      exam.name = newName;
      await context.read<LocalRepository>().saveExam(exam);
      _loadExams();
    }
  }

  Future<void> _showDeleteDialog(Exam exam) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.confirmDeleteTitle(exam.name),
          style: AppTextStyles.headlineSmall(),
        ),
        content: Text(
          l10n.confirmDeleteBody,
          style: AppTextStyles.bodyMedium(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.wrong,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<LocalRepository>().deleteExam(exam.id);
      _loadExams();
    }
  }
}

class _ExamCard extends StatelessWidget {
  final Exam exam;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _ExamCard({
    required this.exam,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final total = exam.answerKeysTotal;
    final done = exam.answerKeysDone;
    final progress = total > 0 ? done / total : 0.0;

    return GestureDetector(
      onLongPress: () => _showContextMenu(context),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppTheme.sp16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.folder_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppTheme.sp12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exam.name,
                        style: AppTextStyles.titleLarge(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.subjectCount(exam.subjects.length),
                        style: AppTextStyles.bodyMedium(),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.textSecondary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  ),
                  onSelected: (value) {
                    if (value == 'rename') {
                      onRename();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'rename',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_outlined, size: 20),
                          const SizedBox(width: 8),
                          Text(l10n.rename),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: AppColors.wrong,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.delete,
                            style: const TextStyle(color: AppColors.wrong),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppTheme.sp12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.primarySoft,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.answerKeysProgress(done, total),
              style: AppTextStyles.bodySmall(),
            ),
          ],
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusSheet),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.rename),
              onTap: () {
                Navigator.of(ctx).pop();
                onRename();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.wrong),
              title: Text(
                l10n.delete,
                style: const TextStyle(color: AppColors.wrong),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BenefitRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.sp12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: AppTheme.sp12),
          Expanded(
            child: Text(label, style: AppTextStyles.bodyLarge()),
          ),
        ],
      ),
    );
  }
}
