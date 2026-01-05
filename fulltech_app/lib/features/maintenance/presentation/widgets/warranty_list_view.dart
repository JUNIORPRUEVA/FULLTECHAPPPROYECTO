import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/app_config.dart';
import '../../providers/maintenance_provider.dart';
import '../../data/models/maintenance_models.dart';

String _publicUrlFromMaybeRelative(String raw) {
  final v = raw.trim();
  if (v.isEmpty) return '';
  if (v.startsWith('http://') || v.startsWith('https://')) return v;

  final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/api$'), '');
  if (v.startsWith('/')) return '$base$v';
  return '$base/$v';
}

class WarrantyListView extends ConsumerStatefulWidget {
  const WarrantyListView({super.key});

  @override
  ConsumerState<WarrantyListView> createState() => _WarrantyListViewState();
}

class _WarrantyListViewState extends ConsumerState<WarrantyListView> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      ref.read(warrantyControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(warrantyControllerProvider);
    final controller = ref.read(warrantyControllerProvider.notifier);
    final productsAsync = ref.watch(maintenanceProductsProvider);

    return Column(
      children: [
        // Filters
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade50,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 750;

              final searchField = TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar por ticket o producto...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            controller.setSearch(null);
                          },
                        )
                      : null,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: controller.setSearch,
              );

              final productDropdown = productsAsync.when<Widget>(
                data: (items) {
                  return DropdownButtonFormField<String?>(
                    value: controller.productoIdFilter,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Producto',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todos'),
                      ),
                      ...items.map(
                        (p) => DropdownMenuItem<String?>(
                          value: p.id,
                          child: Row(
                            children: [
                              if (p.imagenUrl.trim().isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    _publicUrlFromMaybeRelative(p.imagenUrl),
                                    width: 28,
                                    height: 28,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox(
                                          width: 28,
                                          height: 28,
                                          child: Icon(
                                            Icons.inventory_2,
                                            size: 18,
                                          ),
                                        ),
                                  ),
                                )
                              else
                                const SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: Icon(Icons.inventory_2, size: 18),
                                ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  p.nombre,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'RD\$${p.precioVenta.toStringAsFixed(2)}',
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    onChanged: controller.setProductoFilter,
                  );
                },
                error: (_, __) {
                  return DropdownButtonFormField<String?>(
                    value: controller.productoIdFilter,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Producto',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todos'),
                      ),
                    ],
                    onChanged: controller.setProductoFilter,
                  );
                },
                loading: () => const SizedBox(
                  height: 44,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );

              final statusDropdown = DropdownButton<WarrantyStatus?>(
                value: controller.statusFilter,
                hint: const Text('Estado'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todos')),
                  ...WarrantyStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(_getStatusLabel(status)),
                    );
                  }),
                ],
                onChanged: controller.setStatusFilter,
              );

              final clearButton = IconButton(
                icon: const Icon(Icons.filter_alt_off),
                tooltip: 'Limpiar filtros',
                onPressed: () {
                  _searchController.clear();
                  controller.clearFilters();
                },
              );

              if (isNarrow) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: searchField),
                        const SizedBox(width: 8),
                        clearButton,
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: productDropdown),
                        const SizedBox(width: 12),
                        statusDropdown,
                      ],
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: searchField),
                  const SizedBox(width: 12),
                  SizedBox(width: 340, child: productDropdown),
                  const SizedBox(width: 12),
                  statusDropdown,
                  const SizedBox(width: 12),
                  clearButton,
                ],
              );
            },
          ),
        ),

        // List
        Expanded(
          child: state.error != null
              ? _buildError(state.error!)
              : state.items.isEmpty && !state.isLoading
              ? _buildEmpty()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: state.items.length + (state.isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= state.items.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    return _buildWarrantyCard(state.items[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildWarrantyCard(WarrantyCase warranty) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // TODO: Show detail dialog
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Product image
              if (warranty.producto?.imagenUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _publicUrlFromMaybeRelative(warranty.producto!.imagenUrl!),
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                  ),
                )
              else
                _buildPlaceholderImage(),

              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            warranty.producto?.nombre ??
                                'Producto #${warranty.productoId}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        _buildStatusBadge(warranty.warrantyStatus),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (warranty.supplierName != null)
                      Text(
                        'Proveedor: ${warranty.supplierName}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    if (warranty.supplierTicket != null)
                      Text(
                        'Ticket: ${warranty.supplierTicket}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          warranty.sentDate != null
                              ? 'Enviado: ${DateFormat('dd/MM/yyyy').format(warranty.sentDate!)}'
                              : 'Creado: ${DateFormat('dd/MM/yyyy').format(warranty.createdAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (warranty.receivedDate != null) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.download_done,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Recibido: ${DateFormat('dd/MM/yyyy').format(warranty.receivedDate!)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.verified_user, color: Colors.grey),
    );
  }

  Widget _buildStatusBadge(WarrantyStatus status) {
    final data = _getStatusInfo(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: data.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: data.color),
      ),
      child: Text(
        data.label,
        style: TextStyle(
          color: data.color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Error al cargar garantías',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              ref
                  .read(warrantyControllerProvider.notifier)
                  .loadWarranty(reset: true);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No hay garantías',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea un nuevo caso de garantía',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(WarrantyStatus status) {
    switch (status) {
      case WarrantyStatus.abierto:
        return 'Abierto';
      case WarrantyStatus.enviado:
        return 'Enviado';
      case WarrantyStatus.enProceso:
        return 'En Proceso';
      case WarrantyStatus.aprobado:
        return 'Aprobado';
      case WarrantyStatus.rechazado:
        return 'Rechazado';
      case WarrantyStatus.cerrado:
        return 'Cerrado';
    }
  }

  ({Color color, String label}) _getStatusInfo(WarrantyStatus status) {
    switch (status) {
      case WarrantyStatus.abierto:
        return (color: Colors.blue, label: 'Abierto');
      case WarrantyStatus.enviado:
        return (color: Colors.orange, label: 'Enviado');
      case WarrantyStatus.enProceso:
        return (color: Colors.amber, label: 'En Proceso');
      case WarrantyStatus.aprobado:
        return (color: Colors.green, label: 'Aprobado');
      case WarrantyStatus.rechazado:
        return (color: Colors.red, label: 'Rechazado');
      case WarrantyStatus.cerrado:
        return (color: Colors.grey, label: 'Cerrado');
    }
  }
}
