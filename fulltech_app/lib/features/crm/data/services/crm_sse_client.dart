import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

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
              headers: const {
                'Accept': 'text/event-stream',
                'Cache-Control': 'no-cache',
              },
            ),
          );

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
        } catch (_) {
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
