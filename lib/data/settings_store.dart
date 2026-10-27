import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wrapper around SharedPreferences for all app settings and account flags.
/// Extends ChangeNotifier so that locale/language changes rebuild the whole app.
class SettingsStore extends ChangeNotifier {
  static const _kLanguageCode = 'language_code';
  static const _kOnboardingDone = 'onboarding_done';
  static const _kIsLoggedIn = 'is_logged_in';
  static const _kIsPremium = 'is_premium';
  static const _kFreeScansLeft = 'free_scans_left';
  static const _kUserName = 'user_name';
  static const _kUserEmail = 'user_email';
  static const _kSchoolName = 'school_name';
  static const _kLessonPlanNotify = 'lesson_plan_notify';
  static const _kLessonPlanPoll = 'lesson_plan_poll';

  static const int maxFreeScans = 20;

  final SharedPreferences _prefs;

  SettingsStore._(this._prefs);

  static Future<SettingsStore> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsStore._(prefs);
  }

  // ── Language ────────────────────────────────────────────────────────────
  String get languageCode => _prefs.getString(_kLanguageCode) ?? 'en';

  Future<void> setLanguageCode(String code) async {
    await _prefs.setString(_kLanguageCode, code);
    notifyListeners(); // triggers MaterialApp locale rebuild
  }

  // ── Onboarding ───────────────────────────────────────────────────────────
  bool get onboardingDone => _prefs.getBool(_kOnboardingDone) ?? false;
  Future<void> setOnboardingDone() async {
    await _prefs.setBool(_kOnboardingDone, true);
    notifyListeners();
  }

  // ── Account ──────────────────────────────────────────────────────────────
  bool get isLoggedIn => _prefs.getBool(_kIsLoggedIn) ?? false;
  Future<void> setIsLoggedIn(bool v) async {
    await _prefs.setBool(_kIsLoggedIn, v);
  }

  bool get isPremium => _prefs.getBool(_kIsPremium) ?? false;
  Future<void> setIsPremium(bool v) async {
    await _prefs.setBool(_kIsPremium, v);
  }

  int get freeScansLeft => _prefs.getInt(_kFreeScansLeft) ?? maxFreeScans;
  Future<void> setFreeScansLeft(int v) async {
    await _prefs.setInt(_kFreeScansLeft, v);
  }

  String? get userName => _prefs.getString(_kUserName);
  Future<void> setUserName(String? v) async {
    if (v != null) {
      await _prefs.setString(_kUserName, v);
    } else {
      await _prefs.remove(_kUserName);
    }
  }

  String? get userEmail => _prefs.getString(_kUserEmail);
  Future<void> setUserEmail(String? v) async {
    if (v != null) {
      await _prefs.setString(_kUserEmail, v);
    } else {
      await _prefs.remove(_kUserEmail);
    }
  }

  String? get schoolName => _prefs.getString(_kSchoolName);
  Future<void> setSchoolName(String? v) async {
    if (v != null) {
      await _prefs.setString(_kSchoolName, v);
    } else {
      await _prefs.remove(_kSchoolName);
    }
  }

  // ── Lesson Plans ─────────────────────────────────────────────────────────
  bool get lessonPlanNotifyMe => _prefs.getBool(_kLessonPlanNotify) ?? false;
  Future<void> setLessonPlanNotifyMe(bool v) async {
    await _prefs.setBool(_kLessonPlanNotify, v);
    notifyListeners();
  }

  String get lessonPlanPollSelection =>
      _prefs.getString(_kLessonPlanPoll) ?? '';
  Future<void> setLessonPlanPollSelection(String v) async {
    await _prefs.setString(_kLessonPlanPoll, v);
    notifyListeners();
  }
}
