import 'dart:convert';

import '../datasources/crm_remote_datasource.dart';
import '../models/crm_message.dart';
import '../models/crm_chat_stats.dart';
import '../models/crm_thread.dart';
import '../models/crm_quick_reply.dart';
import '../models/ai_settings.dart';
import '../models/ai_suggestion.dart';
import '../models/customer.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/storage/local_db_interface.dart';
import '../../../../core/storage/db_write_queue.dart';

class CrmRepository {
  final CrmRemoteDataSource _remote;
  final LocalDb _db;

  static const String threadsStore = 'crm_threads_v1';
  static String messagesStoreForThread(String threadId) =>
      'crm_messages_v1:$threadId';

  CrmRepository(this._remote, this._db);

  Future<List<CrmThread>> readCachedThreads() async {
    final rows = await _db.listEntitiesJson(store: threadsStore);
    final items = rows
        .map((s) => CrmThread.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList(growable: false);

    // Sort newest first (last message / updated).
    items.sort((a, b) {
      final aKey = a.lastMessageAt ?? a.updatedAt;
      final bKey = b.lastMessageAt ?? b.updatedAt;
      return bKey.compareTo(aKey);
    });
    return items;
  }

  Future<void> cacheThreads(
    List<CrmThread> threads, {
    bool replace = false,
  }) async {
    if (threads.isEmpty) return;

    // Batch all writes into a single queued operation
    await dbWriteQueue.enqueue(() async {
      if (replace) {
        await _db.clearStoreDirect(store: threadsStore);
      }
      // Write all threads in this single transaction
      for (final t in threads) {
        final json = jsonEncode(t.toJson());
        await _db.upsertEntityDirect(store: threadsStore, id: t.id, json: json);
      }
    });
  }

  Future<List<CrmMessage>> readCachedMessages({
    required String threadId,
  }) async {
    final store = messagesStoreForThread(threadId);
    final rows = await _db.listEntitiesJson(store: store);
    final items = rows
        .map((s) => CrmMessage.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList(growable: false);

    // Ensure chronological order (oldest -> newest).
    items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return items;
  }

  Future<void> cacheMessages(
    List<CrmMessage> messages, {
    required String threadId,
    bool replace = false,
  }) async {
    if (messages.isEmpty) return;

    final store = messagesStoreForThread(threadId);
    // Batch all writes into a single queued operation
    await dbWriteQueue.enqueue(() async {
      if (replace) {
        await _db.clearStoreDirect(store: store);
      }
      // Write all messages in this single transaction
      for (final m in messages) {
        final json = jsonEncode(m.toJson());
        await _db.upsertEntityDirect(store: store, id: m.id, json: json);
      }
    });
  }

  Future<ThreadsPage> listThreads({
    String? search,
    String? estado,
    String? productId,
    bool? pinned,
    String? assignedUserId,
    int limit = 30,
    int offset = 0,
  }) {
    return _remote.listThreads(
      search: search,
      estado: estado,
      productId: productId,
      pinned: pinned,
      assignedUserId: assignedUserId,
      limit: limit,
      offset: offset,
    );
  }

  Future<CrmThread> getThread(String id) => _remote.getThread(id);

  Future<CrmThread> patchThread(String id, Map<String, dynamic> patch) =>
      _remote.patchThread(id, patch);

  Future<CrmThread> patchChat(String chatId, Map<String, dynamic> patch) =>
      _remote.patchChat(chatId, patch);

  Future<CrmThread> postChatStatus(String chatId, Map<String, dynamic> payload) =>
      _remote.postChatStatus(chatId, payload);

  Future<void> deleteChat(String chatId) => _remote.deleteChat(chatId);

  Future<MessagesPage> listMessages({
    required String threadId,
    int limit = 50,
    DateTime? before,
  }) {
    return _remote.listMessages(
      threadId: threadId,
      limit: limit,
      before: before,
    );
  }

  Future<CrmMessage> editChatMessage({
    required String threadId,
    required String messageId,
    required String text,
  }) {
    return _remote.editChatMessage(
      threadId: threadId,
      messageId: messageId,
      text: text,
    );
  }

  Future<CrmMessage> deleteChatMessage({
    required String threadId,
    required String messageId,
  }) {
    return _remote.deleteChatMessage(threadId: threadId, messageId: messageId);
  }

  Future<CrmMessage> postMessage({
    required String threadId,
    required bool fromMe,
    String type = 'text',
    String? body,
    String? mediaUrl,
  }) {
    return _remote.postMessage(
      threadId: threadId,
      fromMe: fromMe,
      type: type,
      body: body,
      mediaUrl: mediaUrl,
    );
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
  }) {
    return _remote.sendMessage(
      threadId: threadId,
      type: type,
      message: message,
      mediaUrl: mediaUrl,
      toWaId: toWaId,
      toPhone: toPhone,
      aiSuggestionId: aiSuggestionId,
      aiSuggestedText: aiSuggestedText,
      aiUsedKnowledge: aiUsedKnowledge,
    );
  }

  Future<Map<String, dynamic>> sendOutboundTextMessage({
    required String phone,
    required String text,
    String? status,
    String? displayName,
  }) {
    return _remote.sendOutboundTextMessage(
      phone: phone,
      text: text,
      status: status,
      displayName: displayName,
    );
  }

  Future<CrmMessage> sendMediaMessage({
    required String threadId,
    required PlatformFile file,
    String? caption,
    String? type,
    String? toWaId,
    String? toPhone,
  }) {
    return _remote.sendMediaMessage(
      threadId: threadId,
      file: file,
      caption: caption,
      type: type,
      toWaId: toWaId,
      toPhone: toPhone,
    );
  }

  Future<CrmMessage> sendLocationMessage({
    required String threadId,
    required double latitude,
    required double longitude,
    String? label,
    String? address,
    String? toWaId,
    String? toPhone,
  }) {
    return _remote.sendLocationMessage(
      threadId: threadId,
      latitude: latitude,
      longitude: longitude,
      label: label,
      address: address,
      toWaId: toWaId,
      toPhone: toPhone,
    );
  }

  Future<ConvertResult> convertThreadToCustomer(String threadId) =>
      _remote.convertThreadToCustomer(threadId);

  Future<Customer> convertChatToCustomer(String chatId, {String? status}) =>
      _remote.convertChatToCustomer(chatId, status: status);

  Future<CrmChatStats> getChatStats() => _remote.getChatStats();

  Future<List<CrmQuickReply>> listQuickReplies({
    String? search,
    String? category,
    bool? isActive,
  }) {
    return _remote.listQuickReplies(
      search: search,
      category: category,
      isActive: isActive,
    );
  }

  Future<CrmQuickReply> createQuickReply({
    required String title,
    required String category,
    required String content,
    String? keywords,
    bool allowComment = true,
    bool isActive = true,
  }) {
    return _remote.createQuickReply(
      title: title,
      category: category,
      content: content,
      keywords: keywords,
      allowComment: allowComment,
      isActive: isActive,
    );
  }

  Future<CrmQuickReply> updateQuickReply({
    required String id,
    required String title,
    required String category,
    required String content,
    String? keywords,
    bool allowComment = true,
    bool isActive = true,
  }) {
    return _remote.updateQuickReply(
      id: id,
      title: title,
      category: category,
      content: content,
      keywords: keywords,
      allowComment: allowComment,
      isActive: isActive,
    );
  }

  Future<void> deleteQuickReply(String id) => _remote.deleteQuickReply(id);

  // Evolution/WhatsApp Integration
  Future<Map<String, dynamic>> getEvolutionConfig() =>
      _remote.getEvolutionConfig();

  Future<Map<String, dynamic>> getEvolutionStatus() =>
      _remote.getEvolutionStatus();

  Future<Map<String, dynamic>> testEvolutionPing() =>
      _remote.testEvolutionPing();

  Future<void> saveEvolutionConfig(Map<String, dynamic> config) =>
      _remote.saveEvolutionConfig(config);

  // Mark chat as read
  Future<void> markChatRead(String chatId) => _remote.markChatRead(chatId);

  // AI
  Future<AiSettingsPublic> getAiSettingsPublic() =>
      _remote.getAiSettingsPublic();
  Future<AiSettings> getAiSettings() => _remote.getAiSettings();
  Future<AiSettings> patchAiSettings(Map<String, dynamic> patch) =>
      _remote.patchAiSettings(patch);

  Future<AiSuggestResponse> suggestAi({
    String? chatId,
    String? lastCustomerMessageId,
    required String customerMessageText,
    String? customerPhone,
    String? customerName,
    String? currentChatState,
    String? assignedProductId,
    bool quickRepliesEnabled = true,
  }) {
    return _remote.suggestAi(
      chatId: chatId,
      lastCustomerMessageId: lastCustomerMessageId,
      customerMessageText: customerMessageText,
      customerPhone: customerPhone,
      customerName: customerName,
      currentChatState: currentChatState,
      assignedProductId: assignedProductId,
      quickRepliesEnabled: quickRepliesEnabled,
    );
  }
}
