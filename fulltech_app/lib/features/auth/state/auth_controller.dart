import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

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

    // IMPORTANT: Avoid treating a stale/expired token as authenticated.
    // Validate it first to prevent a cascade of 401s (settings/ui, crm/stream, etc.).
    state = AuthValidating(user: session.user);

    try {
      final me = await _api.me();
      // Keep stored user info fresh (token stays the same).
      await _db.saveSession(AuthSession(token: session.token, user: me));
      state = AuthAuthenticated(token: session.token, user: me);
    } catch (e) {
      // If we're offline/unreachable, keep the cached session so the app can
      // work in offline-first mode; we'll validate again on next successful request.
      if (e is DioException) {
        final status = e.response?.statusCode;
        final offline = e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout;

        if (offline) {
          state = AuthAuthenticated(token: session.token, user: session.user);
          return;
        }

        if (status == 401) {
          if (kDebugMode) {
            debugPrint('[AUTH] bootstrap: token invalid (401), clearing session');
          }
          await _db.clearSession();
          state = const AuthUnauthenticated();
          return;
        }
      }

      if (kDebugMode) {
        debugPrint('[AUTH] bootstrap: validation error $e');
      }
      // Conservative fallback: keep session but do not mark authenticated.
      state = const AuthUnauthenticated();
    }
    try {
      final me = await _api.me();
      state = AuthAuthenticated(token: session.token, user: me);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AUTH] bootstrap: token invalid, clearing session. err=$e');
      }
      await _db.clearSession();
      state = const AuthUnauthenticated();
    }
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
