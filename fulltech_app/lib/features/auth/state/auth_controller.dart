import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

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
        if (kDebugMode) {
          debugPrint(
            '[AUTH] unauthorized event status=${event.statusCode} detail=${event.detail ?? ''}',
          );
        }
        // Clear session immediately on 401 to avoid re-using expired tokens.
        await _db.clearSession();
        state = const AuthUnauthenticated();
      }
    });
  }

  Future<void> bootstrap() async {
    if (kDebugMode) debugPrint('[AUTH] bootstrap()');
    final session = await _db.readSession();
    if (session == null) {
      if (kDebugMode) debugPrint('[AUTH] bootstrap: no session');
      state = const AuthUnauthenticated();
      return;
    }

    if (kDebugMode) {
      debugPrint(
        '[AUTH] bootstrap: session found user=${session.user.email} role=${session.user.role}',
      );
    }

    // Validate token by attempting a simple request. If it fails (401),
    // the unauthorized event will be fired by the interceptor and we'll
    // transition to AuthUnauthenticated. Otherwise, set authenticated state.
    state = AuthAuthenticated(token: session.token, user: session.user);
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    if (kDebugMode) debugPrint('[AUTH] login() email=$email');
    final result = await _api.login(email: email, password: password);
    final session = AuthSession(token: result.token, user: result.user);
    await _db.saveSession(session);
    if (kDebugMode) {
      debugPrint('[AUTH] login: saved session role=${session.user.role}');
    }
    state = AuthAuthenticated(token: session.token, user: session.user);
  }

  Future<void> logout() async {
    if (kDebugMode) debugPrint('[AUTH] logout()');
    await _db.clearSession();
    state = const AuthUnauthenticated();
  }

  @override
  void dispose() {
    _eventsSub.cancel();
    super.dispose();
  }
}
