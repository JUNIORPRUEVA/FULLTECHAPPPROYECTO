import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../../../core/services/auth_events.dart';
import '../../../core/services/auth_token_store.dart';
import '../../../core/services/auth_api.dart';
import '../../../core/storage/local_db.dart';
import 'auth_state.dart';

import 'dart:async';

class AuthController extends StateNotifier<AuthState> {
  final LocalDb _db;
  final AuthApi _api;

  late final StreamSubscription<AuthEvent> _eventsSub;
  bool _refreshInProgress = false;
  bool _reauthInProgress = false;

  AuthController({required LocalDb db, required AuthApi api})
    : _db = db,
      _api = api,
      super(const AuthUnknown()) {
    _eventsSub = AuthEvents.stream.listen((event) async {
      if (event.type == AuthEventType.unauthorized) {
        if (kDebugMode) {
          debugPrint(
            '[AUTH] unauthorized event status=${event.statusCode} detail=${event.detail ?? ''}',
          );
        }

        // Only clear session if we're currently authenticated
        // This prevents clearing session during startup race conditions
        final currentState = state;
        if (currentState is! AuthAuthenticated) {
          if (kDebugMode) {
            debugPrint('[AUTH] ignoring 401 - not authenticated yet');
          }
          return;
        }

        // Check if session still exists before clearing
        // (it might have been cleared by another concurrent 401)
        final session = await _db.readSession();
        if (session == null) {
          if (kDebugMode) {
            debugPrint('[AUTH] session already cleared, updating state only');
          }
          state = const AuthUnauthenticated();
          return;
        }

        // DO NOT logout immediately on a single 401.
        // Re-validate via /auth/me (and/or refresh) to prevent random logout loops
        // caused by a single bad endpoint/temporary race.
        if (_reauthInProgress) return;
        _reauthInProgress = true;
        try {
          // Try refresh first if available.
          final rt = AuthTokenStore.refreshToken ?? (await _db.readSession())?.refreshToken;
          if (rt != null && rt.trim().isNotEmpty) {
            final refreshed = await _refreshWithToken(rt);
            if (refreshed) {
              if (kDebugMode) debugPrint('[AUTH] 401 recovered by refresh; keeping session');
              return;
            }
          }

          // Validate token; if /auth/me succeeds, ignore this 401.
          try {
            await _api.me();
            if (kDebugMode) debugPrint('[AUTH] 401 ignored: /auth/me ok');
            return;
          } catch (e) {
            if (e is DioException) {
              final status = e.response?.statusCode;
              final offline =
                  e.type == DioExceptionType.connectionError ||
                  e.type == DioExceptionType.connectionTimeout ||
                  e.type == DioExceptionType.receiveTimeout;
              if (offline) {
                if (kDebugMode) debugPrint('[AUTH] 401 ignored: offline during reauth');
                return;
              }
              if (status != 401) {
                if (kDebugMode) debugPrint('[AUTH] 401 ignored: /auth/me returned $status');
                return;
              }
            }

            // Confirmed invalid: clear session.
            if (kDebugMode) {
              debugPrint('[AUTH] clearing session and logging out');
            }
            AuthTokenStore.clear();
            await _db.clearSession();
            state = const AuthUnauthenticated();
          }
        } finally {
          _reauthInProgress = false;
        }
      }
    });
  }

  Future<void> bootstrap() async {
    if (kDebugMode) debugPrint('[AUTH] bootstrap()');
    final session = await _db.readSession();
    if (session == null) {
      if (kDebugMode) debugPrint('[AUTH] bootstrap: no session');
      AuthTokenStore.clear();
      state = const AuthUnauthenticated();
      return;
    }

    // Make token available immediately for ApiClient fallbacks.
    AuthTokenStore.set(session.token);
    AuthTokenStore.setRefreshToken(session.refreshToken);

    if (kDebugMode) {
      final t = session.token;
      final suffix = t.length <= 6 ? t : t.substring(t.length - 6);
      debugPrint(
        '[AUTH] bootstrap: session found user=${session.user.email} role=${session.user.role} token=***$suffix',
      );
    }

    // IMPORTANT: Avoid treating a stale/expired token as authenticated.
    // Validate it first to prevent a cascade of 401s (settings/ui, crm/stream, etc.).
    state = AuthValidating(user: session.user);

    try {
      final me = await _api.me();
      // Keep stored user info fresh (token stays the same).
      await _db.saveSession(
        AuthSession(token: session.token, refreshToken: session.refreshToken, user: me),
      );
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
          // Attempt a single refresh (if available) before logging out.
          final rt = session.refreshToken ?? AuthTokenStore.refreshToken;
          if (rt != null && rt.trim().isNotEmpty) {
            if (kDebugMode) {
              debugPrint('[AUTH] bootstrap: token invalid (401), attempting refresh');
            }
            final refreshed = await _refreshWithToken(rt);
            if (refreshed) return;
          }

          if (kDebugMode) {
            debugPrint('[AUTH] bootstrap: token invalid (401), clearing session');
          }
          AuthTokenStore.clear();
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

  Future<bool> _refreshWithToken(String refreshToken) async {
    if (_refreshInProgress) return false;
    _refreshInProgress = true;
    try {
      final result = await _api.refresh(refreshToken: refreshToken);
      final session = AuthSession(
        token: result.token,
        refreshToken: result.refreshToken ?? refreshToken,
        user: result.user,
      );

      AuthTokenStore.set(session.token);
      AuthTokenStore.setRefreshToken(session.refreshToken);
      await _db.saveSession(session);

      if (kDebugMode) {
        final t = session.token;
        final suffix = t.length <= 6 ? t : t.substring(t.length - 6);
        debugPrint('[AUTH] refresh: ok token=***$suffix user=${session.user.email}');
      }

      state = AuthAuthenticated(token: session.token, user: session.user);
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AUTH] refresh: failed $e');
      }
      return false;
    } finally {
      _refreshInProgress = false;
    }
  }

  Future<void> login({required String email, required String password}) async {
    if (kDebugMode) debugPrint('[AUTH] login() email=$email');
    final result = await _api.login(email: email, password: password);
    final session = AuthSession(
      token: result.token,
      refreshToken: result.refreshToken,
      user: result.user,
    );

    // Ensure token is available even if DB persistence fails.
    AuthTokenStore.set(session.token);
    AuthTokenStore.setRefreshToken(session.refreshToken);
    try {
      await _db.saveSession(session);
    } catch (e) {
      // Don't block login on local persistence issues.
      if (kDebugMode) {
        debugPrint('[AUTH] login: failed to persist session: $e');
      }
    }
    if (kDebugMode) {
      debugPrint('[AUTH] login: saved session role=${session.user.role}');
    }
    state = AuthAuthenticated(token: session.token, user: session.user);
  }

  Future<void> logout() async {
    if (kDebugMode) debugPrint('[AUTH] logout()');
    AuthTokenStore.clear();
    await _db.clearSession();
    state = const AuthUnauthenticated();
  }

  @override
  void dispose() {
    _eventsSub.cancel();
    super.dispose();
  }
}
