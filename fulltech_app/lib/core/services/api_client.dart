import 'package:dio/dio.dart';

import '../storage/local_db.dart';
import 'app_config.dart';
import 'auth_events.dart';

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
          final session = await db.readSession();
          if (session != null) {
            options.headers['Authorization'] = 'Bearer ${session.token}';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // Handle 401 (token invalidated) and 403 (access revoked) errors
          if (error.response?.statusCode == 401 ||
              error.response?.statusCode == 403) {
            // Clear local session and data
            await db.clearSession();

            // Notify app layers (router/state) to force logout.
            AuthEvents.unauthorized(error.response?.statusCode);
          }

          handler.next(error);
        },
      ),
    );

    return client;
  }
}


