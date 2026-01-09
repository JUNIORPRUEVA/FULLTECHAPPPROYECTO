import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../state/crm_providers.dart';
import '../../state/customers_state.dart';
import '../../state/customers_controller.dart';

class CrmCustomersPageEnhanced extends ConsumerStatefulWidget {
  const CrmCustomersPageEnhanced({super.key});

  @override
  ConsumerState<CrmCustomersPageEnhanced> createState() =>
      _CrmCustomersPageEnhancedState();
}

class _CrmCustomersPageEnhancedState
    extends ConsumerState<CrmCustomersPageEnhanced> {
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
    final productsAsync = ref.watch(crmProductsProvider);

    final isDesktop = MediaQuery.of(context).size.width >= 1100;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 320,
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Buscar…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            tooltip: 'Limpiar',
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              notifier.setSearch('');
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: notifier.setSearch,
                ),
              ),
              productsAsync.when(
                data: (products) {
                  final active = products.where((p) => p.isActive).toList();
                  return SizedBox(
                    width: 240,
                    child: DropdownButtonFormField<String?>(
                      initialValue: state.productId,
                      decoration: const InputDecoration(
                        labelText: 'Producto',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Todos'),
                        ),
                        ...active.map(
                          (p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(
                              p.nombre,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: notifier.setProductId,
                    ),
                  );
                },
                loading: () => const SizedBox(
                  width: 240,
                  height: 48,
                  child: LinearProgressIndicator(),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
              SizedBox(
                width: 160,
                child: DropdownButtonFormField<String?>(
                  initialValue: state.status,
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Todos')),
                    DropdownMenuItem(value: 'activo', child: Text('Activo')),
                    DropdownMenuItem(
                      value: 'interesado',
                      child: Text('Interesado'),
                    ),
                    DropdownMenuItem(
                      value: 'inactivo',
                      child: Text('Inactivo'),
                    ),
                  ],
                  onChanged: notifier.setStatus,
                ),
              ),
              FilledButton.tonal(
                onPressed: notifier.refresh,
                child: const Text('Reintentar'),
              ),
              IconButton(
                tooltip: 'Limpiar filtros',
                onPressed: () {
                  _searchCtrl.clear();
                  notifier.clearFilters();
                  notifier.refresh();
                },
                icon: const Icon(Icons.filter_alt_off),
              ),
            ],
          ),
        ),
        Expanded(
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _CustomersList(state: state, notifier: notifier),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(width: 380, child: _GlobalStatsAndTrackingPanel()),
                  ],
                )
              : _CustomersList(state: state, notifier: notifier),
        ),
      ],
    );
  }
}

class _CustomersList extends StatelessWidget {
  final CustomersState state;
  final CustomersController notifier;

