import '../../../core/models/app_user.dart';

sealed class AuthState {
  const AuthState();
}

class AuthUnknown extends AuthState {
  const AuthUnknown();
}

class AuthValidating extends AuthState {
  final AppUser user;
  const AuthValidating({required this.user});
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthAuthenticated extends AuthState {
  final String token;
  final AppUser user;

  const AuthAuthenticated({
    required this.token,
    required this.user,
  });
}
