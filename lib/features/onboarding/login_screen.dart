import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../data/account_state.dart';
import '../../data/settings_store.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  final bool fromPremiumSheet;

  const LoginScreen({super.key, this.fromPremiumSheet = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthService>();
      final user = await auth.signInWithGoogle();
      if (!mounted) return;
      if (user != null) {
        await context.read<AccountState>().login(
              name: user.name,
              email: user.email,
            );
        if (!mounted) return;
        await context.read<SettingsStore>().setOnboardingDone();
        if (!mounted) return;
        context.go(AppRoutes.home);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _skip() async {
    await context.read<SettingsStore>().setOnboardingDone();
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.sp24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),

              // Logo
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.document_scanner_rounded,
                    size: 44,
                    color: AppColors.primary,
                  ),
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    duration: 500.ms,
                    curve: Curves.easeOutBack,
                  )
                  .fadeIn(duration: 400.ms),

              const SizedBox(height: AppTheme.sp24),

              Text(
                'MasterJi',
                style: AppTextStyles.headlineLarge(),
                textAlign: TextAlign.center,
              ).animate(delay: 150.ms).fadeIn(duration: 400.ms),

              const SizedBox(height: AppTheme.sp8),
              Text(
                l10n.checkOMRInSeconds,
                style: AppTextStyles.bodyLarge(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ).animate(delay: 250.ms).fadeIn(duration: 400.ms),

              const Spacer(flex: 2),

              // Google button
              _GoogleSignInButton(
                label: l10n.continueWithGoogle,
                loading: _loading,
                onPressed: _signIn,
              ).animate(delay: 400.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: AppTheme.sp16),

              // Skip
              Column(
                children: [
                  TextButton(
                    onPressed: _loading ? null : _skip,
                    child: Text(l10n.skipForNow),
                  ),
                  const SizedBox(height: AppTheme.sp4),
                  Text(
                    l10n.youGet20FreeScans,
                    style: AppTextStyles.bodySmall(),
                    textAlign: TextAlign.center,
                  ),
                ],
              ).animate(delay: 500.ms).fadeIn(duration: 400.ms),

              const SizedBox(height: AppTheme.sp32),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const _GoogleSignInButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.15),
      borderRadius: BorderRadius.circular(AppTheme.radiusButton),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: loading ? null : onPressed,
        child: Container(
          height: AppTheme.minTouchTarget,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusButton),
            border: Border.all(color: const Color(0xFFDDE3EA), width: 1),
          ),
          child: loading
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation(AppColors.textSecondary),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Google G logo (simplified coloured version)
                    _GoogleLogo(),
                    const SizedBox(width: AppTheme.sp12),
                    Text(
                      label,
                      style: AppTextStyles.titleMedium(),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

/// Simplified Google "G" logo using CustomPaint.
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()..style = PaintingStyle.fill;

    // Draw the four coloured arcs of the "G"
    // Blue top-right
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        -1.57, 1.57, true, paint);

    // Red top-left
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        -3.14, 1.57, true, paint);

    // Yellow bottom-left
    paint.color = const Color(0xFFFBBC04);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        1.57, 0.79, true, paint);

    // Green bottom-right
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        2.36, 0.79, true, paint);

    // White inner circle
    paint.color = Colors.white;
    canvas.drawCircle(center, radius * 0.55, paint);

    // Blue right bar of the G
    paint.color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.5, size.height * 0.4,
          size.width * 0.5, size.height * 0.2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
