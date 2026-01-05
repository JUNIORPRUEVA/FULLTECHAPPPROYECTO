import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../data/models/crm_message.dart';

import '../data/repositories/crm_repository.dart';
import 'crm_messages_state.dart';

class CrmMessagesController extends StateNotifier<CrmMessagesState> {
  final CrmRepository _repo;
  final String _threadId;

  CrmMessagesController({required CrmRepository repo, required String threadId})
    : _repo = repo,
      _threadId = threadId,
      super(CrmMessagesState.initial());

  Future<void> loadInitial() async {
    if (kDebugMode) {
      debugPrint('[CRM][STATE] loadInitial threadId=$_threadId');
    }
    state = state.copyWith(loading: true, error: null);
    try {
      final page = await _repo.listMessages(threadId: _threadId);
      state = state.copyWith(
        loading: false,
        items: page.items,
        nextBefore: page.nextBefore,
        error: null,
      );
      if (kDebugMode) {
        debugPrint(
          '[CRM][STATE] loadInitial done threadId=$_threadId items=${page.items.length} nextBefore=${page.nextBefore}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[CRM][STATE] loadInitial error threadId=$_threadId error=$e',
        );
      }
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore) return;
    if (state.nextBefore == null) return;

    if (kDebugMode) {
      debugPrint(
        '[CRM][STATE] loadMore threadId=$_threadId before=${state.nextBefore}',
      );
    }

    state = state.copyWith(loadingMore: true, error: null);
    try {
      final page = await _repo.listMessages(
        threadId: _threadId,
        before: state.nextBefore,
      );
      state = state.copyWith(
        loadingMore: false,
        items: [...page.items, ...state.items],
        nextBefore: page.nextBefore,
      );
      if (kDebugMode) {
        debugPrint(
          '[CRM][STATE] loadMore done threadId=$_threadId added=${page.items.length} total=${state.items.length} nextBefore=${page.nextBefore}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CRM][STATE] loadMore error threadId=$_threadId error=$e');
      }
      state = state.copyWith(loadingMore: false, error: e.toString());
    }
  }

  Future<void> sendText(
    String text, {
    String? aiSuggestionId,
    String? aiSuggestedText,
    List<String>? aiUsedKnowledge,
  }) async {
    final body = text.trim();
    if (body.isEmpty) return;

    if (kDebugMode) {
      debugPrint(
        '[CRM][STATE] sendText threadId=$_threadId len=${body.length}',
      );
    }

    final tempId = 'local-${DateTime.now().microsecondsSinceEpoch}';
    final optimistic = CrmMessage(
      id: tempId,
      fromMe: true,
      type: 'text',
      body: body,
      mediaUrl: null,
      status: 'sending',
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      sending: true,
      error: null,
      items: [...state.items, optimistic],
    );
    try {
      final sent = await _repo.sendMessage(
        threadId: _threadId,
        message: body,
        aiSuggestionId: aiSuggestionId,
        aiSuggestedText: aiSuggestedText,
        aiUsedKnowledge: aiUsedKnowledge,
      );

      final next = state.items
          .map((m) => m.id == tempId ? sent : m)
          .toList(growable: false);
      state = state.copyWith(sending: false, items: next, error: null);
      if (kDebugMode) {
        debugPrint(
          '[CRM][STATE] sendText done threadId=$_threadId optimisticId=$tempId serverId=${sent.id}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CRM][STATE] sendText error threadId=$_threadId error=$e');
      }

      final next = state.items
          .map((m) => m.id == tempId
              ? CrmMessage(
                  id: m.id,
                  fromMe: m.fromMe,
                  type: m.type,
                  body: m.body,
                  mediaUrl: m.mediaUrl,
                  status: 'failed',
                  createdAt: m.createdAt,
                )
              : m)
          .toList(growable: false);
      state = state.copyWith(sending: false, error: e.toString(), items: next);
    }
  }

  Future<void> sendMedia(PlatformFile file, {String? caption, String? type}) async {
    if (kDebugMode) {
      debugPrint(
        '[CRM][STATE] sendMedia threadId=$_threadId file=${file.name}',
      );
    }
    final tempId = 'local-${DateTime.now().microsecondsSinceEpoch}';
    final resolvedType = (type ?? '').trim().isEmpty ? 'media' : type!.trim();
    final optimistic = CrmMessage(
      id: tempId,
      fromMe: true,
      type: resolvedType,
      body: (caption != null && caption.trim().isNotEmpty)
          ? caption.trim()
          : file.name,
      mediaUrl: null,
      status: 'sending',
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      sending: true,
      error: null,
      items: [...state.items, optimistic],
    );
    try {
      final sent = await _repo.sendMediaMessage(
        threadId: _threadId,
        file: file,
        caption: caption,
        type: type,
      );

      final next = state.items
          .map((m) => m.id == tempId ? sent : m)
          .toList(growable: false);
      state = state.copyWith(sending: false, items: next, error: null);
      if (kDebugMode) {
        debugPrint(
          '[CRM][STATE] sendMedia done threadId=$_threadId optimisticId=$tempId serverId=${sent.id}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CRM][STATE] sendMedia error threadId=$_threadId error=$e');
      }

      final next = state.items
          .map((m) => m.id == tempId
              ? CrmMessage(
                  id: m.id,
                  fromMe: m.fromMe,
                  type: m.type,
                  body: m.body,
                  mediaUrl: m.mediaUrl,
                  status: 'failed',
                  createdAt: m.createdAt,
                )
              : m)
          .toList(growable: false);
      state = state.copyWith(sending: false, error: e.toString(), items: next);
    }
  }
}
