import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';

import '../models/crm_message.dart';
import '../models/crm_chat_stats.dart';
import '../models/crm_thread.dart';
import '../models/crm_quick_reply.dart';
import '../models/ai_settings.dart';
import '../models/ai_suggestion.dart';
import '../models/customer.dart';

class CrmRemoteDataSource {
  final Dio _dio;
  CancelToken? _cancelToken;

  CrmRemoteDataSource(this._dio);

  void cancelRequests() {
    _cancelToken?.cancel('Operation cancelled by user');
    _cancelToken = null;
  }

  Options get _defaultOptions => Options(
    sendTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  );

  Future<ThreadsPage> listThreads({
    String? search,
    String? estado,
    String? productId,
    bool? pinned,
    String? assignedUserId,
    int limit = 30,
    int offset = 0,
  }) async {
    // New WhatsApp CRM API uses page/limit and optional status.
    final page = (offset ~/ limit) + 1;

    if (kDebugMode) {
      debugPrint(
        '[CRM][HTTP] GET /crm/chats page=$page limit=$limit search=$search status=$estado productId=$productId',
      );
    }

    final res = await _dio.get(
      '/crm/chats',
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        // Reuse "estado" UI as status filter.
        if (estado != null && estado.trim().isNotEmpty) 'status': estado.trim(),
        if (productId != null && productId.trim().isNotEmpty)
          'productId': productId.trim(),
        'page': page,
        'limit': limit,
      },
      options: _defaultOptions,
    );

    final data = res.data as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(CrmThread.fromJson)
        .toList();

    if (kDebugMode) {
      debugPrint(
        '[CRM][HTTP] /crm/chats -> items=${items.length} total=${data['total']}',
      );
    }

