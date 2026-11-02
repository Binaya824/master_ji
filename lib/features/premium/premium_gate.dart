import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/account_state.dart';
import '../../services/auth_service.dart';
import '../../services/omr_service.dart';
import 'premium_sheet.dart';

/// Helper that checks whether the user can use a premium feature.
/// If they can, runs [action]; otherwise shows the [PremiumSheet].
///
/// Usage:
/// ```dart
/// PremiumGate.runOrShowSheet(context, canUseExams, () => context.go('/exams'));
/// ```
abstract final class PremiumGate {
  /// Runs [action] if [allowed] is true; otherwise shows the premium sheet.
  static Future<void> runOrShowSheet(
    BuildContext context,
    bool allowed,
    VoidCallback action,
  ) async {
    if (allowed) {
      action();
    } else {
      await PremiumSheet.show(context);
    }
  }

  /// Convenience: checks [AccountState.canUseExams] and runs [action] or shows sheet.
  static Future<void> examOrSheet(
    BuildContext context,
    VoidCallback action,
  ) async {
    final account = context.read<AccountState>();
    await runOrShowSheet(context, account.canUseExams, action);
  }

  /// Handles an OMR scan being blocked by the auth/key gate ([OmrUnauthorizedException]).
  ///
  /// When the block is a licensing issue — no secret key, demo limit (20 scans)
  /// reached, or an expired subscription — the premium upsell sheet is shown so
  /// the user can go for premium. Login-related blocks and other failures fall
  /// back to a plain error snackbar with the underlying message.
  static Future<void> handleScanBlock(
    BuildContext context,
    Object error,
  ) async {
    if (error is OmrUnauthorizedException) {
      switch (error.reason) {
        case AuthGuardReason.noSecretKey:
        case AuthGuardReason.demoLimitReached:
        case AuthGuardReason.subscriptionExpired:
          if (context.mounted) await PremiumSheet.show(context);
          return;
        case AuthGuardReason.notLoggedIn:
        case AuthGuardReason.sessionExpired:
        case _:
          break;
      }
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Could not scan: ${error.toString().replaceAll(RegExp(r'^(Exception: |Unauthorized: )'), '')}',
        ),
        backgroundColor: Colors.red,
      ),
    );
  }
}
