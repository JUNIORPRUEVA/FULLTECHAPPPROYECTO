import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/crm_stream_event.dart';

class CrmSseClient {
  final Dio _dio;

  CrmSseClient(this._dio);

  Stream<CrmStreamEvent> stream() {
    late final StreamController<CrmStreamEvent> controller;
    var cancelled = false;

    Future<void> pump() async {
      while (!cancelled) {
        try {
          final res = await _dio.get<ResponseBody>(
            '/crm/stream',
            options: Options(
              responseType: ResponseType.stream,
              // IMPORTANT: SSE is long-lived.
              // The ApiClient default receiveTimeout is 20s, while the backend ping is 25s.
              // If we don't increase it, the stream will always time out and reconnect.
              receiveTimeout: const Duration(minutes: 2),
              extra: const {
                'offlineQueue': false,
                'logSse': true,
              },
              headers: {
                'Accept': 'text/event-stream',
                'Cache-Control': 'no-cache',
              },
            ),
          );

          if (kDebugMode) {
            debugPrint(
              '[CRM][SSE] connected status=${res.statusCode} baseUrl=${_dio.options.baseUrl}',
            );
          }

          final body = res.data;
          if (body == null) {
            throw Exception('SSE response body missing');
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
        } catch (e) {
          if (kDebugMode) {
            if (e is DioException) {
              debugPrint(
                '[CRM][SSE] error type=${e.type} status=${e.response?.statusCode} msg=${e.message} baseUrl=${_dio.options.baseUrl}',
              );
            } else {
              debugPrint('[CRM][SSE] error $e');
            }
          }
          // Best-effort reconnect.
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    }

    controller = StreamController<CrmStreamEvent>(
      onListen: () {
        unawaited(pump());
      },
      onCancel: () async {
        cancelled = true;
      },
    );

    return controller.stream;
  }
}
