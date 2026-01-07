import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/services/auth_events.dart';
import '../models/crm_stream_event.dart';

class CrmSseClient {
  final Dio _dio;

  CrmSseClient(this._dio);

  Stream<CrmStreamEvent> stream() {
    late final StreamController<CrmStreamEvent> controller;
    var cancelled = false;
    CancelToken? cancelToken;

    var attempt = 0;

    Duration nextBackoff() {
      // Exponential backoff: 1s, 2s, 5s, 10s, 20s, 30s (cap)
      attempt = (attempt + 1).clamp(1, 20);
      final secs = switch (attempt) {
        1 => 1,
        2 => 2,
        3 => 5,
        4 => 10,
        5 => 20,
        _ => 30,
      };
      return Duration(seconds: secs);
    }

    Future<void> pump() async {
      while (!cancelled) {
        try {
          cancelToken?.cancel('reconnect');
          cancelToken = CancelToken();

          final res = await _dio.get<ResponseBody>(
            '/crm/stream',
            options: Options(
              responseType: ResponseType.stream,
              // Don't throw DioException for 401/403; handle status codes explicitly.
              validateStatus: (code) => code != null,
              // IMPORTANT: SSE is long-lived.
              // The ApiClient default receiveTimeout is 20s, while the backend ping is 25s.
              // If we don't increase it, the stream will always time out and reconnect.
              receiveTimeout: const Duration(minutes: 2),
              extra: const {
                'offlineQueue': false,
                'offlineCache': false,
                'logSse': true,
                // SSE handles 401 itself; avoid duplicate unauthorized cascades.
                'suppressUnauthorizedEvent': true,
              },
              headers: {
                'Accept': 'text/event-stream',
                'Cache-Control': 'no-cache',
              },
            ),
            cancelToken: cancelToken,
          );

          final status = res.statusCode ?? 0;
          if (status != 200) {
            if (kDebugMode) {
              debugPrint(
                '[CRM][SSE] connect refused status=$status baseUrl=${_dio.options.baseUrl}',
              );
            }

            final authHeader = res.requestOptions.headers['Authorization'];
            final hadAuthHeader = authHeader != null &&
                authHeader.toString().trim().isNotEmpty;

            if (status == 401) {
              // Stop all retries: token is invalid.
              final detail =
                  '401 GET /crm/stream hadAuthHeader=$hadAuthHeader baseUrl=${_dio.options.baseUrl}';
              if (hadAuthHeader) {
                AuthEvents.unauthorized(401, detail);
              }
              break;
            }

            // Retry with backoff for other statuses.
            await Future.delayed(nextBackoff());
            continue;
          }

          // Successful connect: reset backoff.
          attempt = 0;

          if (kDebugMode) {
            debugPrint(
              '[CRM][SSE] connected status=${res.statusCode} baseUrl=${_dio.options.baseUrl}',
            );
          }

          final body = res.data;
          if (body == null) {
            // Treat as disconnect and retry.
            await Future.delayed(nextBackoff());
            continue;
          }

          String? currentEvent;
          final dataLines = <String>[];
          var buffer = '';

          Future<void> flush() async {
            if (currentEvent == null || dataLines.isEmpty) {
              currentEvent = null;
              dataLines.clear();
              return;
            }

            final data = dataLines.join('\n').trim();
            final evt = currentEvent;

            currentEvent = null;
            dataLines.clear();

            if (evt != 'crm') return;
            if (data.isEmpty) return;

            try {
              final decoded = jsonDecode(data);
              if (decoded is Map<String, dynamic>) {
                controller.add(CrmStreamEvent.fromJson(decoded));
              }
            } catch (_) {
              // Ignore parse errors.
            }
          }

          await for (final chunk in utf8.decoder.bind(body.stream)) {
            if (cancelled) break;

            buffer += chunk;
            while (true) {
              final idx = buffer.indexOf('\n');
              if (idx < 0) break;

              var line = buffer.substring(0, idx);
              buffer = buffer.substring(idx + 1);

              if (line.endsWith('\r')) {
                line = line.substring(0, line.length - 1);
              }

              if (line.isEmpty) {
                await flush();
                continue;
              }

              if (line.startsWith('event:')) {
                currentEvent = line.substring('event:'.length).trim();
                continue;
              }

              if (line.startsWith('data:')) {
                dataLines.add(line.substring('data:'.length).trim());
                continue;
              }
            }
          }

          // Stream ended.
          await flush();
          if (kDebugMode) {
            debugPrint('[CRM][SSE] disconnected; reconnecting...');
          }

          await Future.delayed(nextBackoff());
        } catch (e, st) {
          if (kDebugMode) {
            if (e is DioException) {
              debugPrint(
                '[CRM][SSE] error type=${e.type} status=${e.response?.statusCode} msg=${e.message} baseUrl=${_dio.options.baseUrl}',
              );
              debugPrint(st.toString());
            } else {
              debugPrint('[CRM][SSE] error $e');
              debugPrint(st.toString());
            }
          }

          // If cancelled or explicitly unauthorized, stop.
          if (cancelled) break;
          if (e is DioException && e.response?.statusCode == 401) {
            final authHeader = e.requestOptions.headers['Authorization'];
            final hadAuthHeader = authHeader != null &&
                authHeader.toString().trim().isNotEmpty;
            final detail =
                '401 GET /crm/stream hadAuthHeader=$hadAuthHeader baseUrl=${_dio.options.baseUrl}';
            if (hadAuthHeader) {
              AuthEvents.unauthorized(401, detail);
            }
            break;
          }

          // Best-effort reconnect with backoff.
          await Future.delayed(nextBackoff());
        }
      }

      try {
        await controller.close();
      } catch (_) {
        // ignore
      }
    }

    controller = StreamController<CrmStreamEvent>(
      onListen: () {
        unawaited(pump());
      },
      onCancel: () async {
        cancelled = true;
        cancelToken?.cancel('cancelled');
      },
    );

    return controller.stream;
  }
}
