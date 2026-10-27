import 'auth_service.dart';

/// Mock implementation of [AuthService] for development.
/// Simulates a 1-second sign-in delay and returns a fixed mock teacher account.
class MockAuthService implements AuthService {
  static const _delay = Duration(seconds: 1);

  @override
  Future<AuthUser?> signInWithGoogle() async {
    await Future.delayed(_delay);
    return const AuthUser(
      name: 'Teacher',
      email: 'teacher@example.com',
    );
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
