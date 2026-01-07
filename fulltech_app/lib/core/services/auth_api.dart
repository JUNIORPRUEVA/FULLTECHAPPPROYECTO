import 'package:dio/dio.dart';

import '../models/app_user.dart';

class AuthApi {
  final Dio _dio;

  AuthApi(this._dio);

  Future<({String token, AppUser user})> login({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });

    final data = res.data as Map<String, dynamic>;
    return (
      token: data['token'] as String,
      user: AppUser.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  Future<({String token, AppUser user})> register({
    required String email,
    required String password,
    required String name,
    String? empresaNombre,
  }) async {
    final res = await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'name': name,
      if (empresaNombre != null) 'empresaNombre': empresaNombre,
    });

    final data = res.data as Map<String, dynamic>;
    return (
      token: data['token'] as String,
      user: AppUser.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  Future<AppUser> me() async {
    final res = await _dio.get('/auth/me', options: Options(extra: const {
      // Avoid offline caches/queues and avoid spamming unauthorized events during bootstrap validation.
      'offlineCache': false,
      'offlineQueue': false,
      'suppressUnauthorizedEvent': true,
    }));

    final data = res.data as Map<String, dynamic>;
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }
}
