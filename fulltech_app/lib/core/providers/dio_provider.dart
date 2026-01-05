import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fulltech_app/features/auth/state/auth_providers.dart';

final dioProvider = Provider<Dio>((ref) {
  // Get the ApiClient which already has Dio configured
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.dio;
});
