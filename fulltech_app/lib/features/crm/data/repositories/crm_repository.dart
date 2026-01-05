import '../datasources/crm_remote_datasource.dart';
import '../models/crm_message.dart';
import '../models/crm_chat_stats.dart';
import '../models/crm_thread.dart';
import '../models/crm_quick_reply.dart';
import '../models/ai_settings.dart';
import '../models/ai_suggestion.dart';
import 'package:file_picker/file_picker.dart';

class CrmRepository {
  final CrmRemoteDataSource _remote;

  CrmRepository(this._remote);

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

  Future<MessagesPage> listMessages({
    required String threadId,
    int limit = 50,
    DateTime? before,
  }) {
    return _remote.listMessages(threadId: threadId, limit: limit, before: before);
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
    String? aiSuggestionId,
    String? aiSuggestedText,
    List<String>? aiUsedKnowledge,
  }) {
    return _remote.sendMessage(
      threadId: threadId,
      type: type,
      message: message,
      mediaUrl: mediaUrl,
      aiSuggestionId: aiSuggestionId,
      aiSuggestedText: aiSuggestedText,
      aiUsedKnowledge: aiUsedKnowledge,
    );
  }

  Future<CrmMessage> sendMediaMessage({
    required String threadId,
    required PlatformFile file,
    String? caption,
    String? type,
  }) {
    return _remote.sendMediaMessage(
      threadId: threadId,
      file: file,
      caption: caption,
      type: type,
    );
  }

  Future<ConvertResult> convertThreadToCustomer(String threadId) =>
      _remote.convertThreadToCustomer(threadId);

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
  Future<AiSettingsPublic> getAiSettingsPublic() => _remote.getAiSettingsPublic();
  Future<AiSettings> getAiSettings() => _remote.getAiSettings();
  Future<AiSettings> patchAiSettings(Map<String, dynamic> patch) => _remote.patchAiSettings(patch);

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
