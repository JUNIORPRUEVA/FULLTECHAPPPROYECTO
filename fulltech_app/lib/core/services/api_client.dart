import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../storage/local_db.dart';
import 'app_config.dart';
import 'auth_events.dart';
import 'http_offline_cache.dart';
import 'offline_http_queue.dart';

class ApiClient {
  final Dio dio;
  final LocalDb db;

  static bool _handlingUnauthorized = false;
  static DateTime? _lastUnauthorizedAt;

  ApiClient._(this.dio, this.db);

  static Future<ApiClient> create(LocalDb db) async {
    return forBaseUrl(db, AppConfig.apiBaseUrl);
  }

  static ApiClient forBaseUrl(LocalDb db, String baseUrl) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 40),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    final client = ApiClient._(dio, db);

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Correlation id for diagnostics (per-request).
          options.extra.putIfAbsent(
            'rid',
            () => DateTime.now().microsecondsSinceEpoch.toString(),
          );

          // Default behavior: allow offline queueing for write requests.
          // Modules can opt out via `Options(extra: {'offlineQueue': false})`.
          options.extra.putIfAbsent('offlineQueue', () => true);

          // Default behavior: allow offline caching for JSON GET requests.
          // Modules can opt out via `Options(extra: {'offlineCache': false})`.
          options.extra.putIfAbsent('offlineCache', () {
            final method = options.method.toUpperCase();
            if (method != 'GET') return false;
            // Only cache JSON-like responses. Avoid bytes/stream.
            return options.responseType == ResponseType.json;
          });

          final session = await db.readSession();
          if (session != null) {
            options.headers['Authorization'] = 'Bearer ${session.token}';

            // Safe diagnostics: log only token suffix.
            if (kDebugMode && options.extra['logSse'] == true) {
              final t = session.token;
              final suffix = t.length <= 8 ? t : t.substring(t.length - 8);
              debugPrint(
                '[NET][${options.extra['rid']}] ${options.method} ${options.path} token=…$suffix baseUrl=${dio.options.baseUrl}',
              );
            }
          }
          handler.next(options);
        },
        onResponse: (response, handler) async {
          try {
            await HttpOfflineCache.put(db, response.requestOptions, response.data);
          } catch (_) {
            // Best-effort only.
          }
          handler.next(response);
        },
        onError: (error, handler) async {
          // Offline-first GET fallback: serve cached snapshot when offline.
          try {
            final method = error.requestOptions.method.toUpperCase();
            final offlineCache = error.requestOptions.extra['offlineCache'] == true;
            final isOffline = error.type == DioExceptionType.connectionError ||
                error.type == DioExceptionType.connectionTimeout ||
                error.type == DioExceptionType.receiveTimeout;

            if (method == 'GET' && offlineCache && isOffline) {
              final cached = await HttpOfflineCache.get(db, error.requestOptions);
              if (cached != null) {
                handler.resolve(
                  Response(
                    requestOptions: error.requestOptions,
                    statusCode: 200,
                    data: cached,
                  ),
                );
                return;
              }
            }
          } catch (_) {
            // If cache fails, continue with normal error flow.
          }

          // If offline and this is a write request, enqueue it for later.
          // This is best-effort: skips multipart/FormData payloads.
          final offlineQueue = error.requestOptions.extra['offlineQueue'] == true;
          final method = error.requestOptions.method.toUpperCase();
          final isWrite = method == 'POST' || method == 'PUT' || method == 'PATCH' || method == 'DELETE';

          if (offlineQueue && isWrite) {
            final isOffline = error.type == DioExceptionType.connectionError ||
                error.type == DioExceptionType.connectionTimeout ||
                error.type == DioExceptionType.receiveTimeout;

            final data = error.requestOptions.data;
            final isMultipart = data is FormData;

            if (isOffline && !isMultipart) {
              try {
                await OfflineHttpQueue.enqueue(
                  db,
                  method: method,
                  path: error.requestOptions.path,
                  queryParameters: error.requestOptions.queryParameters,
                  data: data,
                );
              } catch (_) {
                // Best-effort only; never block the original error flow.
              }
            }
          }

          // Handle 401 (token invalidated) errors.
          // IMPORTANT: Only force logout when the request was authenticated.
          // Some endpoints may respond 401 for anonymous requests; we should not
          // wipe the session in that case (it causes an immediate "bounce back" after login).
          final status = error.response?.statusCode;
          if (status == 401) {
            final suppress = error.requestOptions.extra['suppressUnauthorizedEvent'] == true;
            final authHeader = error.requestOptions.headers['Authorization'];
            final hadAuthHeader = authHeader != null && authHeader.toString().trim().isNotEmpty;

            final path = error.requestOptions.path;
            final detail =
              '$status ${error.requestOptions.method} $path hadAuthHeader=$hadAuthHeader';

            // CRITICAL: Only log ONCE per path to prevent spam
            // Track last 401 path+time to avoid repeated logs
            final now = DateTime.now();
            final recent = _lastUnauthorizedAt != null &&
                now.difference(_lastUnauthorizedAt!) < const Duration(seconds: 5);
            
            if (kDebugMode && !recent) {
              debugPrint('[AUTH][HTTP] $detail baseUrl=${dio.options.baseUrl}');
            }

            if (hadAuthHeader && !suppress) {
              // Debounce/lock: avoid clearing session + emitting unauthorized repeatedly.
              if (!_handlingUnauthorized && !recent) {
                _handlingUnauthorized = true;
                _lastUnauthorizedAt = now;
                try {
                  if (kDebugMode) {
                    debugPrint('[AUTH] clearing local session due to $detail');
                  }
                  await db.clearSession();
                  AuthEvents.unauthorized(status, detail);
                } finally {
                  // Release lock shortly after to allow future real logouts.
                  _handlingUnauthorized = false;
                }
              }
            } else if (!hadAuthHeader && !recent) {
              // WARNING: Request sent without auth header
              // This indicates a bug - authenticated endpoints should always have the header
              if (kDebugMode) {
                debugPrint('[AUTH][BUG] Request to $path sent without Authorization header!');
                debugPrint('[AUTH][BUG] This should not happen for protected endpoints.');
              }
            }
          }

          handler.next(error);
        },
      ),
    );

    return client;
  }
}


