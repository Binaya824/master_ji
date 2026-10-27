import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../data/settings_store.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.sp24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                l10n.chooseLanguage,
                style: AppTextStyles.headlineLarge(),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),
              const SizedBox(height: AppTheme.sp8),
              Text(
                l10n.tapToSwitch,
                style: AppTextStyles.bodyMedium(),
                textAlign: TextAlign.center,
              ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
              const SizedBox(height: AppTheme.sp32),

              // Language cards
              _LanguageCard(
                label: 'ଓଡ଼ିଆ',
                sublabel: 'Odia',
                flag: '🇮🇳',
                delay: 200,
                onTap: () => _selectLanguage(context, 'or'),
              ),
              const SizedBox(height: AppTheme.sp16),
              _LanguageCard(
                label: 'English',
                sublabel: 'ଇଂରାଜୀ',
                flag: '🇬🇧',
                delay: 300,
                onTap: () => _selectLanguage(context, 'en'),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectLanguage(BuildContext context, String code) async {
    final store = context.read<SettingsStore>();
    await store.setLanguageCode(code);
    if (!context.mounted) return;
    context.go(AppRoutes.login);
  }
}

class _LanguageCard extends StatelessWidget {
  final String label;
  final String sublabel;
  final String flag;
  final int delay;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.label,
    required this.sublabel,
    required this.flag,
    required this.delay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(color: AppColors.cardBorder),
          ),
          padding: const EdgeInsets.all(AppTheme.sp24),
          child: Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: AppTheme.sp16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.headlineMedium()),
                  Text(sublabel,
                      style: AppTextStyles.bodyMedium(
                          color: AppColors.textSecondary)),
                ],
              ),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: 350.ms)
        .slideX(begin: 0.1, end: 0);
  }
}
