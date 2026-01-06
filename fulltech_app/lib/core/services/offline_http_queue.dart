import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../storage/local_db.dart';

class OfflineHttpQueue {
  static const module = '__http';
  static const op = 'request';

  static bool isNetworkError(Object e) {
    // Keep this dependency-light; callers can still do stricter checks.
    final msg = e.toString();
    return msg.contains('SocketException') ||
        msg.contains('Failed host lookup') ||
        msg.contains('connectionError') ||
        msg.contains('connectionTimeout') ||
        msg.contains('receiveTimeout');
  }

  static Future<void> enqueue(
    LocalDb db, {
    required String method,
    required String path,
    Map<String, dynamic>? queryParameters,
    Object? data,
    String? requestId,
  }) async {
    final id = requestId ?? const Uuid().v4();

    await db.enqueueSync(
      module: module,
      op: op,
      entityId: id,
      payloadJson: jsonEncode({
        'method': method.toUpperCase(),
        'path': path,
        if (queryParameters != null) 'query': queryParameters,
        if (data != null) 'data': data,
      }),
    );
  }
}
