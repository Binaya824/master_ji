import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:omr_scanner/app/router.dart';
import 'package:omr_scanner/data/account_state.dart';
import 'package:omr_scanner/data/settings_store.dart';
import 'package:omr_scanner/features/premium/premium_sheet.dart';
import 'package:omr_scanner/features/profile/debug_section.dart';
import 'package:omr_scanner/l10n/app_localizations.dart';
import 'package:omr_scanner/theme/app_colors.dart';
import 'package:omr_scanner/theme/app_text.dart';
import 'package:omr_scanner/theme/app_theme.dart';
import 'package:omr_scanner/widgets/app_card.dart';
import 'package:omr_scanner/widgets/primary_button.dart';

/// Profile screen displaying user account details, subscription tier,
/// language toggle, help & share links, and developer debug panel.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final account = context.watch<AccountState>();
    final settings = context.watch<SettingsStore>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.sp16,
            vertical: AppTheme.sp24,
          ),
          children: [
            // ── Top Title Area ──────────────────────────────────────────────
            Text(
              l10n.profile,
              style: AppTextStyles.headlineMedium(),
            ),
            const SizedBox(height: AppTheme.sp24),

            // ── Account Section ─────────────────────────────────────────────
            if (!account.isLoggedIn)
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.person_off_rounded,
                          color: AppColors.textSecondary,
                          size: 24,
                        ),
                        const SizedBox(width: AppTheme.sp12),
                        Expanded(
                          child: Text(
                            l10n.guestMode,
                            style: AppTextStyles.bodyLarge(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.sp16),
                    PrimaryButton(
                      label: l10n.continueWithGoogle,
                      icon: const Icon(Icons.login_rounded, size: 18),
                      onPressed: () => context.push(AppRoutes.login),
                    ),
                  ],
                ),
              )
            else
              AppCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        _UserAvatar(name: account.userName ?? 'Teacher'),
                        const SizedBox(width: AppTheme.sp16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                account.userName ?? '',
                                style: AppTextStyles.headlineSmall(),
                              ),
                              if (account.userEmail != null &&
                                  account.userEmail!.isNotEmpty)
                                Text(
                                  account.userEmail!,
                                  style: AppTextStyles.bodyMedium(),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.sp16),
                    const Divider(),
                    const SizedBox(height: AppTheme.sp8),
                    // School Row
                    Row(
                      children: [
                        const Icon(
                          Icons.school_outlined,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppTheme.sp12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.school,
                                style: AppTextStyles.labelMedium(),
                              ),
                              Text(
                                account.schoolName?.isNotEmpty == true
                                    ? account.schoolName!
                                    : '—',
                                style: AppTextStyles.bodyLarge(),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showEditSchoolSheet(context, account),
                          child: Text(l10n.editSchool),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: AppTheme.sp16),

            // ── Plan Card ───────────────────────────────────────────────────
            _SubscriptionPlanCard(account: account, l10n: l10n),

            const SizedBox(height: AppTheme.sp16),

            // ── Language Section ────────────────────────────────────────────
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.language,
                    style: AppTextStyles.titleMedium(),
                  ),
                  const SizedBox(height: AppTheme.sp12),
                  Row(
                    children: [
                      Expanded(
                        child: _LanguageToggleButton(
                          label: l10n.odia,
                          selected: settings.languageCode == 'or',
                          onTap: () async {
                            await settings.setLanguageCode('or');
                            if (mounted) setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: AppTheme.sp8),
                      Expanded(
                        child: _LanguageToggleButton(
                          label: l10n.english,
                          selected: settings.languageCode == 'en',
                          onTap: () async {
                            await settings.setLanguageCode('en');
                            if (mounted) setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.sp16),

            // ── Help & Share Section ────────────────────────────────────────
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.helpAndShare,
                    style: AppTextStyles.titleMedium(),
                  ),
                  const SizedBox(height: AppTheme.sp8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: Color(0xFF25D366),
                    ),
                    title: Text(l10n.whatsappSupport),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    onTap: () => _launchExternalUrl(
                      'https://wa.me/919999999999',
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.share_rounded,
                      color: AppColors.primary,
                    ),
                    title: Text(l10n.shareApp),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    onTap: () {
                      Share.share(
                        'Check out MasterJi — scan OMR sheets in seconds! https://masterji.app',
                      );
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.star_outline_rounded,
                      color: AppColors.accent,
                    ),
                    title: Text(l10n.rateApp),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    onTap: () => _launchExternalUrl(
                      'https://play.google.com/store/apps/details?id=com.masterji',
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.textSecondary,
                    ),
                    title: Text(l10n.aboutAndPrivacy),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    onTap: () => context.push(AppRoutes.profileAbout),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.sp16),

            // ── Debug Section (kDebugMode only) ─────────────────────────────
            if (kDebugMode) ...[
              const DebugSection(),
              const SizedBox(height: AppTheme.sp16),
            ],

            // ── Log Out Button ──────────────────────────────────────────────
            if (account.isLoggedIn)
              Center(
                child: TextButton(
                  onPressed: () => _handleLogout(context, account, l10n),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.wrong,
                  ),
                  child: Text(
                    l10n.logOut,
                    style: AppTextStyles.titleMedium(color: AppColors.wrong),
                  ),
                ),
              ),

            const SizedBox(height: AppTheme.sp32),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditSchoolSheet(
    BuildContext context,
    AccountState account,
  ) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: account.schoolName);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusSheet),
            ),
          ),
          padding: const EdgeInsets.all(AppTheme.sp24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.editSchool,
                style: AppTextStyles.headlineSmall(),
              ),
              const SizedBox(height: AppTheme.sp16),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.schoolHint,
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: AppTheme.sp16),
              PrimaryButton(
                label: l10n.save,
                onPressed: () async {
                  final text = controller.text.trim();
                  await account.setSchoolName(text.isEmpty ? null : text);
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout(
    BuildContext context,
    AccountState account,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.logOut),
        content: Text(l10n.logOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.wrong),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(l10n.logOut),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await account.logout();
      if (mounted) setState(() {});
    }
  }

  Future<void> _launchExternalUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ── Avatar Circle Widget ────────────────────────────────────────────────────

