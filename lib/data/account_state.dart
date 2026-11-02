import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';
import 'settings_store.dart';

/// Central account state — all premium/login checks go through this class.
/// Never scatter `if (isPremium)` checks across screens; use [canUseExams] and
/// [canQuickScan] instead.
///
/// Reads authentication status from [AuthService] (source of truth for login /
/// secret-key state) and feature-gate flags from [SettingsStore].
class AccountState extends ChangeNotifier {
  final SettingsStore _store;
  final AuthService _auth;

  AccountState(this._store, this._auth) {
    // Propagate AuthService changes (login / logout / scan count) to listeners.
    _auth.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() => notifyListeners();

  // ── Read-only getters ────────────────────────────────────────────────────

  /// True when the user has a valid session (via AuthService).
  bool get isLoggedIn => _auth.isLoggedIn;

  /// Paid users with an active subscription are considered premium.
  bool get isPremium => _auth.membershipType == 'paid' && _auth.isLoggedIn;

  /// Remaining free scans (demo users only; 0 for paid/non-logged-in).
  int get freeScansLeft => _auth.demoScansRemaining;

  /// User's display name from AuthService (only when logged in).
  String? get userName =>
      _auth.isLoggedIn ? (_auth.userName ?? _store.userName) : null;

  /// User's mobile number from AuthService (only when logged in).
  String? get userMobile => _auth.isLoggedIn ? _auth.userMobile : null;

  /// Not used with mobile auth — kept for compatibility with profile UI.
  String? get userEmail => _store.userEmail;

  String? get schoolName => _store.schoolName;

  // ── Feature gates ────────────────────────────────────────────────────────

  /// Can the user create / use exams? (Premium only)
  bool get canUseExams => isPremium;

  /// Can the user scan another student sheet in Quick Scan?
  /// Premium users: always yes. Demo users: while freeScansLeft > 0.
  bool get canQuickScan => isPremium || freeScansLeft > 0;

  // ── Mutations ────────────────────────────────────────────────────────────

  /// Log out via [AuthService] and clear local flags and profile info.
  Future<void> logout() async {
    await _auth.logout();
    await _store.setIsLoggedIn(false);
    await _store.setIsPremium(false);
    await _store.setUserName(null);
    notifyListeners();
  }

  Future<void> setPremium(bool value) async {
    await _store.setIsPremium(value);
    notifyListeners();
  }

  /// Decrements the free scan counter by 1. Call only for Quick Scan student
  /// sheets (not for answer-key scans). No-op if already at 0 or user is premium.
  ///
  /// For demo users this delegates to [AuthService.onScanCompleted] which
  /// decrements the server-synced counter. For non-auth free scans it falls
  /// back to the SettingsStore counter.
  Future<void> decrementFreeScan() async {
    if (isPremium) return;
    if (_auth.isLoggedIn && _auth.membershipType == 'demo') {
      await _auth.onScanCompleted();
      return;
    }
    // Fallback for unauthenticated / non-demo users (legacy behaviour).
    final current = _store.freeScansLeft;
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
    if (!v) await logout();
    // For debug login, use AuthService.login() with test credentials instead.
  }

  Future<void> debugSetPremium(bool v) async {
    assert(kDebugMode);
    await setPremium(v);
  }
}
