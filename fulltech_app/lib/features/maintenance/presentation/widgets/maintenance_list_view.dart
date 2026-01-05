import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../dialogs/edit_maintenance_dialog.dart';
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

class MaintenanceListView extends ConsumerStatefulWidget {
  const MaintenanceListView({super.key});

  @override
  ConsumerState<MaintenanceListView> createState() =>
      _MaintenanceListViewState();
}

class _MaintenanceListViewState extends ConsumerState<MaintenanceListView> {
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
      ref.read(maintenanceControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(maintenanceControllerProvider);
    final controller = ref.read(maintenanceControllerProvider.notifier);
    final productsAsync = ref.watch(maintenanceProductsProvider);

    final products = productsAsync.asData?.value;
    final productNameById = <String, String>{
      for (final p in (products ?? const [])) p.id: p.nombre,
    };
    final productImageById = <String, String>{
      for (final p in (products ?? const [])) p.id: p.imagenUrl,
    };

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
                  hintText: 'Buscar por descripción o producto...',
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

              final statusDropdown = DropdownButton<ProductHealthStatus?>(
                value: controller.statusFilter,
                hint: const Text('Estado'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todos')),
                  ...ProductHealthStatus.values.map((status) {
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
                    return Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 860),
                        child: _buildMaintenanceCard(
                          state.items[index],
                          fallbackProductName:
                              productNameById[state.items[index].productoId],
                          fallbackImageUrl:
                              productImageById[state.items[index].productoId],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMaintenanceCard(
    MaintenanceRecord record, {
    String? fallbackProductName,
    String? fallbackImageUrl,
  }) {
    final recordImageUrl = record.producto?.imagenUrl?.trim() ?? '';
    final recordProductName = record.producto?.nombre.trim() ?? '';

    final imageUrl = recordImageUrl.isNotEmpty
        ? recordImageUrl
        : (fallbackImageUrl?.trim() ?? '');
    final productName = recordProductName.isNotEmpty
        ? recordProductName
        : ((fallbackProductName ?? '').trim().isNotEmpty
              ? fallbackProductName!.trim()
              : 'Producto #${record.productoId}');
    final controller = ref.read(maintenanceControllerProvider.notifier);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          _openDetail(record);
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Product image
              if (imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _publicUrlFromMaybeRelative(imageUrl),
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
                    Text(
                      productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatusBadge(record.statusAfter),
                        const SizedBox(width: 8),
                        Text(
                          _getMaintenanceTypeLabel(record.maintenanceType),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          DateFormat('dd/MM/yyyy').format(record.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Editar',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () async {
                      await showDialog<void>(
                        context: context,
                        builder: (_) => EditMaintenanceDialog(record: record),
                      );
                    },
                  ),
                  IconButton(
                    tooltip: 'Eliminar',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Eliminar mantenimiento'),
                            content: const Text(
                              '¿Seguro que deseas eliminar este mantenimiento?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancelar'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('Eliminar'),
                              ),
                            ],
                          );
                        },
                      );

                      if (ok != true) return;

                      try {
                        await controller.deleteMaintenance(record.id);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Eliminado')),
                        );
                      } catch (_) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No se pudo eliminar')),
                        );
                      }
                    },
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openDetail(MaintenanceRecord record) async {
    final recordImageUrl = record.producto?.imagenUrl?.trim() ?? '';
    final recordProductName = record.producto?.nombre.trim() ?? '';

    // Fallback: product list (filters) usually has image/name.
    final products = ref.read(maintenanceProductsProvider).asData?.value;
    String fallbackImageUrl = '';
    String fallbackProductName = '';
    if (products != null) {
      for (final p in products) {
        if (p.id == record.productoId) {
          fallbackImageUrl = (p.imagenUrl ?? '').trim();
          fallbackProductName = (p.nombre ?? '').trim();
          break;
        }
      }
    }

    final imageUrl = recordImageUrl.isNotEmpty
        ? recordImageUrl
        : fallbackImageUrl;
    final productName = recordProductName.isNotEmpty
        ? recordProductName
        : (fallbackProductName.isNotEmpty
              ? fallbackProductName
              : 'Producto #${record.productoId}');

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Detalle de mantenimiento'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                _publicUrlFromMaybeRelative(imageUrl),
                                width: 128,
                                height: 128,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildPlaceholderImageLarge(),
                              )
                            : _buildPlaceholderImageLarge(),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record.producto?.nombre ??
                                  'Producto #${record.productoId}',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildStatusBadge(record.statusAfter),
                                _chip(
                                  _getMaintenanceTypeLabel(
                                    record.maintenanceType,
                                  ),
                                ),
                                if (record.issueCategory != null)
                                  _chip(
                                    _issueCategoryLabel(record.issueCategory!),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _detailRow(
                    'Fecha',
                    DateFormat('dd/MM/yyyy').format(record.createdAt),
                  ),
                  _detailRow('ID', record.id),
                  _detailRow('Producto ID', record.productoId),
                  if (record.createdBy != null) ...[
                    _detailRow('Usuario', record.createdBy!.nombreCompleto),
                    if ((record.createdBy!.email ?? '').trim().isNotEmpty)
                      _detailRow('Email', record.createdBy!.email!.trim()),
                  ] else ...[
                    _detailRow('Usuario ID', record.createdByUserId),
                  ],
                  if (record.statusBefore != null)
                    _detailRow(
                      'Estado antes',
                      _getStatusLabel(record.statusBefore!),
                    ),
                  _detailRow(
                    'Estado después',
                    _getStatusLabel(record.statusAfter),
                  ),
                  if (record.cost != null)
                    _detailRow(
                      'Costo',
                      'RD\$${record.cost!.toStringAsFixed(2)}',
                    ),
                  const SizedBox(height: 12),
                  Text(
                    'Descripción',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    record.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if ((record.internalNotes ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Notas internas',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      record.internalNotes!.trim(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  if (record.attachmentUrls.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Adjuntos',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (final a in record.attachmentUrls)
                      Text(
                        a,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }

  String _issueCategoryLabel(IssueCategory c) {
    switch (c) {
      case IssueCategory.electrico:
        return 'Eléctrico';
      case IssueCategory.pantalla:
        return 'Pantalla';
      case IssueCategory.bateria:
        return 'Batería';
      case IssueCategory.accesorios:
        return 'Accesorios';
      case IssueCategory.software:
        return 'Software';
      case IssueCategory.fisico:
        return 'Físico';
      case IssueCategory.otro:
        return 'Otro';
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.inventory_2, color: Colors.grey),
    );
  }

  Widget _buildPlaceholderImageLarge() {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.inventory_2, color: Colors.grey, size: 32),
    );
  }

  Widget _buildStatusBadge(ProductHealthStatus status) {
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
            'Error al cargar mantenimientos',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              ref
                  .read(maintenanceControllerProvider.notifier)
                  .loadMaintenance(reset: true);
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
          Icon(
            Icons.build_circle_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay mantenimientos',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea un nuevo registro de mantenimiento',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(ProductHealthStatus status) {
    switch (status) {
      case ProductHealthStatus.okVerificado:
        return 'OK';
      case ProductHealthStatus.conProblema:
        return 'Con Problema';
      case ProductHealthStatus.enGarantia:
        return 'En Garantía';
      case ProductHealthStatus.perdido:
        return 'Perdido';
      case ProductHealthStatus.danadoSinGarantia:
        return 'Dañado';
      case ProductHealthStatus.reparado:
        return 'Reparado';
      case ProductHealthStatus.enRevision:
        return 'En Revisión';
    }
  }

  String _getMaintenanceTypeLabel(MaintenanceType type) {
    switch (type) {
      case MaintenanceType.verificacion:
        return 'Verificación';
      case MaintenanceType.diagnostico:
        return 'Diagnóstico';
      case MaintenanceType.reparacion:
        return 'Reparación';
      case MaintenanceType.limpieza:
        return 'Limpieza';
      case MaintenanceType.garantia:
        return 'Garantía';
      case MaintenanceType.ajusteInventario:
        return 'Ajuste Inventario';
      case MaintenanceType.otro:
        return 'Otro';
    }
  }

  ({Color color, String label}) _getStatusInfo(ProductHealthStatus status) {
    switch (status) {
      case ProductHealthStatus.okVerificado:
        return (color: Colors.green, label: 'OK');
      case ProductHealthStatus.conProblema:
        return (color: Colors.orange, label: 'Con Problema');
      case ProductHealthStatus.enGarantia:
        return (color: Colors.blue, label: 'En Garantía');
      case ProductHealthStatus.perdido:
        return (color: Colors.red, label: 'Perdido');
      case ProductHealthStatus.danadoSinGarantia:
        return (color: Colors.red.shade700, label: 'Dañado');
      case ProductHealthStatus.reparado:
        return (color: Colors.teal, label: 'Reparado');
      case ProductHealthStatus.enRevision:
        return (color: Colors.amber, label: 'En Revisión');
    }
  }
}
