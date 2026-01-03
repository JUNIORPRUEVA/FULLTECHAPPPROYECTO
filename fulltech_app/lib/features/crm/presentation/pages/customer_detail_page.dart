import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/module_page.dart';
import '../../state/crm_providers.dart';

class CustomerDetailPage extends ConsumerStatefulWidget {
  final String customerId;

  const CustomerDetailPage({super.key, required this.customerId});

  @override
  ConsumerState<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends ConsumerState<CustomerDetailPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(customerDetailControllerProvider(widget.customerId).notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerDetailControllerProvider(widget.customerId));

    return ModulePage(
      title: 'Cliente',
      actions: [
        IconButton(
          tooltip: 'Volver',
          onPressed: () => context.go(AppRoutes.crm),
          icon: const Icon(Icons.arrow_back),
        ),
      ],
      child: Builder(
        builder: (context) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error != null) {
            return Center(child: Text(state.error!));
          }
          final c = state.customer;
          if (c == null) {
            return const Center(child: Text('No encontrado'));
          }

          return Row(
            children: [
              Expanded(
                flex: 2,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: ListView(
                      children: [
                        Text(
                          c.nombre,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text('Teléfono: ${c.telefono}'),
                        Text('Email: ${_na(c.email)}'),
                        Text('Dirección: ${_na(c.direccion)}'),
                        Text('Origen: ${c.origen}'),
                        Text('Tags: ${c.tags.isEmpty ? 'N/A' : c.tags.join(', ')}'),
                        const SizedBox(height: 10),
                        Text('Notas: ${_na(c.notas)}'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Card(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Chats relacionados',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Refrescar',
                              onPressed: () => ref
                                  .read(customerDetailControllerProvider(widget.customerId).notifier)
                                  .load(),
                              icon: const Icon(Icons.refresh),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: state.threads.isEmpty
                            ? const Center(child: Text('Sin chats'))
                            : ListView.separated(
                                itemCount: state.threads.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, i) {
                                  final t = state.threads[i];
                                  final title = (t.displayName != null && t.displayName!.trim().isNotEmpty)
                                      ? t.displayName!.trim()
                                      : (t.phone ?? t.waId);

                                  return ListTile(
                                    title: Text(title),
                                    subtitle: Text(t.lastMessagePreview ?? ''),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () => context.go('${AppRoutes.crm}/chats/${t.id}'),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _na(String? v) => (v == null || v.trim().isEmpty) ? 'N/A' : v.trim();
}
