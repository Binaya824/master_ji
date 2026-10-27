import 'package:flutter/foundation.dart';

import 'settings_store.dart';

/// Central account state — all premium/login checks go through this class.
/// Never scatter `if (isPremium)` checks across screens; use [canUseExams] and
/// [canQuickScan] instead.
class AccountState extends ChangeNotifier {
  final SettingsStore _store;

  AccountState(this._store);

  // ── Read-only getters ────────────────────────────────────────────────────
  bool get isLoggedIn => _store.isLoggedIn;
  bool get isPremium => _store.isPremium;
  int get freeScansLeft => _store.freeScansLeft;
  String? get userName => _store.userName;
  String? get userEmail => _store.userEmail;
  String? get schoolName => _store.schoolName;

  // ── Feature gates ────────────────────────────────────────────────────────

  /// Can the user create / use exams? (Premium only)
  bool get canUseExams => isPremium;

  /// Can the user scan another student sheet in Quick Scan?
  /// Premium users: always yes. Free users: while freeScansLeft > 0.
  bool get canQuickScan => isPremium || freeScansLeft > 0;

  // ── Mutations ────────────────────────────────────────────────────────────

  Future<void> login({
    required String name,
    required String email,
  }) async {
    await _store.setIsLoggedIn(true);
    await _store.setUserName(name);
    await _store.setUserEmail(email);
    notifyListeners();
  }

  Future<void> logout() async {
    await _store.setIsLoggedIn(false);
    await _store.setIsPremium(false);
    // Keep local exam data; do NOT reset freeScansLeft on logout
    notifyListeners();
  }

  Future<void> setPremium(bool value) async {
    await _store.setIsPremium(value);
    notifyListeners();
  }

  /// Decrements the free scan counter by 1. Call only for Quick Scan student
  /// sheets (not for answer-key scans). No-op if already at 0 or user is premium.
  Future<void> decrementFreeScan() async {
    if (isPremium) return;
    final current = freeScansLeft;
    if (current <= 0) return;
    await _store.setFreeScansLeft(current - 1);
    notifyListeners();
  }

  Future<void> resetFreeScans() async {
    await _store.setFreeScansLeft(SettingsStore.maxFreeScans);
    notifyListeners();
  }

  Future<void> setSchoolName(String? name) async {
    await _store.setSchoolName(name);
    notifyListeners();
  }

  // ── Debug helpers (kDebugMode only) ─────────────────────────────────────

  Future<void> debugSetLoggedIn(bool v) async {
    assert(kDebugMode);
    if (v) {
      await login(name: 'Teacher', email: 'teacher@example.com');
    } else {
      await logout();
    }
  }

  Future<void> debugSetPremium(bool v) async {
    assert(kDebugMode);
    await setPremium(v);
  }
}
