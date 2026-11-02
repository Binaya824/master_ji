import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:master_ji/data/account_state.dart';
import 'package:master_ji/data/settings_store.dart';
import 'package:master_ji/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Mock flutter_secure_storage so AuthService calls (logout clears the
    // stored session, etc.) don't hit the missing platform plugin.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
  });

  Future<(SettingsStore, AccountState)> makeAccount() async {
    final store = await SettingsStore.create();
    final account = AccountState(store, AuthService());
    return (store, account);
  }

  group('AccountState initial state', () {
    test('starts not logged in, not premium', () async {
      final (_, a) = await makeAccount();
      expect(a.isLoggedIn, false);
      expect(a.isPremium, false);
    });

    test('canUseExams requires a paid session', () async {
      final (_, a) = await makeAccount();
      // Premium is session-driven now (membershipType == 'paid'),
      // so an anonymous session can never use exams.
      expect(a.canUseExams, false);
    });

    test('canQuickScan is false without demo scans remaining', () async {
      final (_, a) = await makeAccount();
      // A fresh AuthService has loaded no session (demoScansRemaining = 0),
      // so quick scan is not allowed.
      expect(a.canQuickScan, false);
    });
  });

  // Login / logout are server-driven now (AuthService.login performs the
  // HTTP call) and cannot be exercised in a unit test without mocking the
  // network layer. The state-propagation behaviour is covered by these
  // store-level tests instead.

  group('AccountState legacy fallback scan counter', () {
    // For non-logged-in / non-demo users decrementFreeScan() falls back to
    // the SettingsStore counter (legacy behaviour), which these tests cover.
    test('decrementFreeScan reduces the store counter by 1', () async {
      final (store, a) = await makeAccount();
      expect(store.freeScansLeft, 20);
      await a.decrementFreeScan();
      expect(store.freeScansLeft, 19);
    });

    test('decrementFreeScan never goes below 0', () async {
      final (store, a) = await makeAccount();
      for (int i = 0; i < 25; i++) {
        await a.decrementFreeScan();
      }
      expect(store.freeScansLeft, 0);
      expect(store.freeScansLeft, isNonNegative);
    });

    test('decrementFreeScan at 0 is a no-op', () async {
      final (store, a) = await makeAccount();
      for (int i = 0; i < 20; i++) {
        await a.decrementFreeScan();
      }
      expect(store.freeScansLeft, 0);
      await a.decrementFreeScan();
      expect(store.freeScansLeft, 0);
    });

    test('resetFreeScans resets the store counter to 20', () async {
      final (store, a) = await makeAccount();
      await a.decrementFreeScan();
      await a.decrementFreeScan();
      expect(store.freeScansLeft, 18);
      await a.resetFreeScans();
      expect(store.freeScansLeft, SettingsStore.maxFreeScans);
    });
  });

  group('AccountState store premium flag', () {
    test('setPremium toggles the store flag', () async {
      final (store, a) = await makeAccount();
      await a.debugSetPremium(true);
      expect(store.isPremium, true);
      await a.debugSetPremium(false);
      expect(store.isPremium, false);
    });

    test('logout clears store login/premium flags', () async {
      final (store, a) = await makeAccount();
      await a.debugSetPremium(true);
      await a.logout();
      expect(store.isLoggedIn, false);
      expect(store.isPremium, false);
      expect(a.isLoggedIn, false);
    });
  });
}
