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
import '../../constants/crm_statuses.dart';
import '../widgets/chat_list_item_pro.dart';
import '../widgets/chat_thread_view.dart';
import '../widgets/crm_outbound_message_dialog.dart';
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

  bool _isRightPanelOpen = true;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isInitialized = true;
      // Start stats controller (with auth guard inside)
      ref.read(crmChatStatsControllerProvider.notifier).start();
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
      // Only refresh if actually initialized and filters actually changed
      if (!_isInitialized || prev == null) return;

      // Check if any filter actually changed
      final changed =
          prev.searchText != next.searchText ||
          prev.status != next.status ||
          prev.productId != next.productId;

      if (!changed) return;

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

    // No need to filter locally since the backend already filters by estado and productId
    // Only apply local search filter if needed for instant feedback
    final filtered = _filterThreadsLocally(threadsState.items, filters);

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
        : ChatThreadView(threadId: selectedId);

    final right = selectedId == null
        ? const _EmptyPanel(text: 'Detalles')
        : RightPanelCrm(threadId: selectedId);

    final rightWidth = (width * 0.28).clamp(340.0, 420.0);
    const collapsedWidth = 34.0;

    final rightColumn = SizedBox(
      width: _isRightPanelOpen ? rightWidth : collapsedWidth,
      child: Stack(
        children: [
          Positioned.fill(
            child: _isRightPanelOpen
                ? right
                : const Card(margin: EdgeInsets.zero, child: SizedBox.shrink()),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  tooltip: _isRightPanelOpen
                      ? 'Ocultar panel'
                      : 'Mostrar panel',
                  onPressed: () {
                    setState(() {
                      _isRightPanelOpen = !_isRightPanelOpen;
                    });
                  },
                  icon: Icon(
                    _isRightPanelOpen
                        ? Icons.chevron_right
                        : Icons.chevron_left,
                  ),
                  iconSize: 22,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Row(
      children: [
        SizedBox(width: 360, child: left),
        const SizedBox(width: 12),
        Expanded(child: center),
        const SizedBox(width: 12),
        rightColumn,
      ],
    );
  }

  /// Only apply local search filter for instant feedback
  /// Backend already handles estado and productId filtering
  static List<CrmThread> _filterThreadsLocally(
    List<CrmThread> items,
    dynamic filters,
  ) {
    final q = (filters.searchText as String).trim().toLowerCase();

    if (q.isEmpty) {
      // No local search filter needed, backend already filtered by estado and productId
      return items;
    }

    // Apply only search filter locally for instant feedback
    return items.where((t) {
      final hay = <String?>[
        t.displayName,
        t.phone,
        t.waId,
        t.lastMessagePreview,
      ].whereType<String>().join(' ').toLowerCase();
      return hay.contains(q);
    }).toList();
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

    return Stack(
      children: [
        Card(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
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

                    final postSale = items
                        .where((t) => CrmStatuses.isPostSaleStatus(t.status))
                        .toList(growable: false);
                    final normal = items
                        .where((t) => !CrmStatuses.isPostSaleStatus(t.status))
                        .toList(growable: false);

                    final hasDivider = postSale.isNotEmpty && normal.isNotEmpty;
                    final listLength =
                        postSale.length + (hasDivider ? 1 : 0) + normal.length;
                    final dividerIndex = postSale.length;

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 72),
                      itemCount: listLength + 1,
                      itemBuilder: (context, index) {
                        if (index == listLength) {
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

                        if (hasDivider && index == dividerIndex) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Divider(height: 18),
                          );
                        }

                        // Map list index -> correct thread list.
                        CrmThread t;
                        if (index >= 0 && index < postSale.length) {
                          t = postSale[index];
                        } else {
                          final normalOffset =
                              index - postSale.length - (hasDivider ? 1 : 0);
                          t = normal[normalOffset];
                        }

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
                          onEdit: () => _showEditChatDialog(context, ref, t),
                          onDelete: () => _showDeleteChatDialog(
                            context,
                            ref,
                            t,
                            () {
                              // After delete, clear selection if this was selected
                              if (selectedId == t.id) {
                                ref
                                        .read(selectedThreadIdProvider.notifier)
                                        .state =
                                    null;
                              }
                              notifier.refresh();
                            },
                          ),
                          now: now,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 14,
          top: 14,
          child: FloatingActionButton(
            heroTag: 'crm_new_outbound_chat_fab',
            mini: true,
            tooltip: 'Nuevo chat (número fuera de lista)',
            onPressed: () async {
              final result = await showDialog<CrmOutboundResult>(
                context: context,
                builder: (_) => const CrmOutboundMessageDialog(),
              );
              if (result == null) return;

              if (result.thread != null) {
                await notifier.upsertLocalThread(result.thread!);
              } else {
                await notifier.refresh();
              }

              onSelect(result.chatId);
            },
            child: const Icon(Icons.chat_bubble_outline),
          ),
        ),
      ],
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

// Dialog para editar chat
void _showEditChatDialog(
  BuildContext context,
  WidgetRef ref,
  CrmThread thread,
) {
  final nameController = TextEditingController(text: thread.displayName ?? '');

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Editar Chat'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre del contacto',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Teléfono: ${thread.phone ?? "No disponible"}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () async {
            try {
              await ref.read(crmRepositoryProvider).patchChat(thread.id, {
                'display_name': nameController.text.trim(),
              });
              await ref.read(crmThreadsControllerProvider.notifier).refresh();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chat actualizado')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
}

// Dialog para eliminar chat
void _showDeleteChatDialog(
  BuildContext context,
  WidgetRef ref,
  CrmThread thread,
  VoidCallback onDeleted,
) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Eliminar Chat'),
      content: Text(
        '¿Estás seguro de que deseas eliminar el chat con ${thread.displayName ?? thread.phone ?? "este contacto"}?\n\nEsta acción no se puede deshacer.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () async {
            try {
              await ref.read(crmRepositoryProvider).deleteChat(thread.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Chat eliminado')));
                onDeleted();
              }
            } catch (e) {
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al eliminar: $e'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            }
          },
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );
}
