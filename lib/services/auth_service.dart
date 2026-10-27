/// User data returned by a successful sign-in.
class AuthUser {
  final String name;
  final String email;

  const AuthUser({required this.name, required this.email});
}

/// Abstract interface for authentication.
/// Swap [MockAuthService] for the real Firebase/Google Sign-In implementation
/// in main.dart — one line.
abstract class AuthService {
  /// Signs in with Google. Returns the signed-in user, or null if cancelled.
  Future<AuthUser?> signInWithGoogle();

  /// Signs out the current user.
  Future<void> signOut();
}
