import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:omr_scanner/data/account_state.dart';
import 'package:omr_scanner/data/settings_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<AccountState> makeAccount() async {
    final store = await SettingsStore.create();
    return AccountState(store);
  }

  group('AccountState initial state', () {
    test('starts not logged in, not premium', () async {
      final a = await makeAccount();
      expect(a.isLoggedIn, false);
      expect(a.isPremium, false);
    });

    test('freeScansLeft starts at 20', () async {
      final a = await makeAccount();
      expect(a.freeScansLeft, 20);
    });

    test('canUseExams requires premium', () async {
      final a = await makeAccount();
      expect(a.canUseExams, false);
    });

    test('canQuickScan is true when scans remain', () async {
      final a = await makeAccount();
      expect(a.canQuickScan, true);
    });
  });

  group('AccountState login/logout', () {
    test('login sets isLoggedIn and user info', () async {
      final a = await makeAccount();
      await a.login(name: 'Teacher', email: 'teacher@test.com');
      expect(a.isLoggedIn, true);
      expect(a.userName, 'Teacher');
      expect(a.userEmail, 'teacher@test.com');
    });

    test('logout clears login state', () async {
      final a = await makeAccount();
      await a.login(name: 'Teacher', email: 'teacher@test.com');
      await a.logout();
      expect(a.isLoggedIn, false);
      expect(a.isPremium, false);
    });
  });

  group('AccountState premium', () {
    test('setPremium true enables canUseExams', () async {
      final a = await makeAccount();
      await a.setPremium(true);
      expect(a.isPremium, true);
      expect(a.canUseExams, true);
    });

    test('premium user can always quick scan', () async {
      final a = await makeAccount();
      await a.setPremium(true);
      // Even if somehow scans are 0 (shouldn't happen normally)
      expect(a.canQuickScan, true);
    });
  });

  group('AccountState free scan counter', () {
    test('decrementFreeScan reduces count by 1', () async {
      final a = await makeAccount();
      expect(a.freeScansLeft, 20);
      await a.decrementFreeScan();
      expect(a.freeScansLeft, 19);
    });

    test('decrementFreeScan does not go below 0', () async {
      final a = await makeAccount();
      for (int i = 0; i < 25; i++) {
        await a.decrementFreeScan();
      }
      expect(a.freeScansLeft, 0);
    });

    test('canQuickScan is false at 0 scans (non-premium)', () async {
      final a = await makeAccount();
      for (int i = 0; i < 20; i++) {
        await a.decrementFreeScan();
      }
      expect(a.freeScansLeft, 0);
      expect(a.canQuickScan, false);
    });

    test('resetFreeScans resets to 20', () async {
      final a = await makeAccount();
      await a.decrementFreeScan();
      await a.decrementFreeScan();
      expect(a.freeScansLeft, 18);
      await a.resetFreeScans();
      expect(a.freeScansLeft, 20);
    });

    test('premium user decrement is no-op', () async {
      final a = await makeAccount();
      await a.setPremium(true);
      await a.decrementFreeScan();
      // freeScansLeft unchanged for premium users
      expect(a.freeScansLeft, 20);
    });
  });
}
