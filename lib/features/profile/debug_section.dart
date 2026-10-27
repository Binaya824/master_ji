import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:omr_scanner/data/account_state.dart';
import 'package:omr_scanner/l10n/app_localizations.dart';
import 'package:omr_scanner/theme/app_colors.dart';
import 'package:omr_scanner/theme/app_text.dart';
import 'package:omr_scanner/theme/app_theme.dart';
import 'package:omr_scanner/widgets/app_card.dart';

/// Developer-only debug section allowing rapid toggling of login state,
/// premium status, and resetting the free scans counter.
/// Renders nothing when running in release mode.
class DebugSection extends StatelessWidget {
  const DebugSection({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final account = context.watch<AccountState>();

    return AppCard(
      color: const Color(0xFFFFF8E7),
      borderColor: AppColors.accent.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bug_report_rounded,
                color: Color(0xFFB7791F),
                size: 20,
              ),
              const SizedBox(width: AppTheme.sp8),
              Text(
                l10n.debugSection,
                style: AppTextStyles.titleMedium(
                  color: const Color(0xFF7A4A00),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.sp12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              l10n.isLoggedInMock,
              style: AppTextStyles.bodyMedium(),
            ),
            value: account.isLoggedIn,
            onChanged: (val) async {
              await account.debugSetLoggedIn(val);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              l10n.isPremiumMock,
              style: AppTextStyles.bodyMedium(),
            ),
            value: account.isPremium,
            onChanged: (val) async {
              await account.debugSetPremium(val);
            },
          ),
          const SizedBox(height: AppTheme.sp8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l10n.resetFreeScans),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB7791F),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await account.resetFreeScans();
              },
            ),
          ),
        ],
      ),
    );
  }
}
