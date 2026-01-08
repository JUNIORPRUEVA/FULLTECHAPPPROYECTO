import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'dart:io';
import 'dart:math' as math;

import '../models/crm_message.dart';
import '../models/crm_chat_stats.dart';
import '../models/crm_thread.dart';
import '../models/crm_quick_reply.dart';
import '../models/ai_settings.dart';
import '../models/ai_suggestion.dart';
import '../models/customer.dart';
import '../../../../core/services/app_config.dart';
import 'evolution_direct_client.dart';
import 'evolution_direct_settings.dart';

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
    extra: const {'offlineQueue': false},
  );

  Options get _jsonOptions => _defaultOptions.copyWith(
    contentType: Headers.jsonContentType,
    headers: const {
      // Some proxies/servers are strict about Accept.
      'Accept': 'application/json',
    },
  );

  Never _rethrowDio(String op, DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    final msg = e.message;
    throw Exception(
      '[CRM][$op] HTTP $status ${msg ?? ''} ${data ?? ''}'.trim(),
    );
  }

  Future<Map<String, dynamic>> _uploadCrmFile(PlatformFile file) async {
    Future<Map<String, dynamic>> doUpload(PlatformFile f) async {
      final multipart = await _toMultipart(f);
      final form = FormData();
      form.files.add(MapEntry('file', multipart));

      final res = await _dio.post(
        '/crm/upload',
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );

      return (res.data as Map<String, dynamic>);
    }

    try {
      return await doUpload(file);
    } catch (e) {
      if (e is DioException) {
        final status = e.response?.statusCode ?? 0;
        final data = e.response?.data;

        // If the server rejects the upload because it's too large, try to
        // compress images automatically (WhatsApp-like behavior).
        final maybeTooLarge =
            status == 413 ||
            (data is Map &&
                ((data['error']?.toString() ?? '').toLowerCase().contains(
                      'too large',
                    ) ||
                    (data['message']?.toString() ?? '').toLowerCase().contains(
                      'too large',
                    )));

        if (maybeTooLarge && _inferMediaType(file) == 'image') {
          final details = (data is Map) ? data['details'] : null;
          final maxUploadMb = (details is Map) ? details['maxUploadMb'] : null;
          final parsedMb = maxUploadMb is num
              ? maxUploadMb.toInt()
              : int.tryParse('$maxUploadMb');

          // Use server hint when available, otherwise target 4MB.
          final targetBytes =
              ((parsedMb != null && parsedMb > 0)
                  ? parsedMb * 1024 * 1024
                  : 4 * 1024 * 1024) -
              (200 * 1024);

          final compressed = await _compressImageToMaxBytes(
            file,
            maxBytes: targetBytes.clamp(256 * 1024, 50 * 1024 * 1024).toInt(),
          );

          return await doUpload(compressed);
        }
      }

      rethrow;
    }
  }

  static Future<PlatformFile> _compressImageToMaxBytes(
    PlatformFile file, {
    required int maxBytes,
  }) async {
    final originalBytes =
        file.bytes ??
        (file.path != null && file.path!.trim().isNotEmpty
            ? await File(file.path!).readAsBytes()
            : null);

    if (originalBytes == null) {
      throw Exception('No image bytes/path available for compression');
    }

    final decoded = img.decodeImage(originalBytes);
    if (decoded == null) {
      throw Exception('Unsupported image format (decode failed)');
    }

    // Estimate a good downscale factor up-front to minimize iterations.
    // Rough heuristic: encoded JPEG size ~ proportional to pixel count.
    final sizeRatio = maxBytes / originalBytes.length;
    final scaleEstimate = sizeRatio >= 1
        ? 1.0
        : (sizeRatio).clamp(0.05, 1.0).toDouble();
    final pixelScale = math.sqrt(scaleEstimate).clamp(0.25, 1.0);

    var targetW = decoded.width;
    var targetH = decoded.height;
    if (pixelScale < 0.99) {
      targetW = (decoded.width * pixelScale).round();
      targetH = (decoded.height * pixelScale).round();
    }

    // Cap very large images even if the ratio estimate isn't available.
    final maxDimension = decoded.width > decoded.height
        ? decoded.width
        : decoded.height;
    if (maxDimension > 2200) {
      final scale = 2200 / maxDimension;
      targetW = (targetW * scale).round();
      targetH = (targetH * scale).round();
    }

    targetW = targetW.clamp(640, decoded.width);
    targetH = targetH.clamp(640, decoded.height);

    img.Image working = decoded;
    if (working.width != targetW || working.height != targetH) {
      working = img.copyResize(working, width: targetW, height: targetH);
    }

    var quality = 80;
    List<int> encoded = img.encodeJpg(working, quality: quality);

    var guard = 0;
    while (encoded.length > maxBytes && guard < 6) {
      guard++;

      if (quality > 55) {
        quality = (quality - 15).clamp(55, 95);
      } else {
        final newW = (working.width * 0.80).round();
        final newH = (working.height * 0.80).round();
        if (newW < 640 || newH < 640) break;
        working = img.copyResize(working, width: newW, height: newH);
      }

      encoded = img.encodeJpg(working, quality: quality);
    }

    // If we still couldn't reach the target, return the best attempt
    // (it will likely still fail with 413, but we tried).
    final baseName = p.basenameWithoutExtension(file.name);
    final newName = '${baseName.isEmpty ? 'image' : baseName}.jpg';

    return PlatformFile(
      name: newName,
      size: encoded.length,
      bytes: Uint8List.fromList(encoded),
    );
  }

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
    final res = await _dio.get('/crm/chats/$id', options: _jsonOptions);
    final data = res.data as Map<String, dynamic>;
    final item = (data['item'] as Map<String, dynamic>);
    return CrmThread.fromJson(item);
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

  Future<CrmMessage> editChatMessage({
    required String threadId,
    required String messageId,
    required String text,
  }) async {
    final res = await _dio.patch(
      '/crm/chats/$threadId/messages/$messageId',
      data: {'text': text},
    );

    final data = res.data;
    if (data is Map<String, dynamic> && data['item'] is Map<String, dynamic>) {
      return CrmMessage.fromJson(data['item'] as Map<String, dynamic>);
    }
    if (data is Map<String, dynamic>) {
      return CrmMessage.fromJson(data);
    }
    throw Exception('Unexpected response for editChatMessage');
  }

  Future<CrmMessage> deleteChatMessage({
    required String threadId,
    required String messageId,
  }) async {
    final res = await _dio.delete('/crm/chats/$threadId/messages/$messageId');

    final data = res.data;
    if (data is Map<String, dynamic> && data['item'] is Map<String, dynamic>) {
      return CrmMessage.fromJson(data['item'] as Map<String, dynamic>);
    }
    if (data is Map<String, dynamic>) {
      return CrmMessage.fromJson(data);
    }
    throw Exception('Unexpected response for deleteChatMessage');
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
        options: _jsonOptions,
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
    String? toWaId,
    String? toPhone,
    String? aiSuggestionId,
    String? aiSuggestedText,
    List<String>? aiUsedKnowledge,
  }) async {
    if (type != 'text') {
      throw UnsupportedError('Use sendMediaMessage() for non-text messages');
    }

    // Optional: send directly via Evolution from the client app.
    // Then record in backend without sending again.
    final directSettings = await EvolutionDirectSettings.load();
    final useDirectRequested =
        AppConfig.crmSendDirectEvolution || directSettings.enabled;

    final baseUrl = AppConfig.evolutionApiBaseUrl.trim().isNotEmpty
        ? AppConfig.evolutionApiBaseUrl.trim()
        : directSettings.baseUrl;
    final apiKey = AppConfig.evolutionApiKey.trim().isNotEmpty
        ? AppConfig.evolutionApiKey.trim()
        : directSettings.apiKey;
    final instance = AppConfig.evolutionInstance.trim().isNotEmpty
        ? AppConfig.evolutionInstance.trim()
        : directSettings.instance;
    final defaultCountryCode =
        AppConfig.evolutionDefaultCountryCode.trim().isNotEmpty
        ? AppConfig.evolutionDefaultCountryCode.trim()
        : directSettings.defaultCountryCode;

    final directConfigured =
        baseUrl.trim().isNotEmpty &&
        apiKey.trim().isNotEmpty &&
        instance.trim().isNotEmpty;
    final useDirect = useDirectRequested && directConfigured;

    if (kDebugMode) {
      debugPrint('[CRM][SEND] ===== START SEND MESSAGE =====');
      debugPrint('[CRM][SEND] threadId=$threadId');
      debugPrint('[CRM][SEND] message length=${message?.length ?? 0}');
      debugPrint('[CRM][SEND] toWaId=$toWaId toPhone=$toPhone');
      debugPrint(
        '[CRM][SEND] directRequested=$useDirectRequested directConfigured=$directConfigured',
      );
      debugPrint('[CRM][SEND] baseUrl=$baseUrl');
      debugPrint('[CRM][SEND] instance=$instance');
      debugPrint(
        '[CRM][SEND] apiKey=${apiKey.isNotEmpty ? "SET (${apiKey.length} chars)" : "EMPTY"}',
      );
      debugPrint('[CRM][SEND] useDirect=$useDirect');
    }

    if (useDirect) {
      if (kDebugMode) {
        debugPrint('[CRM][SEND] 🚀 Using Evolution DIRECT send');
      }

      final evo = EvolutionDirectClient.create(
        baseUrl: baseUrl,
        apiKey: apiKey,
        instance: instance,
        defaultCountryCode: defaultCountryCode,
      );

      if (kDebugMode) {
        debugPrint('[CRM][SEND] Evolution client created, sending text...');
      }
      final send = await evo.sendText(
        text: (message ?? '').toString(),
        toWaId: toWaId,
        toPhone: toPhone,
      );
      if (kDebugMode) {
        debugPrint(
          '[CRM][SEND] ✅ Evolution direct send SUCCESS - messageId=${send.messageId}',
        );
      }
      if (send.messageId == null || send.messageId!.trim().isEmpty) {
        throw Exception('Evolution did not return messageId');
      }

      // Now record in backend
      if (kDebugMode) {
        debugPrint('[CRM][SEND] Recording message in backend...');
      }

      try {
        final res = await _dio.post(
          '/crm/chats/$threadId/messages/text',
          data: {
            'text': (message ?? '').toString(),
            'skipEvolution': true,
            'remoteMessageId': send.messageId,
            if (aiSuggestionId != null) 'aiSuggestionId': aiSuggestionId,
            if (aiSuggestedText != null) 'aiSuggestedText': aiSuggestedText,
            if (aiUsedKnowledge != null) 'aiUsedKnowledge': aiUsedKnowledge,
          },
          options: _jsonOptions,
        );

        final data = res.data as Map<String, dynamic>;
        if (kDebugMode) {
          debugPrint('[CRM][SEND] ✅ Backend record SUCCESS');
        }
        return CrmMessage.fromJson(data['item'] as Map<String, dynamic>);
      } catch (e) {
        // Evolution send succeeded, but backend record failed (old backend or server error).
        // Don't mark message as failed.
        if (kDebugMode) {
          debugPrint(
            '[CRM][SEND] ⚠️ Backend record FAILED but Evolution sent OK: $e',
          );
        }
        return CrmMessage(
          id: 'evo-${send.messageId}',
          fromMe: true,
          type: 'text',
          body: (message ?? '').toString(),
          mediaUrl: null,
          status: 'sent',
          createdAt: DateTime.now(),
        );
      }
    }

    // Default path: send via backend.
    if (kDebugMode) {
      debugPrint('[CRM][SEND] 📡 Using BACKEND send (not direct)');
    }
    try {
      final res = await _dio.post(
        '/crm/chats/$threadId/messages/text',
        data: {
          'text': (message ?? '').toString(),
          if (aiSuggestionId != null) 'aiSuggestionId': aiSuggestionId,
          if (aiSuggestedText != null) 'aiSuggestedText': aiSuggestedText,
          if (aiUsedKnowledge != null) 'aiUsedKnowledge': aiUsedKnowledge,
        },
        options: _jsonOptions,
      );

      final data = res.data as Map<String, dynamic>;
      if (kDebugMode) {
        debugPrint('[CRM][SEND] ✅ Backend send SUCCESS');
      }
      return CrmMessage.fromJson(data['item'] as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CRM][SEND] ❌ Backend send FAILED: $e');
      }
      // If backend is failing (e.g., HTTP 500), fall back to direct Evolution send when configured.
      if (!directConfigured) {
        if (kDebugMode) {
          debugPrint('[CRM][SEND] ❌ Cannot fallback - direct not configured');
        }
        rethrow;
      }

      if (kDebugMode) {
        debugPrint('[CRM][SEND] 🔄 Falling back to Evolution direct...');
      }

      final evo = EvolutionDirectClient.create(
        baseUrl: baseUrl,
        apiKey: apiKey,
        instance: instance,
        defaultCountryCode: defaultCountryCode,
      );
      final send = await evo.sendText(
        text: (message ?? '').toString(),
        toWaId: toWaId,
        toPhone: toPhone,
      );
      if (kDebugMode) {
        debugPrint(
          '[CRM][SEND] ✅ Fallback Evolution send SUCCESS - messageId=${send.messageId}',
        );
      }
      if (send.messageId == null || send.messageId!.trim().isEmpty) {
        throw Exception('Evolution did not return messageId');
      }

      try {
        final res = await _dio.post(
          '/crm/chats/$threadId/messages/text',
          data: {
            'text': (message ?? '').toString(),
            'skipEvolution': true,
            'remoteMessageId': send.messageId,
            if (aiSuggestionId != null) 'aiSuggestionId': aiSuggestionId,
            if (aiSuggestedText != null) 'aiSuggestedText': aiSuggestedText,
            if (aiUsedKnowledge != null) 'aiUsedKnowledge': aiUsedKnowledge,
          },
          options: _jsonOptions,
        );

        final data = res.data as Map<String, dynamic>;
        return CrmMessage.fromJson(data['item'] as Map<String, dynamic>);
      } catch (_) {
        return CrmMessage(
          id: 'evo-${send.messageId}',
          fromMe: true,
          type: 'text',
          body: (message ?? '').toString(),
          mediaUrl: null,
          status: 'sent',
          createdAt: DateTime.now(),
        );
      }
    }
  }

  Future<CrmMessage> sendLocationMessage({
    required String threadId,
    required double latitude,
    required double longitude,
    String? label,
    String? address,
    String? toWaId,
    String? toPhone,
  }) async {
    final directSettings = await EvolutionDirectSettings.load();
    final useDirectRequested =
        AppConfig.crmSendDirectEvolution || directSettings.enabled;

    final baseUrl = AppConfig.evolutionApiBaseUrl.trim().isNotEmpty
        ? AppConfig.evolutionApiBaseUrl.trim()
        : directSettings.baseUrl;
    final apiKey = AppConfig.evolutionApiKey.trim().isNotEmpty
        ? AppConfig.evolutionApiKey.trim()
        : directSettings.apiKey;
    final instance = AppConfig.evolutionInstance.trim().isNotEmpty
        ? AppConfig.evolutionInstance.trim()
        : directSettings.instance;
    final defaultCountryCode =
        AppConfig.evolutionDefaultCountryCode.trim().isNotEmpty
        ? AppConfig.evolutionDefaultCountryCode.trim()
        : directSettings.defaultCountryCode;

    final directConfigured =
        baseUrl.trim().isNotEmpty && apiKey.trim().isNotEmpty;
    final useDirect = useDirectRequested && directConfigured;

    final mapsUrl = 'https://www.google.com/maps?q=$latitude,$longitude';
    final safeLabel = (label ?? '').trim();
    final recordText = safeLabel.isEmpty
        ? 'Ubicación: $mapsUrl'
        : 'Ubicación ($safeLabel): $mapsUrl';

    // If direct isn't configured, fall back to a normal text message.
    if (!useDirect) {
      return sendMessage(threadId: threadId, message: recordText);
    }

    // Ensure destination is known when not provided.
    String? resolvedWaId = toWaId;
    String? resolvedPhone = toPhone;
    if ((resolvedWaId == null || resolvedWaId.trim().isEmpty) &&
        (resolvedPhone == null || resolvedPhone.trim().isEmpty)) {
      try {
        final chat = await getThread(threadId);
        resolvedWaId = chat.waId;
        resolvedPhone = chat.phone;
      } catch (_) {}
    }

    final evo = EvolutionDirectClient.create(
      baseUrl: baseUrl,
      apiKey: apiKey,
      instance: instance,
      defaultCountryCode: defaultCountryCode,
    );

    final send = await evo.sendLocation(
      latitude: latitude,
      longitude: longitude,
      name: safeLabel.isEmpty ? null : safeLabel,
      address: (address ?? '').trim().isEmpty ? null : address!.trim(),
      toWaId: resolvedWaId,
      toPhone: resolvedPhone,
    );

    if (send.messageId == null || send.messageId!.trim().isEmpty) {
      throw Exception('Evolution did not return messageId');
    }

    try {
      final res = await _dio.post(
        '/crm/chats/$threadId/messages/text',
        data: {
          'text': recordText,
          'skipEvolution': true,
          'remoteMessageId': send.messageId,
        },
        options: _jsonOptions,
      );

      final data = res.data as Map<String, dynamic>;
      return CrmMessage.fromJson(data['item'] as Map<String, dynamic>);
    } catch (_) {
      return CrmMessage(
        id: 'evo-${send.messageId}',
        fromMe: true,
        type: 'text',
        body: recordText,
        mediaUrl: null,
        status: 'sent',
        createdAt: DateTime.now(),
      );
    }
  }

  Future<Map<String, dynamic>> sendOutboundTextMessage({
    required String phone,
    required String text,
    String? status,
    String? displayName,
  }) async {
    String digitsOnly(String v) => v.replaceAll(RegExp(r'\D+'), '');

    String normalizePhoneForWhatsapp(String raw, {required String defaultCc}) {
      final digits = digitsOnly(raw);
      if (digits.isEmpty) return '';
      if (digits.length == 10) {
        final cc = digitsOnly(defaultCc).trim().isNotEmpty
            ? digitsOnly(defaultCc).trim()
            : '1';
        return '$cc$digits';
      }
      return digits;
    }

    final directSettings = await EvolutionDirectSettings.load();
    final useDirectRequested =
        AppConfig.crmSendDirectEvolution || directSettings.enabled;

    final baseUrl = AppConfig.evolutionApiBaseUrl.trim().isNotEmpty
        ? AppConfig.evolutionApiBaseUrl.trim()
        : directSettings.baseUrl;
    final apiKey = AppConfig.evolutionApiKey.trim().isNotEmpty
        ? AppConfig.evolutionApiKey.trim()
        : directSettings.apiKey;
    final instance = AppConfig.evolutionInstance.trim().isNotEmpty
        ? AppConfig.evolutionInstance.trim()
        : directSettings.instance;
    final defaultCountryCode =
        AppConfig.evolutionDefaultCountryCode.trim().isNotEmpty
        ? AppConfig.evolutionDefaultCountryCode.trim()
        : directSettings.defaultCountryCode;

    final directConfigured =
        baseUrl.trim().isNotEmpty && apiKey.trim().isNotEmpty;
    final useDirect = useDirectRequested && directConfigured;

    final normalizedPhone = normalizePhoneForWhatsapp(
      phone,
      defaultCc: defaultCountryCode,
    );
    if (normalizedPhone.trim().isEmpty) {
      throw Exception('Número inválido');
    }

    if (useDirect) {
      final evo = EvolutionDirectClient.create(
        baseUrl: baseUrl,
        apiKey: apiKey,
        instance: instance,
        defaultCountryCode: defaultCountryCode,
      );
      final send = await evo.sendText(
        text: text,
        toPhone: normalizedPhone,
        toWaId: null,
      );
      if (send.messageId == null || send.messageId!.trim().isEmpty) {
        throw Exception('Evolution no devolvió messageId');
      }

      final res = await _dio.post(
        '/crm/chats/outbound/text',
        data: {
          'phone': normalizedPhone,
          'text': text,
          if (status != null) 'status': status,
          if (displayName != null) 'displayName': displayName,
          'skipEvolution': true,
          'remoteMessageId': send.messageId,
        },
        options: _jsonOptions,
      );

      return (res.data as Map).cast<String, dynamic>();
    }

    final res = await _dio.post(
      '/crm/chats/outbound/text',
      data: {
        'phone': normalizedPhone,
        'text': text,
        if (status != null) 'status': status,
        if (displayName != null) 'displayName': displayName,
      },
      options: _jsonOptions,
    );

    return (res.data as Map).cast<String, dynamic>();
  }

  Future<AiSettingsPublic> getAiSettingsPublic() async {
    try {
      final res = await _dio.get('/ai/settings/public');
      return AiSettingsPublic.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      if (e is DioException) _rethrowDio('AI_SETTINGS_PUBLIC', e);
      rethrow;
    }
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
    try {
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
    } catch (e) {
      if (e is DioException) _rethrowDio('AI_SUGGEST', e);
      rethrow;
    }
  }

  Future<CrmMessage> sendMediaMessage({
    required String threadId,
    required PlatformFile file,
    String? caption,
    String? type,
    String? toWaId,
    String? toPhone,
  }) async {
    final resolvedType = (type != null && type.trim().isNotEmpty)
        ? type.trim()
        : _inferMediaType(file);

    final directSettings = await EvolutionDirectSettings.load();
    final useDirectRequested =
        AppConfig.crmSendDirectEvolution || directSettings.enabled;

    final baseUrl = AppConfig.evolutionApiBaseUrl.trim().isNotEmpty
        ? AppConfig.evolutionApiBaseUrl.trim()
        : directSettings.baseUrl;
    final apiKey = AppConfig.evolutionApiKey.trim().isNotEmpty
        ? AppConfig.evolutionApiKey.trim()
        : directSettings.apiKey;
    final instance = AppConfig.evolutionInstance.trim().isNotEmpty
        ? AppConfig.evolutionInstance.trim()
        : directSettings.instance;
    final defaultCountryCode =
        AppConfig.evolutionDefaultCountryCode.trim().isNotEmpty
        ? AppConfig.evolutionDefaultCountryCode.trim()
        : directSettings.defaultCountryCode;

    final directConfigured =
        baseUrl.trim().isNotEmpty && apiKey.trim().isNotEmpty;
    final useDirect = useDirectRequested && directConfigured;

    Future<CrmMessage> directFlow() async {
      final uploaded = await _uploadCrmFile(file);
      final mediaUrl = (uploaded['url'] ?? '').toString().trim();
      if (mediaUrl.isEmpty) throw Exception('Upload did not return url');

      String? resolvedWaId = toWaId;
      String? resolvedPhone = toPhone;
      if ((resolvedWaId == null || resolvedWaId.trim().isEmpty) &&
          (resolvedPhone == null || resolvedPhone.trim().isEmpty)) {
        // Fallback: fetch chat to resolve destination (covers cases where chat isn't in the current list page).
        try {
          final chat = await getThread(threadId);
          resolvedWaId = chat.waId;
          resolvedPhone = chat.phone;
        } catch (_) {
          // keep nulls; EvolutionDirectClient will throw a clear error
        }
      }

      final evo = EvolutionDirectClient.create(
        baseUrl: baseUrl,
        apiKey: apiKey,
        instance: instance,
        defaultCountryCode: defaultCountryCode,
      );

      final send = await evo.sendMedia(
        mediaUrl: mediaUrl,
        caption: caption,
        mediaType: resolvedType,
        toWaId: resolvedWaId,
        toPhone: resolvedPhone,
      );
      if (send.messageId == null || send.messageId!.trim().isEmpty) {
        throw Exception('Evolution did not return messageId');
      }

      try {
        final res = await _dio.post(
          '/crm/chats/$threadId/messages/media-record',
          data: {
            'mediaUrl': mediaUrl,
            'mimeType': uploaded['mime']?.toString(),
            'size': uploaded['size'],
            'fileName': uploaded['name']?.toString() ?? file.name,
            if (caption != null && caption.trim().isNotEmpty)
              'caption': caption.trim(),
            if (resolvedType != null && resolvedType.trim().isNotEmpty)
              'type': resolvedType.trim(),
            'skipEvolution': true,
            'remoteMessageId': send.messageId,
          },
          options: _jsonOptions,
        );

        final data = res.data as Map<String, dynamic>;
        final item = (data['item'] ?? data) as Map<String, dynamic>;
        return CrmMessage.fromJson(item);
      } catch (_) {
        // Evolution send succeeded, but backend record failed.
        return CrmMessage(
          id: 'evo-${send.messageId}',
          fromMe: true,
          type: resolvedType ?? 'media',
          body: (caption != null && caption.trim().isNotEmpty)
              ? caption.trim()
              : file.name,
          mediaUrl: mediaUrl,
          status: 'sent',
          createdAt: DateTime.now(),
        );
      }
    }

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

    try {
      final res = await _dio.post(
        '/crm/chats/$threadId/messages/media',
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );

      final data = res.data as Map<String, dynamic>;
      final item = (data['item'] ?? data) as Map<String, dynamic>;
      return CrmMessage.fromJson(item);
    } catch (e) {
      // If backend media send fails, fall back to direct Evolution send when configured.
      if (!useDirect) rethrow;
      if (kDebugMode) {
        debugPrint(
          '[CRM][SEND] backend media failed, falling back to Evolution direct: $e',
        );
      }
      return directFlow();
    }
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
    
    // 401: Throw to trigger auth handler and stop timer
    if (status == 401) {
      if (kDebugMode) {
        debugPrint('[CRM][HTTP] /crm/chats/stats -> 401 (unauthorized)');
      }
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        type: DioExceptionType.badResponse,
      );
    }
    
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

  Future<Customer> convertChatToCustomer(String chatId) async {
    if (kDebugMode) {
      debugPrint('[CRM][HTTP] POST /crm/chats/$chatId/convert-to-customer');
    }

    try {
      final res = await _dio.post(
        '/crm/chats/$chatId/convert-to-customer',
        options: _jsonOptions,
      );
      final data = res.data as Map<String, dynamic>;
      final customerJson = data['customer'] as Map<String, dynamic>;
      return Customer.fromJson(customerJson);
    } on DioException catch (e) {
      _rethrowDio('convertChatToCustomer', e);
    }
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
      debugPrint('[CRM][HTTP] PATCH /integrations/evolution/config');
    }
    try {
      await _dio.patch('/integrations/evolution/config', data: config);
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
