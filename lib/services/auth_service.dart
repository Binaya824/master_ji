import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// ── Storage key constants ────────────────────────────────────────────────────
const String _keyAccessToken = 'access_token';
const String _keyAccessTokenExpiry = 'access_token_expiry'; // ISO8601 string
const String _keySecretKey = 'secret_key';
const String _keySecretKeyType = 'secret_key_type';
const String _keySecretKeyExpiry = 'secret_key_expiry'; // ISO8601 string
const String _keyDemoScansRemaining =
    'demo_scans_remaining'; // stored as string
const String _keyMembershipType = 'membership_type';
const String _keyUserName = 'user_name';
const String _keyUserMobile = 'user_mobile';
const String _keyDeviceId = 'device_id'; // stored in normal SharedPreferences

/// Exception thrown by [AuthService.checkBeforeScan].
class AuthGuardException implements Exception {
  final String message;
  final AuthGuardReason reason;

  const AuthGuardException(this.message, this.reason);

  @override
  String toString() => 'AuthGuardException(${reason.name}): $message';
}

/// Reasons a scan may be blocked.
enum AuthGuardReason {
  notLoggedIn,
  sessionExpired,
  noSecretKey,
  demoLimitReached,
  subscriptionExpired,
}

/// Mobile + password authentication service for MasterJi.
///
/// Sensitive data (access token, secret key, etc.) are persisted in
/// [FlutterSecureStorage]. The non-sensitive device_id is stored in
/// [SharedPreferences] so it survives across reinstalls on the same device.
///
/// TODO: Change [_baseUrl] to your server URL before release.
class AuthService extends ChangeNotifier {
  // Global singleton instance for direct access from services like OmrService.
  static AuthService? instance;

  AuthService() {
    instance = this;
  }

