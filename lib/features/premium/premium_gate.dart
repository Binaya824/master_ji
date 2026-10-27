import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/account_state.dart';
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
}
