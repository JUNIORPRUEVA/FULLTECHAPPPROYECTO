import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/dio_provider.dart';
import '../services/offline_http_queue.dart';
import '../storage/local_db.dart';
import '../../features/auth/state/auth_providers.dart';

final httpQueueSyncServiceProvider = Provider<HttpQueueSyncService>((ref) {
  return HttpQueueSyncService(
    db: ref.watch(localDbProvider),
    dio: ref.watch(dioProvider),
  );
});

class HttpQueueSyncService {
  final LocalDb _db;
  final Dio _dio;

  HttpQueueSyncService({required LocalDb db, required Dio dio})
    : _db = db,
      _dio = dio;

  bool _isOffline(DioException e) {
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout;
  }

  /// Flushes pending queued HTTP requests (module=`__http`).
  ///
  /// Best-effort: on network/offline errors it stops early.
  Future<void> flushPending() async {
    // CRITICAL: Verify session exists before attempting any sync
    final session = await _db.readSession();
    if (session == null) {
      // No session - stop all sync attempts immediately
      return;
    }

    final items = await _db.getPendingSyncItems();

    for (final item in items) {
      if (item.module != OfflineHttpQueue.module) continue;

      try {
        final payload = jsonDecode(item.payloadJson);
        if (payload is! Map<String, dynamic>) {
          await _db.markSyncItemError(item.id);
          continue;
        }

        final method = (payload['method'] ?? 'POST').toString();
        final path = (payload['path'] ?? '').toString();
        final query = payload['query'];
        final data = payload['data'];

        if (path.trim().isEmpty) {
          await _db.markSyncItemError(item.id);
          continue;
        }

        await _dio.request(
          path,
          data: data,
          queryParameters: query is Map ? query.cast<String, dynamic>() : null,
          options: Options(method: method),
        );

        await _db.markSyncItemSent(item.id);
      } on DioException catch (e) {
        // CRITICAL: Stop retry loop on 401
        if (e.response?.statusCode == 401) {
          await _db.markSyncItemSent(item.id); // Remove from queue permanently
          return; // Stop processing - session is invalid
        }

        await _db.markSyncItemError(item.id);
        if (_isOffline(e)) return;
      } catch (_) {
        await _db.markSyncItemError(item.id);
      }
    }
  }
}
