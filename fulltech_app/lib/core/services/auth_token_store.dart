class AuthTokenStore {
  AuthTokenStore._();

  static String? _token;
  static String? _refreshToken;

  static String? get token => _token;
  static String? get refreshToken => _refreshToken;

  static void set(String? token) {
    final t = (token ?? '').trim();
    _token = t.isEmpty ? null : t;
  }

  static void setRefreshToken(String? refreshToken) {
    final t = (refreshToken ?? '').trim();
    _refreshToken = t.isEmpty ? null : t;
  }

  static void clear() {
    _token = null;
    _refreshToken = null;
  }
}
