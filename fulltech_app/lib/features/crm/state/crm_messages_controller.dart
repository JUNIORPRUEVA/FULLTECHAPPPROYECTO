import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../data/repositories/crm_repository.dart';
import 'crm_messages_state.dart';

class CrmMessagesController extends StateNotifier<CrmMessagesState> {
  final CrmRepository _repo;
  final String _threadId;

  CrmMessagesController({
    required CrmRepository repo,
    required String threadId,
  })  : _repo = repo,
        _threadId = threadId,
        super(CrmMessagesState.initial());

  Future<void> loadInitial() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final page = await _repo.listMessages(threadId: _threadId);
      state = state.copyWith(
        loading: false,
        items: page.items,
        nextBefore: page.nextBefore,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore) return;
    if (state.nextBefore == null) return;

    state = state.copyWith(loadingMore: true, error: null);
    try {
      final page = await _repo.listMessages(threadId: _threadId, before: state.nextBefore);
      state = state.copyWith(
        loadingMore: false,
        items: [...page.items, ...state.items],
        nextBefore: page.nextBefore,
      );
    } catch (e) {
      state = state.copyWith(loadingMore: false, error: e.toString());
    }
  }

  Future<void> sendText(String text) async {
    final body = text.trim();
    if (body.isEmpty) return;

    state = state.copyWith(sending: true, error: null);
    try {
      await _repo.sendMessage(threadId: _threadId, message: body);
      final page = await _repo.listMessages(threadId: _threadId);
      state = state.copyWith(
        sending: false,
        items: page.items,
        nextBefore: page.nextBefore,
      );
    } catch (e) {
      state = state.copyWith(sending: false, error: e.toString());
    }
  }

  Future<void> sendMedia(PlatformFile file, {String? caption}) async {
    state = state.copyWith(sending: true, error: null);
    try {
      await _repo.sendMediaMessage(threadId: _threadId, file: file, caption: caption);
      final page = await _repo.listMessages(threadId: _threadId);
      state = state.copyWith(
        sending: false,
        items: page.items,
        nextBefore: page.nextBefore,
      );
    } catch (e) {
      state = state.copyWith(sending: false, error: e.toString());
    }
  }
}
