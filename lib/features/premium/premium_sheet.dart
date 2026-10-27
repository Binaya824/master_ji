import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../data/account_state.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primary_button.dart';

/// Shows the premium upsell bottom sheet.
/// Call [PremiumSheet.show] from anywhere.
class PremiumSheet extends StatefulWidget {
  const PremiumSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const PremiumSheet(),
      );

  @override
  State<PremiumSheet> createState() => _PremiumSheetState();
}

class _PremiumSheetState extends State<PremiumSheet> {
  bool _yearly = true;
  bool _paying = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final account = context.watch<AccountState>();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusSheet),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.sp24,
            AppTheme.sp8,
            AppTheme.sp24,
            AppTheme.sp24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppTheme.sp24),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Crown icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3D6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.workspace_premium_rounded,
                    size: 36, color: AppColors.accent),
              ),
              const SizedBox(height: AppTheme.sp16),

              Text(
                l10n.premiumTitle,
                style: AppTextStyles.headlineMedium(),
              ),
              const SizedBox(height: AppTheme.sp16),

              // Benefits
              _BenefitRow(
                icon: Icons.all_inclusive_rounded,
                label: l10n.unlimitedScans,
              ),
              _BenefitRow(
                icon: Icons.folder_copy_rounded,
                label: l10n.createExamsWithSets,
              ),
              _BenefitRow(
                icon: Icons.groups_rounded,
                label: l10n.classAndSectionResults,
              ),
              const SizedBox(height: AppTheme.sp24),

              // Plan toggle
              Row(
                children: [
                  Expanded(
                    child: _PlanCard(
                      label: l10n.monthly,
                      price: '₹99/mo',
                      selected: !_yearly,
                      onTap: () => setState(() => _yearly = false),
                    ),
                  ),
                  const SizedBox(width: AppTheme.sp12),
                  Expanded(
                    child: _PlanCard(
                      label: l10n.yearly,
                      price: '₹799/yr',
                      badge: l10n.bestValue,
                      selected: _yearly,
                      onTap: () => setState(() => _yearly = true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.sp24),

              // CTA button
              if (!account.isLoggedIn)
                PrimaryButton(
                  label: l10n.continueWithGoogleToUpgrade,
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push('${AppRoutes.login}?from=premium');
                  },
                )
              else
                PrimaryButton(
                  label: l10n.pay,
                  loading: _paying,
                  onPressed: _handlePay,
                ),

              const SizedBox(height: AppTheme.sp12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.maybeLater),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handlePay() async {
    setState(() => _paying = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _paying = false);

    if (kDebugMode) {
      // In debug builds, set premium = true so we can test premium UI
      await context.read<AccountState>().setPremium(true);
      if (mounted) Navigator.of(context).pop();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).paymentsComingSoon),
          ),
        );
      }
    }
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
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: AppTheme.sp12),
          Text(label, style: AppTextStyles.bodyLarge()),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String label;
  final String price;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.label,
    required this.price,
    this.badge,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppTheme.sp16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.cardBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(bottom: AppTheme.sp8),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.sp8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge!,
                  style: AppTextStyles.labelSmall(color: Colors.white),
                ),
              ),
            Text(label, style: AppTextStyles.titleMedium()),
            const SizedBox(height: 2),
            Text(price,
                style: AppTextStyles.headlineSmall(color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}
