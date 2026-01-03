import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../state/crm_providers.dart';

class CrmCustomersPage extends ConsumerStatefulWidget {
  const CrmCustomersPage({super.key});

  @override
  ConsumerState<CrmCustomersPage> createState() => _CrmCustomersPageState();
}

class _CrmCustomersPageState extends ConsumerState<CrmCustomersPage> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(customersControllerProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customersControllerProvider);
    final notifier = ref.read(customersControllerProvider.notifier);

    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Buscar cliente',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) {
                      notifier.setSearch(v);
                      notifier.refresh();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  tooltip: 'Refrescar',
                  onPressed: () => notifier.refresh(),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Builder(
              builder: (context) {
                if (state.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.error != null) {
                  return Center(child: Text(state.error!));
                }
                if (state.items.isEmpty) {
                  return const Center(child: Text('Sin clientes'));
                }

                return ListView.separated(
                  itemCount: state.items.length + 1,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    if (index == state.items.length) {
                      final canLoadMore = state.items.length < state.total;
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

                    final c = state.items[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(c.nombre.isNotEmpty ? c.nombre[0].toUpperCase() : '?'),
                      ),
                      title: Text(c.nombre),
                      subtitle: Text(c.telefono),
                      onTap: () => context.go('${AppRoutes.crm}/customers/${c.id}'),
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
