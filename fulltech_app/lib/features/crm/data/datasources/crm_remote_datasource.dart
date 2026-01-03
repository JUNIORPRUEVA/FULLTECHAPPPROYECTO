import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../models/crm_message.dart';
import '../models/crm_thread.dart';
import '../models/customer.dart';

class CrmRemoteDataSource {
  final Dio _dio;

  CrmRemoteDataSource(this._dio);

  Future<ThreadsPage> listThreads({
    String? search,
    String? estado,
    bool? pinned,
    String? assignedUserId,
    int limit = 30,
    int offset = 0,
  }) async {
    // New WhatsApp CRM API uses page/limit and optional status.
    final page = (offset ~/ limit) + 1;

    final res = await _dio.get(
      '/crm/chats',
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        // Reuse "estado" UI as status filter.
        if (estado != null && estado.trim().isNotEmpty) 'status': estado.trim(),
        'page': page,
        'limit': limit,
      },
    );

    final data = res.data as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(CrmThread.fromJson)
        .toList();

    return ThreadsPage(
      items: items,
      total: (data['total'] as num? ?? items.length).toInt(),
      limit: (data['limit'] as num? ?? limit).toInt(),
      offset: offset,
    );
  }

  Future<CrmThread> getThread(String id) async {
    // No dedicated "get chat" endpoint yet; list and pick.
    final res = await _dio.get('/crm/chats', queryParameters: {'page': 1, 'limit': 1});
    final data = res.data as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>).cast<Map<String, dynamic>>();
    if (items.isEmpty) throw Exception('Chat not found');
    return CrmThread.fromJson(items.first);
  }

  Future<CrmThread> patchThread(String id, Map<String, dynamic> patch) async {
    // New chats API does not support patching thread metadata yet.
    throw UnsupportedError('Chat update is not supported in the new CRM API');
  }

  Future<MessagesPage> listMessages({
    required String threadId,
    int limit = 50,
    DateTime? before,
  }) async {
    final res = await _dio.get(
      '/crm/chats/$threadId/messages',
      queryParameters: {
        'limit': limit,
        if (before != null) 'before': before.toIso8601String(),
      },
    );

    final data = res.data as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(CrmMessage.fromJson)
        .toList();

    final rawNext = data['next_before'];
    final nextBefore = rawNext is String ? DateTime.tryParse(rawNext) : null;

    return MessagesPage(items: items, nextBefore: nextBefore);
  }

  Future<CrmMessage> postMessage({
    required String threadId,
    required bool fromMe,
    String type = 'text',
    String? body,
    String? mediaUrl,
  }) async {
    // New API distinguishes text vs media. Keep minimal support here.
    if (!fromMe) throw UnsupportedError('Inbound messages are created via webhook only');

    if (type == 'text') {
      final res = await _dio.post(
        '/crm/chats/$threadId/messages/text',
        data: {
          'text': (body ?? '').toString(),
        },
      );

      final data = res.data as Map<String, dynamic>;
      return CrmMessage.fromJson(data['item'] as Map<String, dynamic>);
    }

    throw UnsupportedError('Use media upload endpoint for non-text messages');
  }

  Future<CrmMessage> sendMessage({
    required String threadId,
    String type = 'text',
    String? message,
    String? mediaUrl,
  }) async {
    if (type != 'text') {
      throw UnsupportedError('Use sendMediaMessage() for non-text messages');
    }

    final res = await _dio.post(
      '/crm/chats/$threadId/messages/text',
      data: {
        'text': (message ?? '').toString(),
      },
    );

    final data = res.data as Map<String, dynamic>;
    return CrmMessage.fromJson(data['item'] as Map<String, dynamic>);
  }

  Future<CrmMessage> sendMediaMessage({
    required String threadId,
    required PlatformFile file,
    String? caption,
    String? type,
  }) async {
    final resolvedType = (type ?? _inferMediaType(file)).toString();

    final multipart = await _toMultipart(file);
    final form = FormData();
    form.files.add(MapEntry('file', multipart));
    form.fields.add(MapEntry('type', resolvedType));
    if (caption != null && caption.trim().isNotEmpty) {
      form.fields.add(MapEntry('caption', caption.trim()));
    }

    final res = await _dio.post(
      '/crm/chats/$threadId/messages/media',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );

    final data = res.data as Map<String, dynamic>;
    final item = (data['item'] ?? data) as Map<String, dynamic>;
    return CrmMessage.fromJson(item);
  }

  static String _inferMediaType(PlatformFile f) {
    final ext = (f.extension ?? '').toLowerCase();
    if ({'jpg', 'jpeg', 'png', 'gif', 'webp'}.contains(ext)) return 'image';
    if ({'mp4', 'mov', 'avi', 'mkv', 'webm', '3gp'}.contains(ext)) return 'video';
    if ({'mp3', 'wav', 'aac', 'm4a', 'ogg', 'opus'}.contains(ext)) return 'audio';
    return 'document';
  }

  static Future<MultipartFile> _toMultipart(PlatformFile f) async {
    if (f.bytes != null) {
      return MultipartFile.fromBytes(f.bytes!, filename: f.name);
    }
    final path = f.path;
    if (path == null || path.trim().isEmpty) {
      throw Exception('No file bytes/path available');
    }
    return MultipartFile.fromFile(path, filename: f.name);
  }

  Future<ConvertResult> convertThreadToCustomer(String threadId) async {
    // Not supported with the new chats API.
    throw UnsupportedError('Convert to customer is not supported in the new CRM API');
  }
}

class ThreadsPage {
  final List<CrmThread> items;
  final int total;
  final int limit;
  final int offset;

  ThreadsPage({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });
}

class MessagesPage {
  final List<CrmMessage> items;
  final DateTime? nextBefore;

  MessagesPage({required this.items, required this.nextBefore});
}

class ConvertResult {
  final Customer customer;
  final CrmThread thread;

  ConvertResult({required this.customer, required this.thread});
}
