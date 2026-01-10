import 'dart:async';

import 'package:dio/dio.dart';

import '../models/crm_stream_event.dart';
import 'crm_sse_client.dart';

class SseEvent {
  final String type;
  final String? chatId;
  final String? messageId;
  final String? targetUserId;

  const SseEvent({
    required this.type,
    required this.chatId,
    required this.messageId,
    required this.targetUserId,
  });
}

class SseService {
  SseService(Dio dio) : _client = CrmSseClient(dio);

  final CrmSseClient _client;

  Stream<SseEvent> stream() {
    return _client.stream().map(_map);
  }

  static SseEvent _map(CrmStreamEvent evt) {
    String normalizeType(String raw) {
      switch (raw) {
        case 'message.new':
          return 'crm.message.created';
        case 'message.updated':
        case 'message.status':
          return 'crm.message.created';
        case 'chat.updated':
          return 'crm.chat.updated';
        case 'chat.assigned':
          return 'crm.chat.assigned';
        case 'chat.removed':
          return 'crm.chat.removed';
        default:
          return raw;
      }
    }

    return SseEvent(
      type: normalizeType(evt.type),
      chatId: evt.chatId,
      messageId: evt.messageId,
      targetUserId: evt.targetUserId,
    );
  }
}