    return ThreadsPage(
      items: items,
      total: (data['total'] as num? ?? items.length).toInt(),
      limit: (data['limit'] as num? ?? limit).toInt(),
      offset: offset,
    );
  }

  Future<CrmThread> getThread(String id) async {
    // No dedicated "get chat" endpoint yet; list and pick.
    final res = await _dio.get(
      '/crm/chats',
      queryParameters: {'page': 1, 'limit': 1},
    );
    final data = res.data as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>).cast<Map<String, dynamic>>();
    if (items.isEmpty) throw Exception('Chat not found');
    return CrmThread.fromJson(items.first);
  }

  Future<CrmThread> patchThread(String id, Map<String, dynamic> patch) async {
    final res = await _dio.patch('/crm/chats/$id', data: patch);
    final data = res.data as Map<String, dynamic>;
    return CrmThread.fromJson(data['item'] as Map<String, dynamic>);
  }

  Future<CrmThread> patchChat(String chatId, Map<String, dynamic> patch) {
    return patchThread(chatId, patch);
  }

  Future<MessagesPage> listMessages({
    required String threadId,
    int limit = 50,
    DateTime? before,
  }) async {
    if (kDebugMode) {
      debugPrint(
        '[CRM][HTTP] GET /crm/chats/$threadId/messages limit=$limit before=${before?.toIso8601String()}',
      );
    }
    final res = await _dio.get(
      '/crm/chats/$threadId/messages',
      queryParameters: {
        'limit': limit,
        if (before != null) 'before': before.toIso8601String(),
      },
      options: _defaultOptions,
    );

    final data = res.data as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(CrmMessage.fromJson)
        .toList();

    final rawNext = data['next_before'] ?? data['nextBefore'];
    final nextBefore = rawNext is String ? DateTime.tryParse(rawNext) : null;

    if (kDebugMode) {
      debugPrint(
        '[CRM][HTTP] /crm/chats/$threadId/messages -> items=${items.length} nextBefore=$nextBefore',
      );
    }

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
    if (!fromMe)
      throw UnsupportedError('Inbound messages are created via webhook only');

    if (type == 'text') {
      final res = await _dio.post(
        '/crm/chats/$threadId/messages/text',
        data: {'text': (body ?? '').toString()},
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
    String? aiSuggestionId,
    String? aiSuggestedText,
    List<String>? aiUsedKnowledge,
  }) async {
    if (type != 'text') {
      throw UnsupportedError('Use sendMediaMessage() for non-text messages');
    }

    final res = await _dio.post(
      '/crm/chats/$threadId/messages/text',
      data: {
        'text': (message ?? '').toString(),
        if (aiSuggestionId != null) 'aiSuggestionId': aiSuggestionId,
        if (aiSuggestedText != null) 'aiSuggestedText': aiSuggestedText,
        if (aiUsedKnowledge != null) 'aiUsedKnowledge': aiUsedKnowledge,
      },
    );

    final data = res.data as Map<String, dynamic>;
    return CrmMessage.fromJson(data['item'] as Map<String, dynamic>);
  }

  Future<AiSettingsPublic> getAiSettingsPublic() async {
    final res = await _dio.get('/ai/settings/public');
    return AiSettingsPublic.fromJson(res.data as Map<String, dynamic>);
  }

  Future<AiSettings> getAiSettings() async {
    final res = await _dio.get('/ai/settings');
    return AiSettings.fromJson(res.data as Map<String, dynamic>);
  }

  Future<AiSettings> patchAiSettings(Map<String, dynamic> patch) async {
    final res = await _dio.patch('/ai/settings', data: patch);
    return AiSettings.fromJson(res.data as Map<String, dynamic>);
  }

  Future<AiSuggestResponse> suggestAi({
    String? chatId,
    String? lastCustomerMessageId,
    required String customerMessageText,
    String? customerPhone,
    String? customerName,
    String? currentChatState,
    String? assignedProductId,
    bool quickRepliesEnabled = true,
  }) async {
    final res = await _dio.post(
      '/ai/suggest',
      data: {
        if (chatId != null) 'chatId': chatId,
        if (lastCustomerMessageId != null)
          'lastCustomerMessageId': lastCustomerMessageId,
        'customerMessageText': customerMessageText,
        if (customerPhone != null) 'customerPhone': customerPhone,
        if (customerName != null) 'customerName': customerName,
        if (currentChatState != null) 'currentChatState': currentChatState,
        if (assignedProductId != null) 'assignedProductId': assignedProductId,
        'quickRepliesEnabled': quickRepliesEnabled,
      },
    );

    return AiSuggestResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<CrmMessage> sendMediaMessage({
    required String threadId,
    required PlatformFile file,
    String? caption,
    String? type,
  }) async {
    final resolvedType = (type != null && type.trim().isNotEmpty)
        ? type.trim()
        : _inferMediaType(file);

    final multipart = await _toMultipart(file);
    final form = FormData();
    form.files.add(MapEntry('file', multipart));
    // If type is omitted, backend will infer it from mime-type.
    if (resolvedType != null && resolvedType.trim().isNotEmpty) {
      form.fields.add(MapEntry('type', resolvedType.trim()));
    }
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

  Future<CrmChatStats> getChatStats() async {
    if (kDebugMode) {
      debugPrint('[CRM][HTTP] GET /crm/chats/stats');
    }
    // Some deployments don't have this endpoint yet (404).
    // Avoid throwing in Dio so the debugger won't pause on exceptions.
    final res = await _dio.get(
      '/crm/chats/stats',
      options: Options(validateStatus: (s) => s != null && s < 500),
    );

    final status = res.statusCode ?? 0;
    if (status == 404) {
      if (kDebugMode) {
        debugPrint('[CRM][HTTP] /crm/chats/stats -> 404 (not available)');
      }
      return const CrmChatStats(
        total: 0,
        byStatus: {},
        importantCount: 0,
        unreadTotal: 0,
      );
    }

    if (status >= 400) {
      if (kDebugMode) {
        debugPrint('[CRM][HTTP] /crm/chats/stats -> $status (ignored)');
      }
      return const CrmChatStats(
        total: 0,
        byStatus: {},
        importantCount: 0,
        unreadTotal: 0,
      );
    }

    final data = res.data as Map<String, dynamic>;
    return CrmChatStats.fromJson(data);
  }

  Future<List<CrmQuickReply>> listQuickReplies({
    String? search,
    String? category,
    bool? isActive,
  }) async {
    if (kDebugMode) {
      debugPrint(
        '[CRM][HTTP] GET /crm/quick-replies search=$search category=$category isActive=$isActive',
      );
    }

    final res = await _dio.get(
      '/crm/quick-replies',
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (category != null && category.trim().isNotEmpty)
          'category': category.trim(),
        if (isActive != null) 'isActive': isActive.toString(),
      },
    );

    final data = res.data as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(CrmQuickReply.fromJson)
        .toList();
    return items;
  }

  Future<CrmQuickReply> createQuickReply({
    required String title,
    required String category,
    required String content,
    String? keywords,
    bool allowComment = true,
    bool isActive = true,
  }) async {
    final res = await _dio.post(
      '/crm/quick-replies',
      data: {
        'title': title,
        'category': category,
        'content': content,
        'keywords': keywords,
        'allowComment': allowComment,
        'isActive': isActive,
      },
    );

    final data = res.data as Map<String, dynamic>;
    return CrmQuickReply.fromJson(data['item'] as Map<String, dynamic>);
  }

  Future<CrmQuickReply> updateQuickReply({
    required String id,
    required String title,
    required String category,
    required String content,
    String? keywords,
    bool allowComment = true,
    bool isActive = true,
  }) async {
    final res = await _dio.put(
      '/crm/quick-replies/$id',
      data: {
        'title': title,
        'category': category,
        'content': content,
        'keywords': keywords,
        'allowComment': allowComment,
        'isActive': isActive,
      },
    );

    final data = res.data as Map<String, dynamic>;
    return CrmQuickReply.fromJson(data['item'] as Map<String, dynamic>);
  }

  Future<void> deleteQuickReply(String id) async {
    await _dio.delete('/crm/quick-replies/$id');
  }

  static String? _inferMediaType(PlatformFile f) {
    final ext = (f.extension ?? '').toLowerCase();
    if (ext.trim().isEmpty) return null;
    if ({'jpg', 'jpeg', 'png', 'gif', 'webp'}.contains(ext)) return 'image';
    if ({'mp4', 'mov', 'avi', 'mkv', 'webm', '3gp'}.contains(ext))
      return 'video';
    if ({'mp3', 'wav', 'aac', 'm4a', 'ogg', 'opus'}.contains(ext))
      return 'audio';
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
    throw UnsupportedError(
      'Convert to customer is not supported in the new CRM API',
    );
  }

  // Evolution/WhatsApp Integration endpoints
  Future<Map<String, dynamic>> getEvolutionConfig() async {
    if (kDebugMode) {
      debugPrint('[CRM][HTTP] GET /integrations/evolution/config');
    }
    try {
      final res = await _dio.get('/integrations/evolution/config');
      return res.data as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) debugPrint('[CRM] Error getting config: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getEvolutionStatus() async {
    if (kDebugMode) {
      debugPrint('[CRM][HTTP] GET /integrations/evolution/status');
    }
    try {
      final res = await _dio.get('/integrations/evolution/status');
      return res.data as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) debugPrint('[CRM] Error getting status: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> testEvolutionPing() async {
    if (kDebugMode) {
      debugPrint('[CRM][HTTP] GET /integrations/evolution/ping');
    }
    try {
      final res = await _dio.get('/integrations/evolution/ping');
      return res.data as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) debugPrint('[CRM] Error testing ping: $e');
      rethrow;
    }
  }

  Future<void> saveEvolutionConfig(Map<String, dynamic> config) async {
    if (kDebugMode) {
      debugPrint('[CRM][HTTP] PATCH /admin/integrations/evolution/config');
    }
    try {
      await _dio.patch('/admin/integrations/evolution/config', data: config);
    } catch (e) {
      if (kDebugMode) debugPrint('[CRM] Error saving config: $e');
      rethrow;
    }
  }

  // Mark chat as read
  Future<void> markChatRead(String chatId) async {
    if (kDebugMode) {
      debugPrint('[CRM][HTTP] PATCH /crm/chats/$chatId/read');
    }
    // Best-effort: if backend doesn't support it (404) or returns 4xx,
    // don't throw (debugger pauses on thrown DioException).
    final res = await _dio.patch(
      '/crm/chats/$chatId/read',
      options: Options(validateStatus: (s) => s != null && s < 500),
    );

    final status = res.statusCode ?? 0;
    if (status >= 400 && kDebugMode) {
      debugPrint('[CRM][HTTP] /crm/chats/$chatId/read -> $status (ignored)');
    }
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
