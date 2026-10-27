import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../data/account_state.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../premium/premium_gate.dart';
import '../premium/premium_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final account = context.watch<AccountState>();
    final today = DateFormat('d MMM yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {},
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Header ─────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppTheme.sp16, AppTheme.sp24, AppTheme.sp16, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  account.isLoggedIn && account.userName != null
                                      ? l10n.namaskarName(account.userName!)
                                      : l10n.namaskar,
                                  style: AppTextStyles.headlineMedium(),
                                ),
                                Text(
                                  l10n.today(today),
                                  style: AppTextStyles.bodyMedium(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppTheme.sp8),
                          _StatusChip(account: account),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms),

                    // ── Login banner (logged-out only) ────────────────
                    if (!account.isLoggedIn) ...[
                      const SizedBox(height: AppTheme.sp12),
                      _LoginBanner(l10n: l10n),
                    ],

                    const SizedBox(height: AppTheme.sp24),

                    // ── Hero cards ────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.sp16),
                      child: Column(
                        children: [
                          // Quick Scan card
                          _QuickScanCard(l10n: l10n)
                              .animate(delay: 100.ms)
                              .fadeIn(duration: 350.ms)
                              .slideY(begin: 0.1, end: 0),

                          const SizedBox(height: AppTheme.sp12),

                          // Exams card
                          _ExamsCard(l10n: l10n, account: account)
                              .animate(delay: 180.ms)
                              .fadeIn(duration: 350.ms)
                              .slideY(begin: 0.1, end: 0),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppTheme.sp32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Status chip ─────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final AccountState account;
  const _StatusChip({required this.account});

  @override
  Widget build(BuildContext context) {
    if (account.isPremium) {
      return Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.sp12, vertical: AppTheme.sp4),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          border: Border.all(color: AppColors.accent.withOpacity(0.4)),
        ),
        child: Text(
          '👑 Premium',
          style: AppTextStyles.labelMedium(color: AppColors.accent),
        ),
      );
    }

    final left = account.freeScansLeft;
    final color = left <= 0
        ? AppColors.wrong
        : left <= 5
            ? AppColors.accent
            : AppColors.primary;

    return GestureDetector(
      onTap: () => PremiumSheet.show(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.sp12, vertical: AppTheme.sp4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(
          '⚡ $left free scans left',
          style: AppTextStyles.labelMedium(color: color),
        ),
      ),
    );
  }
}

// ── Login banner ─────────────────────────────────────────────────────────────

class _LoginBanner extends StatefulWidget {
  final AppLocalizations l10n;
  const _LoginBanner({required this.l10n});

  @override
  State<_LoginBanner> createState() => _LoginBannerState();
}

class _LoginBannerState extends State<_LoginBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.sp16, vertical: AppTheme.sp4),
      child: Material(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall + 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall + 4),
          onTap: () => context.push(AppRoutes.login),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.sp12, vertical: AppTheme.sp8),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: AppTheme.sp8),
                Expanded(
                  child: Text(
                    widget.l10n.loginBanner,
                    style:
                        AppTextStyles.bodySmall(color: AppColors.primaryDark),
                  ),
                ),
                IconButton(
                  iconSize: 16,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close,
                      size: 16, color: AppColors.textSecondary),
                  onPressed: () => setState(() => _dismissed = true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Quick Scan card ──────────────────────────────────────────────────────────

class _QuickScanCard extends StatelessWidget {
  final AppLocalizations l10n;
  const _QuickScanCard({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.primary,
      borderColor: Colors.transparent,
      onTap: () => context.push(AppRoutes.quickScanSetup),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.document_scanner_rounded,
                size: 28, color: Colors.white),
          ),
          const SizedBox(width: AppTheme.sp16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.quickScan,
                    style: AppTextStyles.headlineSmall(color: Colors.white)),
                const SizedBox(height: 2),
                Text(l10n.quickScanSubtitle,
                    style: AppTextStyles.bodySmall(
                        color: Colors.white.withOpacity(0.8))),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              size: 16, color: Colors.white),
        ],
      ),
    );
  }
}

// ── Exams card ───────────────────────────────────────────────────────────────

class _ExamsCard extends StatelessWidget {
  final AppLocalizations l10n;
  final AccountState account;
  const _ExamsCard({required this.l10n, required this.account});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => PremiumGate.examOrSheet(
        context,
        () => context.go(AppRoutes.exams),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.folder_open_rounded,
                    size: 28, color: AppColors.primary),
                if (!account.canUseExams)
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_rounded,
                          size: 8, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.sp16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(l10n.exams,
                        style: AppTextStyles.headlineSmall()),
                    if (!account.canUseExams) ...[
                      const SizedBox(width: AppTheme.sp8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Premium',
                            style: AppTextStyles.labelSmall(
                                color: AppColors.accent)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  account.canUseExams
                      ? l10n.examsScanSubtitle
                      : 'Create exams for every class and subject',
                  style: AppTextStyles.bodySmall(),
                ),
              ],
            ),
          ),
          Icon(
            account.canUseExams
                ? Icons.arrow_forward_ios_rounded
                : Icons.lock_rounded,
            size: 16,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}


