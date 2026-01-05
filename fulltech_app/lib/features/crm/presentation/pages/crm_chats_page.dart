import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/debouncer.dart';
import '../../../../core/widgets/compact_error_widget.dart';
import '../../state/crm_providers.dart';
import '../../state/crm_threads_state.dart';
import '../../data/models/crm_thread.dart';
import '../widgets/chat_list_item_pro.dart';
import 'thread_chat_page.dart';
import '../widgets/right_panel_crm.dart';

class CrmChatsPage extends ConsumerStatefulWidget {
  const CrmChatsPage({super.key});

  @override
  ConsumerState<CrmChatsPage> createState() => _CrmChatsPageState();
}

class _CrmChatsPageState extends ConsumerState<CrmChatsPage> {
  final Debouncer _debouncer = Debouncer(
    delay: const Duration(milliseconds: 400),
  );

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(crmThreadsControllerProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(crmChatFiltersProvider, (prev, next) {
      // Apply debounce when filters change
      _debouncer.run(() {
        final notifier = ref.read(crmThreadsControllerProvider.notifier);
        notifier.setSearch(next.searchText);
        notifier.setEstado(next.status);
        notifier.setProductId(next.productId);
        notifier.refresh();
      });
    });

    final threadsState = ref.watch(crmThreadsControllerProvider);
    final selectedId = ref.watch(selectedThreadIdProvider);
    final filters = ref.watch(crmChatFiltersProvider);

    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;
    final isDesktop3Pane = width >= 1200;

    final filtered = _filterThreads(threadsState.items, filters);

    final left = _ThreadsList(
      threadsState: threadsState,
      visibleItems: filtered,
      selectedId: selectedId,
      onSelect: (id) {
        if (kDebugMode) {
          debugPrint('[CRM][UI] Selected threadId=$id');
        }
        ref.read(selectedThreadIdProvider.notifier).state = id;
        if (isMobile) {
          context.go('${AppRoutes.crm}/chats/$id');
        }
      },
    );

    if (!isDesktop3Pane) {
      return left;
    }

    final center = selectedId == null
        ? const _EmptyPanel(text: 'Selecciona un chat')
        : ThreadChatPanel(threadId: selectedId);

    final right = selectedId == null
        ? const _EmptyPanel(text: 'Detalles')
        : RightPanelCrm(threadId: selectedId);

    final rightWidth = (width * 0.28).clamp(340.0, 420.0);

    return Row(
      children: [
        SizedBox(width: 360, child: left),
        const SizedBox(width: 12),
        Expanded(child: center),
        const SizedBox(width: 12),
        SizedBox(width: rightWidth, child: right),
      ],
    );
  }

  static List<CrmThread> _filterThreads(
    List<CrmThread> items,
    dynamic filters,
  ) {
    final q = (filters.searchText as String).trim().toLowerCase();
    final status = (filters.status as String).trim();
    final productId = filters.productId as String?;

    bool matchesSearch(CrmThread t) {
      if (q.isEmpty) return true;
      final hay = <String?>[
        t.displayName,
        t.phone,
        t.waId,
        t.lastMessagePreview,
      ].whereType<String>().join(' ').toLowerCase();
      return hay.contains(q);
    }

    bool matchesStatus(CrmThread t) {
      if (status.isEmpty || status == 'todos') return true;
      return t.status.trim() == status;
    }

    bool matchesProduct(CrmThread t) {
      if (productId == null || productId.trim().isEmpty) return true;
      return (t.productId ?? '').trim() == productId.trim();
    }

    return items
        .where((t) => matchesSearch(t) && matchesStatus(t) && matchesProduct(t))
        .toList();
  }
}

class _ThreadsList extends ConsumerWidget {
  final CrmThreadsState threadsState;
  final List<CrmThread> visibleItems;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const _ThreadsList({
    required this.threadsState,
    required this.visibleItems,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(crmThreadsControllerProvider.notifier);
    final now = DateTime.now();
    // Use server-reported total so the number doesn't look "fixed" at the page size.
    final count = threadsState.total;
    final unansweredCount = visibleItems
        .where((t) => !t.lastMessageFromMe && t.unreadCount > 0)
        .length;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Chats: $count',
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('•'),
                const SizedBox(width: 12),
                Text(
                  'Sin responder: $unansweredCount',
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (threadsState.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final error = threadsState.error;
                if (error != null) {
                  return CompactErrorWidget(
                    error: error,
                    onRetry: () => notifier.refresh(),
                  );
                }

                final items = visibleItems;
                if (items.isEmpty) {
                  return const Center(child: Text('Sin chats'));
                }

                return ListView.builder(
                  itemCount: items.length + 1,
                  itemBuilder: (context, index) {
                    if (index == items.length) {
                      final total = threadsState.total;
                      final canLoadMore = threadsState.items.length < total;
                      return Padding(
                        padding: const EdgeInsets.all(10),
                        child: Align(
                          alignment: Alignment.center,
                          child: TextButton(
                            onPressed: canLoadMore
                                ? () => notifier.loadMore()
                                : null,
                            child: Text(canLoadMore ? 'Cargar más' : 'Fin'),
                          ),
                        ),
                      );
                    }

                    final CrmThread t = items[index];
                    return ChatListItemPro(
                      thread: t,
                      isSelected: selectedId == t.id,
                      onTap: () async {
                        onSelect(t.id);
                        // Mark as read
                        try {
                          await ref
                              .read(crmRepositoryProvider)
                              .markChatRead(t.id);
                          // Refresh to update unread count
                          await notifier.refresh();
                        } catch (e) {
                          if (kDebugMode) {
                            debugPrint('[CRM] Error marking read: $e');
                          }
                        }
                      },
                      now: now,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final String text;

  const _EmptyPanel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(child: Center(child: Text(text)));
  }
}
