import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fulltech_app/core/utils/debouncer.dart';
import 'dart:math' as math;

import '../data/repositories/crm_repository.dart';
import '../data/models/crm_thread.dart';
import 'crm_threads_state.dart';

class CrmThreadsController extends StateNotifier<CrmThreadsState> {
  final CrmRepository _repo;
  final Debouncer _debouncer = Debouncer(
    delay: const Duration(milliseconds: 400),
  );

  CrmThreadsController({required CrmRepository repo})
    : _repo = repo,
      super(CrmThreadsState.initial());

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  Future<void> refresh() async {
    // Offline-first: show cached threads immediately (if any), then refresh.
    try {
      final cached = await _repo.readCachedThreads();
      if (cached.isNotEmpty) {
        state = state.copyWith(
          loading: false,
          error: null,
          offset: 0,
          items: cached,
          total: cached.length,
        );
      } else {
        state = state.copyWith(loading: true, error: null, offset: 0);
      }
    } catch (_) {
      // If cache fails, fall back to online behavior.
      state = state.copyWith(loading: true, error: null, offset: 0);
    }

    try {
      final page = await _repo.listThreads(
        search: state.search.isEmpty ? null : state.search,
        estado: state.estado == 'todos' ? null : state.estado,
        productId: state.productId,
        limit: state.limit,
        offset: 0,
      );

      // Persist latest snapshot (best-effort).
      try {
        await _repo.cacheThreads(page.items, replace: true);
      } catch (_) {}

      state = state.copyWith(
        loading: false,
        items: page.items,
        total: page.total,
        offset: page.offset,
      );
    } catch (e) {
      // Keep any cached items visible; surface the error.
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.loading) return;
    final nextOffset = state.offset + state.items.length;
    if (state.items.isNotEmpty && nextOffset >= state.total) return;

    state = state.copyWith(loading: true, error: null);
    try {
      final page = await _repo.listThreads(
        search: state.search.isEmpty ? null : state.search,
        estado: state.estado == 'todos' ? null : state.estado,
        productId: state.productId,
        limit: state.limit,
        offset: nextOffset,
      );

      // Best-effort cache append.
      try {
        await _repo.cacheThreads(page.items, replace: false);
      } catch (_) {}

      state = state.copyWith(
        loading: false,
        items: [...state.items, ...page.items],
        total: page.total,
        offset: nextOffset,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void setSearch(String value) {
    state = state.copyWith(search: value);
  }

  void setEstado(String value) {
    state = state.copyWith(estado: value);
  }

  void setProductId(String? value) {
    state = state.copyWith(productId: value);
  }

  Future<void> upsertLocalThread(CrmThread thread) async {
    final items = [...state.items];
    final idx = items.indexWhere((t) => t.id == thread.id);
    if (idx >= 0) {
      items[idx] = thread;
    } else {
      items.insert(0, thread);
    }

    // Sort newest first (last message / updated).
    items.sort((a, b) {
      final aKey = a.lastMessageAt ?? a.updatedAt;
      final bKey = b.lastMessageAt ?? b.updatedAt;
      return bKey.compareTo(aKey);
    });

    state = state.copyWith(
      items: items,
      total: math.max(state.total, items.length),
    );

    try {
      await _repo.cacheThreads([thread], replace: false);
    } catch (_) {
      // Ignore cache errors.
    }
  }
}
