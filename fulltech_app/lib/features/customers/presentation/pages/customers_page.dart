import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fulltech_app/core/widgets/module_page.dart';
import 'package:fulltech_app/core/widgets/compact_error_widget.dart';
import 'package:go_router/go_router.dart';

import 'package:fulltech_app/core/routing/app_routes.dart';
import 'package:fulltech_app/features/customers/presentation/widgets/customers_filter_bar.dart';
import 'package:fulltech_app/features/customers/presentation/widgets/customers_list.dart';
import 'package:fulltech_app/features/customers/presentation/widgets/customers_stats_panel.dart';
import 'package:fulltech_app/features/customers/providers/customers_provider.dart';
import 'package:fulltech_app/features/customers/data/models/customer_response.dart';

class CustomersPage extends ConsumerStatefulWidget {
  final bool onlyActiveCustomers;

  const CustomersPage({super.key, this.onlyActiveCustomers = false});

  @override
  ConsumerState<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends ConsumerState<CustomersPage> {
  String? _selectedCustomerId;

  @override
  void initState() {
    super.initState();
    // Load customers on init
    Future.microtask(() {
      ref.read(customersControllerProvider.notifier).loadCustomers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customersControllerProvider);
    final customers = widget.onlyActiveCustomers
      ? state.customers.where(_isActiveCustomer).toList()
      : state.customers;

    final isDesktop = MediaQuery.of(context).size.width >= 1100;

    return ModulePage(
      title: widget.onlyActiveCustomers ? 'Clientes Activos' : 'Clientes',
      child: Column(
        children: [
          // Stats Panel at top
          CustomersStatsPanel(stats: state.stats),

          // Filter Bar
          const CustomersFilterBar(),

          // Main Content
          Expanded(
            child: Row(
              children: [
                // Customer List (left side)
                Expanded(
                  flex: 1,
                  child: CustomersList(
                    customers: customers,
                    isLoading: state.isLoading,
                    error: state.error,
                    selectedCustomerId: _selectedCustomerId,
                    onCustomerSelected: (id) {
                      setState(() {
                        _selectedCustomerId = id;
                      });
                    },
                    onRefresh: () {
                      ref
                          .read(customersControllerProvider.notifier)
                          .loadCustomers();
                    },
                    emptyTitle: widget.onlyActiveCustomers
                        ? 'No hay clientes activos'
                        : 'No hay clientes',
                    emptySubtitle: widget.onlyActiveCustomers
                        ? "Solo se muestran clientes marcados como activos (por ejemplo tag/estado 'compro')."
                        : 'Intenta cambiar los filtros',
                  ),
                ),

                // Customer Detail Panel (right side)
                if (_selectedCustomerId != null)
                  Expanded(
                    flex: 1,
                    child: _buildDetailPanel(_selectedCustomerId!),
                  ),

                if (isDesktop) ...[
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 380,
                    child: _CustomersTrackingPanel(
                      customers: customers,
                      selectedCustomerId: _selectedCustomerId,
                      onSelectCustomer: (id) {
                        setState(() {
                          _selectedCustomerId = id;
                        });
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isActiveCustomer(CustomerItem c) {
    // En este módulo, "cliente activo" intenta representar "ya compró".
    // Hoy el backend expone:
    // - status/tags (ej. 'compro')
    // - isActiveCustomer (actualmente true para tags 'compro' o 'activo')
    // - totalPurchasesCount (placeholder 0)
    // Usamos 'compro' y compras>0 como señal fuerte; y como fallback, isActiveCustomer.
    final status = (c.status).toLowerCase().trim();
    final tagsLower = c.tags.map((t) => t.toLowerCase().trim()).toList();
    final hasPurchases = c.totalPurchasesCount > 0;
    final isBought = status == 'compro' || tagsLower.contains('compro');
    return isBought || hasPurchases || c.isActiveCustomer;
  }

  Widget _buildDetailPanel(String customerId) {
    final detailAsync = ref.watch(customerDetailProvider(customerId));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Colors.grey[300]!)),
      ),
      child: detailAsync.when(
        data: (detail) {
          final customer = detail.customer;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with close button
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        customer.fullName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _selectedCustomerId = null;
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Profile Info
                _buildInfoCard('Información de Contacto', [
                  _buildInfoRow('Teléfono', customer.phone),
                  if (customer.whatsappId != null)
                    _buildInfoRow('WhatsApp ID', customer.whatsappId!),
                  if (customer.email != null)
                    _buildInfoRow('Email', customer.email!),
                  if (customer.address != null)
                    _buildInfoRow('Dirección', customer.address!),
                ]),

                const SizedBox(height: 16),

                // Status & Tags
                _buildInfoCard('Estado y Etiquetas', [
                  _buildInfoRow('Estado', customer.status),
                  if (customer.tags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: customer.tags
                            .map(
                              (tag) => Chip(
                                label: Text(tag),
                                backgroundColor: Colors.blue[100],
                              ),
                            )
                            .toList(),
                      ),
                    ),
                ]),

                const SizedBox(height: 16),

                // Purchase Summary
                _buildInfoCard('Resumen de Compras', [
                  _buildInfoRow(
                    'Total Compras',
                    '${detail.stats.totalPurchases} compras',
                  ),
                  _buildInfoRow(
                    'Monto Total',
                    '\$${detail.stats.totalSpent.toStringAsFixed(2)}',
                  ),
                  if (detail.stats.lastPurchaseAt != null)
                    _buildInfoRow(
                      'Última Compra',
                      detail.stats.lastPurchaseAt!,
                    ),
                ]),

                const SizedBox(height: 16),

                // Last Product
                if (customer.assignedProduct != null)
                  _buildInfoCard('Producto Asignado', [
                    Row(
                      children: [
                        if (customer.assignedProduct!.imageUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              customer.assignedProduct!.imageUrl!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported),
                              ),
                            ),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customer.assignedProduct!.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '\$${customer.assignedProduct!.price.toStringAsFixed(2)}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ]),

                const SizedBox(height: 16),

                // Purchases Section
                if (detail.purchases.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Historial de Compras',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...detail.purchases.map(
                        (purchase) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              purchase.product?.name ?? 'Producto Desconocido',
                            ),
                            subtitle: Text(
                              '${purchase.date} | Cant: ${purchase.quantity}',
                            ),
                            trailing: Text(
                              '\$${purchase.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 16),

                // Chats Section
                if (detail.chats.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Conversaciones',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...detail.chats.map(
                        (chat) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.chat),
                            title: Text(chat.displayName ?? 'Chat'),
                            subtitle: chat.lastMessagePreview != null
                                ? Text(chat.lastMessagePreview!)
                                : const Text('Sin mensajes'),
                            trailing: chat.unreadCount > 0
                                ? CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.red,
                                    child: Text(
                                      '${chat.unreadCount}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 16),

                // Notes
                if (customer.internalNote != null &&
                    customer.internalNote!.isNotEmpty)
                  _buildInfoCard('Notas', [Text(customer.internalNote!)]),

                const SizedBox(height: 16),

                // Audit Info
                _buildInfoCard('Información de Auditoría', [
                  _buildInfoRow('Creado', customer.createdAt),
                  _buildInfoRow('Actualizado', customer.updatedAt),
                ]),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.go(AppRoutes.crm);
                        },
                        icon: const Icon(Icons.chat),
                        label: const Text('Ir a Chats'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _confirmDelete(customer.id, customer.fullName);
                        },
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text(
                          'Eliminar',
                          style: TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => CompactErrorWidget(
          error: error.toString(),
          onRetry: () => ref.invalidate(customerDetailProvider(customerId)),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro de eliminar al cliente "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(customersControllerProvider.notifier)
                  .deleteCustomer(id);
              setState(() {
                _selectedCustomerId = null;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _CustomersTrackingPanel extends ConsumerWidget {
  final List<CustomerItem> customers;
  final String? selectedCustomerId;
  final ValueChanged<String?> onSelectCustomer;

  const _CustomersTrackingPanel({
    required this.customers,
    required this.selectedCustomerId,
    required this.onSelectCustomer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final total = customers.length;
    final totalSpent = customers.fold<double>(
      0,
      (sum, c) => sum + c.totalSpent,
    );
    final totalPurchases = customers.fold<int>(
      0,
      (sum, c) => sum + c.totalPurchasesCount,
    );

    final top = customers.toList()
      ..sort((a, b) => b.totalSpent.compareTo(a.totalSpent));

    return Column(
      children: [
        if (selectedCustomerId != null) ...[
          _SelectedCustomerTrackingCard(customerId: selectedCustomerId!),
          const SizedBox(height: 12),
        ],
        Expanded(
          child: Card(
            child: Column(
              children: [
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
                      Icon(Icons.track_changes, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Seguimiento',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _MiniStat(
                          icon: Icons.people,
                          title: 'Clientes en lista',
                          value: '$total',
                        ),
                        const SizedBox(height: 10),
                        _MiniStat(
                          icon: Icons.shopping_bag,
                          title: 'Compras (conteo)',
                          value: '$totalPurchases',
                        ),
                        const SizedBox(height: 10),
                        _MiniStat(
                          icon: Icons.attach_money,
                          title: 'Ingresos (estimado)',
                          value: '\$${totalSpent.toStringAsFixed(2)}',
                        ),
                        const Divider(height: 28),
                        Text(
                          'Top Clientes',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...top.take(8).map(
                          (c) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 16,
                                child: Text(
                                  c.fullName.isNotEmpty
                                      ? c.fullName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              title: Text(
                                c.fullName,
                                style: const TextStyle(fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '\$${c.totalSpent.toStringAsFixed(2)} • ${c.totalPurchasesCount} compras',
                                style: const TextStyle(fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: selectedCustomerId == c.id
                                  ? const Icon(Icons.check, size: 16)
                                  : null,
                              onTap: () => onSelectCustomer(c.id),
                            ),
                          ),
                        ),
                        if (customers.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'No hay datos para seguimiento.',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
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
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _MiniStat({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _SelectedCustomerTrackingCard extends ConsumerStatefulWidget {
  final String customerId;

  const _SelectedCustomerTrackingCard({required this.customerId});

  @override
  ConsumerState<_SelectedCustomerTrackingCard> createState() =>
      _SelectedCustomerTrackingCardState();
}

class _SelectedCustomerTrackingCardState
    extends ConsumerState<_SelectedCustomerTrackingCard> {
  final _noteCtrl = TextEditingController();
  bool _saving = false;
  String? _lastLoadedNote;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detailAsync = ref.watch(customerDetailProvider(widget.customerId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: detailAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: ${e.toString()}'),
          data: (detail) {
            final c = detail.customer;
            final incoming = c.internalNote ?? '';
            if (_lastLoadedNote != incoming) {
              _lastLoadedNote = incoming;
              _noteCtrl.text = incoming;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      child: Text(
                        c.fullName.isNotEmpty
                            ? c.fullName[0].toUpperCase()
                            : '?',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.fullName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            c.phone,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Abrir CRM',
                      onPressed: () => context.go(AppRoutes.crm),
                      icon: const Icon(Icons.open_in_new, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Nota de seguimiento',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Escribe una nota para dar seguimiento…',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: _saving
                      ? null
                      : () async {
                          setState(() => _saving = true);
                          try {
                            await ref
                                .read(customersRepositoryProvider)
                                .patchCustomer(widget.customerId, {
                              'notas': _noteCtrl.text.trim(),
                            });
                            ref.invalidate(
                              customerDetailProvider(widget.customerId),
                            );
                            ref
                                .read(customersControllerProvider.notifier)
                                .loadCustomers();
                          } finally {
                            if (mounted) setState(() => _saving = false);
                          }
                        },
                  icon: const Icon(Icons.save, size: 18),
                  label: Text(_saving ? 'Guardando…' : 'Guardar'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
