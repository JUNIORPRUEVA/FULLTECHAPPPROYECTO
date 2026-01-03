import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../state/crm_providers.dart';
import '../../state/crm_threads_state.dart';
import '../../data/models/crm_thread.dart';
import '../widgets/thread_tile.dart';
import 'thread_chat_page.dart';

class CrmChatsPage extends ConsumerStatefulWidget {
  const CrmChatsPage({super.key});

  @override
  ConsumerState<CrmChatsPage> createState() => _CrmChatsPageState();
}

class _CrmChatsPageState extends ConsumerState<CrmChatsPage> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(crmThreadsControllerProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final threadsState = ref.watch(crmThreadsControllerProvider);
    final selectedId = ref.watch(selectedThreadIdProvider);

    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;
    final isDesktop3Pane = width >= 1200;

    final left = _ThreadsList(
      searchCtrl: _searchCtrl,
      threadsState: threadsState,
      selectedId: selectedId,
      onSelect: (id) {
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
        : ThreadInfoPanel(threadId: selectedId);

    return Row(
      children: [
        SizedBox(width: 360, child: left),
        const SizedBox(width: 12),
        Expanded(child: center),
        const SizedBox(width: 12),
        SizedBox(width: 320, child: right),
      ],
    );
  }
}

class _ThreadsList extends ConsumerWidget {
  final TextEditingController searchCtrl;
  final CrmThreadsState threadsState;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const _ThreadsList({
    required this.searchCtrl,
    required this.threadsState,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(crmThreadsControllerProvider.notifier);

    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: searchCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Buscar',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) {
                    notifier.setSearch(v);
                    notifier.refresh();
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Refrescar',
                      onPressed: () => notifier.refresh(),
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Builder(
              builder: (context) {
                if (threadsState.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final error = threadsState.error;
                if (error != null) {
                  return Center(child: Text(error));
                }

                final items = threadsState.items;
                if (items.isEmpty) {
                  return const Center(child: Text('Sin chats'));
                }

                return ListView.separated(
                  itemCount: items.length + 1,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    if (index == items.length) {
                      final total = threadsState.total;
                      final canLoadMore = items.length < total;
                      return Padding(
                        padding: const EdgeInsets.all(10),
                        child: Align(
                          alignment: Alignment.center,
                          child: TextButton(
                            onPressed: canLoadMore ? () => notifier.loadMore() : null,
                            child: Text(canLoadMore ? 'Cargar más' : 'Fin'),
                          ),
                        ),
                      );
                    }

                    final CrmThread t = items[index];
                    return ThreadTile(
                      thread: t,
                      selected: selectedId == t.id,
                      onTap: () => onSelect(t.id),
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
    return Card(
      child: Center(child: Text(text)),
    );
  }
}
