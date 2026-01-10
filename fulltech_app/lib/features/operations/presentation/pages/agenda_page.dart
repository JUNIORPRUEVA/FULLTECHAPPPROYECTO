import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/module_page.dart';
import '../../../crm/data/models/crm_operations_item.dart';
import '../../../crm/data/models/crm_thread.dart';
import '../../../crm/state/crm_providers.dart';

final _crmThreadByIdProvider = FutureProvider.family<CrmThread, String>((
  ref,
  threadId,
) async {
  final repo = ref.watch(crmRepositoryProvider);
  return repo.getThread(threadId);
});

class AgendaPage extends ConsumerWidget {
  const AgendaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep CRM SSE alive while this screen is open, so operations refresh happens
    // without manual reload.
    ref.watch(crmRealtimeProvider);

    final opsAsync = ref.watch(crmOperationsItemsProvider);

    return ModulePage(
      title: 'Operaciones',
      actions: [
        IconButton(
          tooltip: 'Refrescar',
          onPressed: () => ref.invalidate(crmOperationsItemsProvider),
          icon: const Icon(Icons.refresh),
        ),
      ],
      child: opsAsync.when(
        data: (data) {
          final agenda = [...data.agenda];
          agenda.sort((a, b) {
            final adt = a.scheduledAt;
            final bdt = b.scheduledAt;
            if (adt == null && bdt == null) return 0;
            if (adt == null) return 1;
            if (bdt == null) return -1;
            return adt.compareTo(bdt);
          });

          final levantamientos = [...data.levantamientos];
          levantamientos.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  isScrollable: true,
                  tabs: [
                    Tab(text: 'AGENDA'),
                    Tab(text: 'LEVANTAMIENTOS'),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TabBarView(
                    children: [
                      _OperationsItemsList(
                        emptyLabel: 'No hay elementos en Agenda',
                        items: agenda,
                        showScheduledAt: true,
                      ),
                      _OperationsItemsList(
                        emptyLabel: 'No hay elementos en Levantamientos',
                        items: levantamientos,
                        showScheduledAt: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            'Error al cargar operaciones: $err',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
    );
  }
}

class _OperationsItemsList extends ConsumerWidget {
  final List<CrmOperationsItem> items;
  final String emptyLabel;
  final bool showScheduledAt;

  const _OperationsItemsList({
    required this.items,
    required this.emptyLabel,
    required this.showScheduledAt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return Center(child: Text(emptyLabel));
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        final threadAsync = ref.watch(_crmThreadByIdProvider(item.chatId));

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: threadAsync.when(
                        data: (thread) {
                          final name = (thread.displayName ?? '').trim();
                          final phone = (thread.phone ?? '').trim();
                          final title = name.isNotEmpty
                              ? name
                              : (phone.isNotEmpty ? phone : 'Chat');

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                [
                                  if (phone.isNotEmpty && phone != title) phone,
                                  thread.status,
                                ].join(' • '),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ],
                          );
                        },
                        loading: () => const Text('Cargando...'),
                        error: (_, __) => Text(
                          'Chat ${item.chatId}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: () =>
                          context.go('${AppRoutes.crm}/chats/${item.chatId}'),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Abrir chat'),
                    ),
                  ],
                ),
                if (showScheduledAt && item.scheduledAt != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm')
                            .format(item.scheduledAt!.toLocal()),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
                if ((item.note ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    item.note!.trim(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

