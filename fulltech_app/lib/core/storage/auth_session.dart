import '../models/app_user.dart';

class AuthSession {
  final String token;
  final String? refreshToken;
  final AppUser user;

  const AuthSession({
    required this.token,
    required this.refreshToken,
    required this.user,
  });

  Map<String, dynamic> toJson() => {
        'token': token,
        'refreshToken': refreshToken,
        'user': user.toJson(),
      };

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      token: json['token'] as String,
      refreshToken: (json['refreshToken'] as String?) ??
          (json['refresh_token'] as String?),
      user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
