import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/auth_events.dart';
import '../../../core/services/auth_api.dart';
import '../../../core/services/app_config.dart';
import '../../../core/storage/local_db.dart';
import 'auth_state.dart';

import 'dart:async';

class AuthController extends StateNotifier<AuthState> {
  final LocalDb _db;
  final AuthApi Function() _getApi;

  late final StreamSubscription<AuthEvent> _eventsSub;

  DateTime? _lastUnauthorizedHandledAt;

  AuthController({required LocalDb db, required AuthApi Function() getApi})
    : _db = db,
      _getApi = getApi,
      super(const AuthUnknown()) {
    _eventsSub = AuthEvents.stream.listen((event) async {
      if (event.type == AuthEventType.unauthorized) {
        if (kDebugMode) {
          debugPrint(
            '[AUTH] unauthorized event status=${event.statusCode} detail=${event.detail ?? ''}',
          );
        }

        await _handleUnauthorizedEvent(event);
      }
    });
  }

  Future<void> _handleUnauthorizedEvent(AuthEvent event) async {
    final currentState = state;
    if (currentState is! AuthAuthenticated) {
      if (kDebugMode) {
        debugPrint('[AUTH] ignoring unauthorized - not authenticated');
      }
      return;
    }

    // Debounce: avoid cascading loops (CRM SSE + REST + UI settings).
    final now = DateTime.now();
    if (_lastUnauthorizedHandledAt != null &&
        now.difference(_lastUnauthorizedHandledAt!) <
            const Duration(seconds: 2)) {
      return;
    }
    _lastUnauthorizedHandledAt = now;

    // IMPORTANT: Don't immediately wipe the session on any 401.
    // Some endpoints may incorrectly return 401 for authorization problems.
    // Validate with /auth/me first; only logout if the token is truly invalid.
    try {
      final me = await _getApi().me();
      if (kDebugMode) {
        debugPrint(
          '[AUTH] unauthorized event ignored after /auth/me ok user=${me.email} role=${me.role}',
        );
      }
      // Keep stored user fresh.
      await _db.saveSession(AuthSession(token: currentState.token, user: me));
      state = AuthAuthenticated(token: currentState.token, user: me);
      return;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        if (kDebugMode) {
          debugPrint('[AUTH] token invalid after /auth/me 401 -> logout');
          debugPrint(StackTrace.current.toString());
        }
        await _db.clearSession();
        state = const AuthUnauthenticated();
        return;
      }

      // If we can't validate (offline/timeouts/etc), don't wipe the session.
      if (kDebugMode) {
        debugPrint('[AUTH] unable to validate token on unauthorized: $e');
      }
    }
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
      final t = session.token;
      final suffix = t.length <= 6 ? t : t.substring(t.length - 6);
      debugPrint(
        '[AUTH] bootstrap: token=…$suffix userId=${session.user.id} empresaId=${session.user.empresaId} baseUrl=${AppConfig.apiBaseUrl}',
      );
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
      final me = await _getApi().me();
      // Keep stored user info fresh (token stays the same).
      await _db.saveSession(AuthSession(token: session.token, user: me));
      state = AuthAuthenticated(token: session.token, user: me);
    } catch (e) {
      // If we're offline/unreachable, keep the cached session so the app can
      // work in offline-first mode; we'll validate again on next successful request.
      if (e is DioException) {
        final status = e.response?.statusCode;
        final offline =
            e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout;

        if (offline) {
          state = AuthAuthenticated(token: session.token, user: session.user);
          return;
        }

        if (status == 401) {
          if (kDebugMode) {
            debugPrint(
              '[AUTH] bootstrap: token invalid (401), clearing session',
            );
          }
          await _db.clearSession();
          state = const AuthUnauthenticated();
          return;
        }
      }

      if (kDebugMode) {
        debugPrint('[AUTH] bootstrap: validation error $e, preserving session');
      }
      // Keep session and mark as authenticated for offline mode.
      // The session will be re-validated on the next successful request.
      state = AuthAuthenticated(token: session.token, user: session.user);
    }
  }

  Future<void> login({required String email, required String password}) async {
    if (kDebugMode) debugPrint('[AUTH] login() email=$email');
    final result = await _getApi().login(email: email, password: password);
    final session = AuthSession(token: result.token, user: result.user);
    await _db.saveSession(session);
    if (kDebugMode) {
      final t = session.token;
      final suffix = t.length <= 6 ? t : t.substring(t.length - 6);
      debugPrint(
        '[AUTH] login: success token=…$suffix userId=${session.user.id} empresaId=${session.user.empresaId} role=${session.user.role}',
      );
    }
    state = AuthAuthenticated(token: session.token, user: session.user);
  }

  Future<void> logout() async {
    if (kDebugMode) debugPrint('[AUTH] logout()');
    if (kDebugMode) {
      debugPrint(StackTrace.current.toString());
    }
    await _db.clearSession();
    state = const AuthUnauthenticated();
  }

  @override
  void dispose() {
    _eventsSub.cancel();
    super.dispose();
  }
}