  const _CustomersList({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    if (state.loading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.items.isEmpty) {
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
        final isSelected = state.selectedCustomerId == c.id;
        final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

        return ListTile(
          selected: isSelected,
          leading: CircleAvatar(
            child: Text(
              c.displayName.isNotEmpty ? c.displayName[0].toUpperCase() : '?',
            ),
          ),
          title: Text(c.displayName),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.phone),
              if (c.lastPurchaseAt != null)
                Text(
                  'Última compra: ${_formatDate(c.lastPurchaseAt!)}',
                  style: const TextStyle(fontSize: 11),
                ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                fmt.format(c.totalSpent),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${c.totalPurchases} compra${c.totalPurchases != 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
          onTap: () => notifier.selectCustomer(c.id),
        );
      },
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('dd/MM/yy').format(dt);
    } catch (_) {
      return iso;
    }
  }
}

// ============= NUEVO PANEL MEJORADO =============

// Panel global con estadísticas y seguimiento
class _GlobalStatsAndTrackingPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(customersControllerProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        // 1. Card de seguimiento del cliente seleccionado (si hay uno)
        if (state.selectedCustomerId != null) ...[
          _CustomerTrackingCard(
            customerId: state.selectedCustomerId!,
            detail: state.selectedDetail,
            loading: state.loadingDetail,
          ),
          const SizedBox(height: 12),
        ],

        // 2. Estadísticas globales
        Expanded(
          child: Card(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.analytics, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Resumen Global',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Contenido
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Total clientes
                        _StatCard(
                          icon: Icons.people,
                          title: 'Total Clientes',
                          value: '${state.items.length}',
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 12),

                        // Total compras
                        _StatCard(
                          icon: Icons.shopping_bag,
                          title: 'Total Compras',
                          value: '${_getTotalPurchases(state.items)}',
                          color: Colors.orange,
                        ),
                        const SizedBox(height: 12),

                        // Total ingresos
                        _StatCard(
                          icon: Icons.attach_money,
                          title: 'Total Ingresos',
                          value:
                              '\$${_getTotalSpent(state.items).toStringAsFixed(2)}',
                          color: Colors.purple,
                        ),

                        const Divider(height: 32),

                        // Productos más comprados
                        Text(
                          'Productos Más Comprados',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._getTopProducts(state.items).map(
                          (product) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 16,
                                child: Text(
                                  product.count.toString(),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              title: Text(
                                product.name,
                                style: const TextStyle(fontSize: 13),
                              ),
                              subtitle: Text(
                                '${product.count} compra${product.count != 1 ? 's' : ''}',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          ),
                        ),

                        if (_getTopProducts(state.items).isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'No hay datos de productos',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Top clientes
                        Text(
                          'Top Clientes',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._getTopCustomers(state.items, ref).map(
                          (c) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 16,
                                child: Text(
                                  c.displayName.isNotEmpty
                                      ? c.displayName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              title: Text(
                                c.displayName,
                                style: const TextStyle(fontSize: 13),
                              ),
                              subtitle: Text(
                                '\$${c.totalSpent.toStringAsFixed(2)} • ${c.totalPurchases} compras',
                                style: const TextStyle(fontSize: 11),
                              ),
                              trailing: Icon(
                                Icons.star,
                                size: 16,
                                color: Colors.amber[700],
                              ),
                              onTap: () => ref
                                  .read(customersControllerProvider.notifier)
                                  .selectCustomer(c.id),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  int _getTotalPurchases(List<dynamic> customers) {
    return customers.fold<int>(
      0,
      (sum, c) => sum + (c.totalPurchases as int? ?? 0),
    );
  }

  double _getTotalSpent(List<dynamic> customers) {
    return customers.fold<double>(
      0.0,
      (sum, c) => sum + (c.totalSpent as double? ?? 0.0),
    );
  }

  List<_ProductStat> _getTopProducts(List<dynamic> customers) {
    final Map<String, int> productCounts = {};
    for (var customer in customers) {
      final topProduct = customer.topProduct as String?;
      if (topProduct != null && topProduct.isNotEmpty) {
        productCounts[topProduct] = (productCounts[topProduct] ?? 0) + 1;
      }
    }
    final list =
        productCounts.entries
            .map((e) => _ProductStat(name: e.key, count: e.value))
            .toList()
          ..sort((a, b) => b.count.compareTo(a.count));
    return list.take(5).toList();
  }

  List<dynamic> _getTopCustomers(List<dynamic> customers, WidgetRef ref) {
    final sorted = customers.toList()
      ..sort(
        (a, b) => (b.totalSpent as double? ?? 0.0).compareTo(
          a.totalSpent as double? ?? 0.0,
        ),
      );
    return sorted.take(5).toList();
  }
}

class _ProductStat {
  final String name;
  final int count;
  _ProductStat({required this.name, required this.count});
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Card de seguimiento del cliente seleccionado
class _CustomerTrackingCard extends ConsumerStatefulWidget {
  final String customerId;
  final dynamic detail;
  final bool loading;

  const _CustomerTrackingCard({
    required this.customerId,
    required this.detail,
    required this.loading,
  });

  @override
  ConsumerState<_CustomerTrackingCard> createState() =>
      _CustomerTrackingCardState();
}

class _CustomerTrackingCardState extends ConsumerState<_CustomerTrackingCard> {
  final _noteCtrl = TextEditingController();
  bool _addingNote = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifier = ref.read(customersControllerProvider.notifier);

    if (widget.loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final detail = widget.detail;
    if (detail == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('No disponible')),
        ),
      );
    }

    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  child: Text(
                    detail.displayName.isNotEmpty
                        ? detail.displayName[0].toUpperCase()
                        : '?',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detail.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(detail.phone, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => notifier.selectCustomer(null),
                ),
              ],
            ),
          ),

          // Acciones
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.chat, size: 16),
                    label: const Text('Chat', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showEditDialog(context, detail),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Editar', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _showDeleteDialog(context),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  child: const Icon(Icons.delete, size: 16),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Seguimiento
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Seguimiento',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _addingNote = !_addingNote),
                      icon: Icon(
                        _addingNote ? Icons.close : Icons.add,
                        size: 16,
                      ),
                      label: Text(
                        _addingNote ? 'Cancelar' : 'Agregar nota',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),

                if (_addingNote) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Escribe una nota...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () async {
                      if (_noteCtrl.text.trim().isEmpty) return;
                      await notifier.addNote(text: _noteCtrl.text.trim());
                      _noteCtrl.clear();
                      setState(() => _addingNote = false);
                    },
                    child: const Text('Guardar'),
                  ),
                ],

                const SizedBox(height: 12),

                // Notas
                if (detail.notes != null && detail.notes.isNotEmpty)
                  ...detail.notes
                      .take(3)
                      .map<Widget>(
                        (note) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  note.text,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  note.createdAt,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                else
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No hay notas',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, dynamic detail) {
    final nameCtrl = TextEditingController(text: detail.displayName);
    final phoneCtrl = TextEditingController(text: detail.phone);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Cliente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              await ref
                  .read(customersControllerProvider.notifier)
                  .updateCustomer({
                    'nombre': nameCtrl.text.trim(),
                    'telefono': phoneCtrl.text.trim(),
                  });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Cliente'),
        content: const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Función de eliminación pendiente'),
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
