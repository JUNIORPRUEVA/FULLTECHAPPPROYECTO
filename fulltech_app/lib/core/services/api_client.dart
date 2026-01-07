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

  ApiClient._(this.dio, this.db);

  static Future<ApiClient> create(LocalDb db) async {
    return forBaseUrl(db, AppConfig.apiBaseUrl);
  }

  static ApiClient forBaseUrl(LocalDb db, String baseUrl) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    final client = ApiClient._(dio, db);

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
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

          // Handle 401 (token invalidated) and 403 (access revoked) errors.
          // IMPORTANT: Only force logout when the request was authenticated.
          // Some endpoints may respond 401/403 for anonymous requests; we should not
          // wipe the session in that case (it causes an immediate "bounce back" after login).
          final status = error.response?.statusCode;
          if (status == 401 || status == 403) {
            final authHeader = error.requestOptions.headers['Authorization'];
            final hadAuthHeader = authHeader != null && authHeader.toString().trim().isNotEmpty;

            if (kDebugMode) {
              debugPrint(
                '[AUTH][HTTP] $status ${error.requestOptions.method} ${error.requestOptions.path} hadAuthHeader=$hadAuthHeader baseUrl=${dio.options.baseUrl}',
              );
            }

            if (hadAuthHeader) {
              // Clear local session and data
              await db.clearSession();

              // Notify app layers (router/state) to force logout.
              AuthEvents.unauthorized(status);
            }
          }

          handler.next(error);
        },
      ),
    );

    return client;
  }
}


