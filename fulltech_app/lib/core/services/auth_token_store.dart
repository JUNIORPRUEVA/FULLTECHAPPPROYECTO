class AuthTokenStore {
  AuthTokenStore._();

  static String? _token;

  static String? get token => _token;

  static void set(String? token) {
    final t = (token ?? '').trim();
    _token = t.isEmpty ? null : t;
  }

  static void clear() {
    _token = null;
  }
}
