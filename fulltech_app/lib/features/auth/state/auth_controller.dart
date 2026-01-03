import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/auth_events.dart';
import '../../../core/services/auth_api.dart';
import '../../../core/storage/local_db.dart';
import 'auth_state.dart';

import 'dart:async';

class AuthController extends StateNotifier<AuthState> {
  final LocalDb _db;
  final AuthApi _api;

  late final StreamSubscription<AuthEvent> _eventsSub;

  AuthController({
    required LocalDb db,
    required AuthApi api,
  })  : _db = db,
        _api = api,
        super(const AuthUnknown()) {
    _eventsSub = AuthEvents.stream.listen((event) async {
      if (event.type == AuthEventType.unauthorized) {
        // Keep it idempotent: interceptor already cleared session.
        state = const AuthUnauthenticated();
      }
    });
  }

  Future<void> bootstrap() async {
    final session = await _db.readSession();
    if (session == null) {
      state = const AuthUnauthenticated();
      return;
    }

    state = AuthAuthenticated(token: session.token, user: session.user);
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final result = await _api.login(email: email, password: password);
    final session = AuthSession(token: result.token, user: result.user);
    await _db.saveSession(session);
    state = AuthAuthenticated(token: session.token, user: session.user);
  }

  Future<void> logout() async {
    await _db.clearSession();
    state = const AuthUnauthenticated();
  }

  @override
  void dispose() {
    _eventsSub.cancel();
    super.dispose();
  }
}