class _UserAvatar extends StatelessWidget {
  final String name;

  const _UserAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isNotEmpty
        ? name.trim()[0].toUpperCase()
        : 'T';

    return CircleAvatar(
      radius: 28,
      backgroundColor: AppColors.primary,
      child: Text(
        initials,
        style: AppTextStyles.headlineMedium(color: Colors.white),
      ),
    );
  }
}

// ── Plan Card ───────────────────────────────────────────────────────────────

class _SubscriptionPlanCard extends StatelessWidget {
  final AccountState account;
  final AppLocalizations l10n;

  const _SubscriptionPlanCard({
    required this.account,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    if (account.isPremium) {
      return AppCard(
        color: const Color(0xFFFFF9EE),
        borderColor: AppColors.accent.withValues(alpha: 0.5),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.accent,
                size: 24,
              ),
            ),
            const SizedBox(width: AppTheme.sp16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.planPremium,
                    style: AppTextStyles.titleMedium(
                      color: const Color(0xFF7A4A00),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.unlimitedScansShort,
                    style: AppTextStyles.bodyMedium(
                      color: const Color(0xFF7A4A00),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Free plan
    final usedScans = (20 - account.freeScansLeft).clamp(0, 20);
    final progress = usedScans / 20.0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.planFree,
                style: AppTextStyles.titleMedium(),
              ),
              Text(
                '$usedScans / 20',
                style: AppTextStyles.labelMedium(
                  color: AppColors.textSecondary,
                ),
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
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppTheme.sp8),
          Text(
            l10n.freeScansProgress(usedScans),
            style: AppTextStyles.bodySmall(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppTheme.sp16),
          PrimaryButton(
            label: l10n.goPremium,
            icon: const Icon(
              Icons.workspace_premium_rounded,
              color: AppColors.accent,
              size: 20,
            ),
            onPressed: () => PremiumSheet.show(context),
          ),
        ],
      ),
    );
  }
}

// ── Language Toggle Button ──────────────────────────────────────────────────

class _LanguageToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageToggleButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: AppTheme.sp12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusButton),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.titleMedium(
            color: selected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