  // Base URL auto-detects the running platform:
  // - Android emulator uses http://10.0.2.2:3000/api
  // - Linux desktop / macOS / Windows / iOS simulator uses http://localhost:3000/api
  // - Can be overridden via --dart-define=API_URL=http://your-server-ip:3000/api
  static String get _baseUrl {
    const fromEnv = String.fromEnvironment('API_URL');
    if (fromEnv.isNotEmpty) return '$fromEnv/api';
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    }
    return 'http://localhost:3000/api';
  }

  /// Hard-coded demo scan limit, tracked purely on-device (never stored on the
  /// server). When the local count hits 0 the app reports it once via
  /// POST /api/auth/demo-completed.
  static const int _maxDemoScans = 20;

  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  // ── In-memory cache (populated at startup from secure storage) ───────────
  String? _accessToken;
  DateTime? _accessTokenExpiry;
  String? _secretKey;
  String? _secretKeyType;
  DateTime? _secretKeyExpiry;
  int _demoScansRemaining = 0;
  String _membershipType = 'none';
  String? _userName;
  String? _userMobile;

  // ── Getters ──────────────────────────────────────────────────────────────

  /// True when the user has a valid, non-expired access token.
  /// If the token has expired (> 5 days), automatically triggers local session wipe.
  bool get isLoggedIn {
    if (_accessToken == null || _accessTokenExpiry == null) return false;
    if (DateTime.now().isAfter(_accessTokenExpiry!)) {
      _clearAuthData();
      return false;
    }
    return true;
  }

  String? get secretKey => _secretKey;
  String? get secretKeyType => _secretKeyType;
  DateTime? get secretKeyExpiry => _secretKeyExpiry;
  int get demoScansRemaining => _demoScansRemaining;
  String get membershipType => _membershipType;
  String? get userName => _userName;
  String? get userMobile => _userMobile;

  // ── Auth guard ──────────────────────────────────────────────────────────

  /// Checks locally (no network) whether a scan is allowed.
  /// Throws [AuthGuardException] if not.
  void checkBeforeScan() {
    // 1. Check access token presence
    if (_accessToken == null) {
      throw const AuthGuardException(
        'Please log in first.',
        AuthGuardReason.notLoggedIn,
      );
    }

    // 2. Check token expiry (5-day TTL). If expired, auto-wipe session locally.
    if (_accessTokenExpiry == null ||
        DateTime.now().isAfter(_accessTokenExpiry!)) {
      _clearAuthData();
      notifyListeners();
      throw const AuthGuardException(
        'Session expired. Please log in again.',
        AuthGuardReason.sessionExpired,
      );
    }

    // 3. Check secret key
    if (_secretKey == null || _secretKey!.isEmpty) {
      throw const AuthGuardException(
        'No licence key found. Please contact admin.',
        AuthGuardReason.noSecretKey,
      );
    }

    // 4. Type-specific checks
    if (_secretKeyType == 'demo') {
      if (_demoScansRemaining <= 0) {
        throw const AuthGuardException(
          'Demo limit of 20 scans reached. Please upgrade.',
          AuthGuardReason.demoLimitReached,
        );
      }
    } else if (_secretKeyType == 'paid') {
      if (_secretKeyExpiry != null &&
          DateTime.now().isAfter(_secretKeyExpiry!)) {
        throw const AuthGuardException(
          'Your subscription has expired. Please renew.',
          AuthGuardReason.subscriptionExpired,
        );
      }
    }
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────

  /// Load all persisted auth data into memory. Call once at app startup
  /// before [runApp].
  Future<void> init() async {
    try {
      _accessToken = await _secure.read(key: _keyAccessToken);

      final expiryStr = await _secure.read(key: _keyAccessTokenExpiry);
      _accessTokenExpiry =
          expiryStr != null ? DateTime.tryParse(expiryStr) : null;

      // Auto-logout: if access token has expired (> 5 days), wipe local session
      if (_accessToken != null &&
          (_accessTokenExpiry == null ||
              DateTime.now().isAfter(_accessTokenExpiry!))) {
        await _clearAuthData();
        notifyListeners();
        return;
      }

      _secretKey = await _secure.read(key: _keySecretKey);
      _secretKeyType = await _secure.read(key: _keySecretKeyType);

      final skExpiryStr = await _secure.read(key: _keySecretKeyExpiry);
      _secretKeyExpiry =
          skExpiryStr != null ? DateTime.tryParse(skExpiryStr) : null;

      _membershipType =
          (await _secure.read(key: _keyMembershipType)) ?? _membershipType;

      // Demo scan count is tracked purely on-device. If a demo user has no
      // stored count yet (fresh install), they start with the full 20 scans.
      final demoStr = await _secure.read(key: _keyDemoScansRemaining);
      if (demoStr != null) {
        _demoScansRemaining = int.tryParse(demoStr) ?? _demoScansRemaining;
      } else if (_membershipType == 'demo') {
        _demoScansRemaining = _maxDemoScans;
        await _secure.write(
          key: _keyDemoScansRemaining,
          value: _demoScansRemaining.toString(),
        );
      }
      _userName = await _secure.read(key: _keyUserName);
      _userMobile = await _secure.read(key: _keyUserMobile);
    } catch (e) {
      debugPrint('AuthService.init error: $e');
    }
    notifyListeners();
  }

  // ── API calls ────────────────────────────────────────────────────────────

  /// Register a new account.
  ///
  /// Returns `null` on success, or a human-readable error message on failure.
  Future<String?> register({
    required String name,
    required String mobile,
    required String password,
  }) async {
    try {
      final deviceId = await _getDeviceId();
      final url = Uri.parse('$_baseUrl/auth/register');
      debugPrint('[Auth] Registering to: $url');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'mobile': mobile,
              'password': password,
              'device_id': deviceId,
            }),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint(
          '[Auth] Register response (${response.statusCode}): ${response.body}');
      final body = _decodeResponse(response);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return null; // success
      }

      return body['message'] as String? ??
          body['error'] as String? ??
          'Registration failed (${response.statusCode}).';
    } on http.ClientException catch (e) {
      debugPrint('[Auth] ClientException: $e');
      return 'Network error: ${e.message}';
    } on TimeoutException {
      debugPrint('[Auth] Register request timed out');
      return 'Connection timed out. Is the server running?';
    } catch (e) {
      debugPrint('[Auth] Register error: $e');
      return 'Connection error: $e';
    }
  }

  /// Log in with mobile number and password.
  ///
  /// Returns `null` on success, or a human-readable error message on failure.
  Future<String?> login({
    required String mobile,
    required String password,
  }) async {
    try {
      final deviceId = await _getDeviceId();
      final url = Uri.parse('$_baseUrl/auth/login');
      debugPrint('[Auth] Logging in to: $url');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'mobile': mobile,
              'password': password,
              'device_id': deviceId,
              // Whatever this device currently has cached (may be null, e.g.
              // after a reinstall/data wipe) - the server uses this to spot
              // demo-scan farming instead of a login-history time window.
              'secret_key': _secretKey,
              'membership_type':
                  _membershipType == 'none' ? null : _membershipType,
            }),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint(
          '[Auth] Login response (${response.statusCode}): ${response.body}');
      final body = _decodeResponse(response);

      if (response.statusCode == 200) {
        await _saveAuthData(body);
        notifyListeners();
        return null; // success
      }

      return body['message'] as String? ??
          body['error'] as String? ??
          'Login failed (${response.statusCode}).';
    } on http.ClientException catch (e) {
      debugPrint('[Auth] ClientException: $e');
      return 'Network error: ${e.message}';
    } on TimeoutException {
      debugPrint('[Auth] Login request timed out');
      return 'Connection timed out. Is the server running?';
    } catch (e) {
      debugPrint('[Auth] Login error: $e');
      return 'Connection error: $e';
    }
  }

  /// Log out: clear only the access token (and its expiry) from local
  /// secure storage and memory. Secret key, membership type, demo-scan
  /// count, and profile info are intentionally kept, so logging back in
  /// doesn't hand out a fresh demo count. 100% local — no server call.
  Future<void> logout() async {
    _accessToken = null;
    _accessTokenExpiry = null;
    await _secure.delete(key: _keyAccessToken);
    await _secure.delete(key: _keyAccessTokenExpiry);
    notifyListeners();
  }

  /// Call after a successful scan.
  ///
  /// For demo users, decrements the local counter. Once the 20-scan demo limit
  /// is reached (count becomes 0), the secret key is automatically deleted
  /// locally. No server calls are made.
  Future<void> onScanCompleted() async {
    if (_membershipType != 'demo') return;

    // Decrement locally.
    if (_demoScansRemaining > 0) {
      _demoScansRemaining--;
      await _secure.write(
        key: _keyDemoScansRemaining,
        value: _demoScansRemaining.toString(),
      );
      // Once demo scans are finished, clear the secret key automatically and
      // report it to the server once (fire-and-forget) so the account is
      // marked demo-completed in the DB.
      if (_demoScansRemaining <= 0) {
        _secretKey = null;
        _secretKeyType = null;
        _membershipType = 'none';
        await _secure.delete(key: _keySecretKey);
        await _secure.delete(key: _keySecretKeyType);
        await _secure.write(key: _keyMembershipType, value: 'none');
        unawaited(_notifyDemoCompleted());
      }
      notifyListeners();
    }
  }

  /// Reports to the server that this account's 20-scan demo finished, so the
  /// user's secret key is cleared in the DB as well. Best-effort: failures are
  /// silently ignored — the local key is already cleared, and on the next
  /// login the server refuses to hand out a key to demo-completed accounts.
  Future<void> _notifyDemoCompleted() async {
    final token = _accessToken;
    if (token == null) return;
    try {
      await http.post(
        Uri.parse('$_baseUrl/auth/demo-completed'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('[Auth] demo-completed report failed (ignored): $e');
    }
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  /// Returns a stable device identifier used for one-account-one-device
  /// binding. On Android this is the real ANDROID_ID
  /// (Settings.Secure.ANDROID_ID, fetched natively via the
  /// `masterji/device_id` channel) — stable per device & app signing key and
  /// survives uninstall/reinstall (so login after reinstall keeps the same
  /// binding and can't be used to farm a second session/demo count).
  /// Note: device_info_plus's androidInfo.id is Build.ID (an OS firmware build
  /// string, identical across devices) — NOT a usable device ID, and the
  /// plugin no longer exposes ANDROID_ID.
  /// On other platforms, falls back to a random UUID persisted in
  /// SharedPreferences.
  static const MethodChannel _deviceIdChannel =
      MethodChannel('masterji/device_id');

  Future<String> _getDeviceId() async {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final androidId =
            await _deviceIdChannel.invokeMethod<String>('getAndroidId');
        if (androidId != null &&
            androidId.isNotEmpty &&
            androidId.toLowerCase() != 'unknown') {
          return androidId;
        }
        debugPrint('[Auth] ANDROID_ID unavailable, falling back to UUID');
      }
    } catch (e) {
      debugPrint('[Auth] ANDROID_ID fetch failed, falling back to UUID: $e');
    }

    // Fallback: persistently stored random UUID (desktop/web/simulator).
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_keyDeviceId);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await prefs.setString(_keyDeviceId, id);
    }
    return id;
  }

  /// Persist auth data returned by the login endpoint.
  ///
  /// Expected response shape (all fields optional — missing ones are ignored):
  /// ```json
  /// {
  ///   "access_token": "...",
  ///   "expires_at": "2026-12-31T00:00:00Z",   // ISO8601
  ///   "secret_key": "...",
  ///   "secret_key_type": "demo" | "paid",
  ///   "secret_key_expiry": "2026-12-31T00:00:00Z",
  ///   "demo_scans_remaining": 20,
  ///   "membership_type": "demo" | "paid" | "none",
  ///   "user": { "name": "...", "mobile": "..." }
  /// }
  /// ```
  Future<void> _saveAuthData(Map<String, dynamic> data) async {
    final token = data['access_token'] as String?;
    final expiresAt = data['expires_at'] as String?;
    final secretKey = data['secret_key'] as String?;
    final secretKeyType = data['secret_key_type'] as String?;
    final secretKeyExpiry = data['secret_key_expiry'] as String?;
    final demoScans = data['demo_scans_remaining'];
    final membership = data['membership_type'] as String?;
    final user = data['user'] as Map<String, dynamic>?;
    final name = (data['name'] as String?) ?? (user?['name'] as String?);
    final mobile = (data['mobile'] as String?) ?? (user?['mobile'] as String?);

    // Write to secure storage
    if (token != null) {
      await _secure.write(key: _keyAccessToken, value: token);
      _accessToken = token;
    }
    if (expiresAt != null) {
      await _secure.write(key: _keyAccessTokenExpiry, value: expiresAt);
      _accessTokenExpiry = DateTime.tryParse(expiresAt);
    }
    if (secretKey != null) {
      await _secure.write(key: _keySecretKey, value: secretKey);
      _secretKey = secretKey;
    }
    if (secretKeyType != null) {
      await _secure.write(key: _keySecretKeyType, value: secretKeyType);
      _secretKeyType = secretKeyType;
    }
    if (secretKeyExpiry != null) {
      await _secure.write(key: _keySecretKeyExpiry, value: secretKeyExpiry);
      _secretKeyExpiry = DateTime.tryParse(secretKeyExpiry);
    }
    if (demoScans != null) {
      // Server MAY still send demo_scans_remaining (older servers); if absent,
      // keep the on-device count loaded in init() — the server no longer
      // stores or sends it.
      final count = demoScans is int ? demoScans : int.tryParse('$demoScans');
      if (count != null) {
        await _secure.write(
          key: _keyDemoScansRemaining,
          value: count.toString(),
        );
        _demoScansRemaining = count;
      }
    }
    if (membership != null) {
      await _secure.write(key: _keyMembershipType, value: membership);
      _membershipType = membership;
    }
    if (name != null) {
      await _secure.write(key: _keyUserName, value: name);
      _userName = name;
    }
    if (mobile != null) {
      await _secure.write(key: _keyUserMobile, value: mobile);
      _userMobile = mobile;
    }
  }

  /// Wipe all auth data from memory and secure storage.
  Future<void> _clearAuthData() async {
    _accessToken = null;
    _accessTokenExpiry = null;
    _secretKey = null;
    _secretKeyType = null;
    _secretKeyExpiry = null;
    _demoScansRemaining = 0;
    _membershipType = 'none';
    _userName = null;
    _userMobile = null;

    await Future.wait([
      _secure.delete(key: _keyAccessToken),
      _secure.delete(key: _keyAccessTokenExpiry),
      _secure.delete(key: _keySecretKey),
      _secure.delete(key: _keySecretKeyType),
      _secure.delete(key: _keySecretKeyExpiry),
      _secure.delete(key: _keyDemoScansRemaining),
      _secure.delete(key: _keyMembershipType),
      _secure.delete(key: _keyUserName),
      _secure.delete(key: _keyUserMobile),
    ]);
  }

  /// Decode an HTTP response body as JSON. Returns an empty map on error.
  Map<String, dynamic> _decodeResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return {};
  }
}
