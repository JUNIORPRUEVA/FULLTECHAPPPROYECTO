import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/services/app_config.dart';
import '../../../core/widgets/module_page.dart';
import '../models/categoria_producto.dart';
import '../models/producto.dart';
import '../state/catalog_providers.dart';
import '../../../modules/inventory/state/inventory_providers.dart';

String _catalogPublicBase() {
  final base = AppConfig.apiBaseUrl;
  return base.replaceFirst(RegExp(r'/api/?$'), '');
}

String? resolveCatalogPublicUrl(String? url) {
  if (url == null) return null;
  final trimmed = url.trim();
  if (trimmed.isEmpty) return null;
  // Local file paths are handled separately via Image.file.
  if (_isLikelyLocalPath(trimmed)) return null;
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  if (trimmed.startsWith('/')) return '${_catalogPublicBase()}$trimmed';
  return '${_catalogPublicBase()}/$trimmed';
}

bool _isLikelyLocalPath(String value) {
  // Treat backend-served paths like /uploads/... as remote (not local).
  if (value.startsWith('/uploads/')) return false;

  // Windows: C:\... or C:/...
  if (RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(value)) return true;
  // file://...
  if (value.startsWith('file://')) return true;
  return false;
}

enum _StockMode { add, subtract }

class CatalogoScreen extends ConsumerStatefulWidget {
  const CatalogoScreen({super.key});

  @override
  ConsumerState<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends ConsumerState<CatalogoScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Kick off offline-first bootstrap.
    // Avoid touching providers during initState (Riverpod best-practice).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(catalogControllerProvider.notifier).bootstrap();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(catalogControllerProvider);
    final controller = ref.read(catalogControllerProvider.notifier);

    final isMobile = MediaQuery.of(context).size.width < 900;

    return ModulePage(
      title: '',
      denseHeader: true,
      actions: const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FiltersBar(
            searchCtrl: _searchCtrl,
            categorias: state.categorias,
            selectedCategoriaId: state.selectedCategoriaId,
            includeInactive: state.includeInactive,
            isOnline: state.isOnline,
            isLoading: state.isLoading,
            onChangedQuery: (v) {
              controller.setQuery(v);
              controller.loadProductos();
            },
            onChangedCategoria: (id) {
              controller.setCategoria(id);
              controller.loadProductos();
            },
            onChangedIncludeInactive: (v) {
              controller.setIncludeInactive(v);
              controller.loadProductos();
            },
            onSync: () => controller.syncAll(),
            onCreateProducto: () =>
                _openProductoDialog(context, categorias: state.categorias),
            onManageCategorias: () => _openCategoriasManagerDialog(context),
            onAdjustStock: () => _openStockAdjustmentDialog(context),
            onManageMarcas: () => _openMarcasManagerDialog(context),
          ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Material(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.error!,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                // Grid de productos (80%)
                Expanded(
                  flex: 80,
                  child: Stack(
                    children: [
                      if (state.productos.isEmpty && !state.isLoading)
                        Center(
                          child: Text(
                            state.query.trim().isEmpty &&
                                    state.selectedCategoriaId == null
                                ? 'No hay productos aún.'
                                : 'No hay resultados con esos filtros.',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        )
                      else
                        _ProductsGrid(
                          productos: state.productos,
                          isMobile: isMobile,
                          onOpen: (p) async {
                            // Best-effort increment.
                            await controller.incrementSearch(p.id);
                            await _openProductoDetailsDialog(
                              context,
                              producto: p,
                              categorias: state.categorias,
                            );
                          },
                          onEdit: (p) => _openProductoDialog(
                            context,
                            categorias: state.categorias,
                            initial: p,
                          ),
                          onDelete: (p) => _confirmDelete(context, p),
                        ),
                      if (state.isLoading)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Container(
                              color: Theme.of(
                                context,
                              ).colorScheme.surface.withOpacity(0.6),
                              alignment: Alignment.center,
                              child: const CircularProgressIndicator(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Panel de resumen (20%)
                Expanded(
                  flex: 20,
                  child: _StatsPanel(
                    totalProductos: state.productos.length,
                    totalCategorias: state.categorias.length,
                    ultimos: _getUltimosProductos(state.productos),
                    masBuscados: _getMassBuscados(state.productos),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Producto> _getUltimosProductos(List<Producto> productos) {
    // Para simular "últimos" ordenamos de forma inversa (asumiendo que el ID se incrementa)
    // o usamos los primeros 3 de la lista actual
    return productos.take(3).toList();
  }

  List<Producto> _getMassBuscados(List<Producto> productos) {
    // Ordena por searchCount descendente y toma los top 3
    final sorted = List<Producto>.from(productos)
      ..sort((a, b) => b.searchCount.compareTo(a.searchCount));
    return sorted.take(3).toList();
  }

  Future<CategoriaProducto?> _showCreateCategoriaDialog(
    BuildContext context,
  ) async {
    final controller = ref.read(catalogControllerProvider.notifier);
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    final resultado = await showDialog<CategoriaProducto?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nueva categoría'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                final nombre = nameCtrl.text.trim();
                if (nombre.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('El nombre es requerido')),
                  );
                  return;
                }

                final desc = descCtrl.text.trim();
                final newCat = await controller.createCategoria(
                  nombre: nombre,
                  descripcion: desc.isEmpty ? null : desc,
                );

                if (context.mounted) {
                  Navigator.pop(context, newCat);
                }
              },
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );

    return resultado;
  }

  Future<void> _openCategoriasManagerDialog(BuildContext context) async {
    final ctrl = ref.read(catalogControllerProvider.notifier);
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final screenW = MediaQuery.of(dialogContext).size.width;
        final maxW = screenW < 860 ? screenW - 24 : 860.0;

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 18,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW, maxHeight: 620),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Consumer(
                builder: (context, ref, _) {
                  final st = ref.watch(catalogControllerProvider);
                  final cats = st.categorias;
                  final cs = Theme.of(context).colorScheme;

                  Future<void> create() async {
                    final nombre = nameCtrl.text.trim();
                    final descripcion = descCtrl.text.trim().isEmpty
                        ? null
                        : descCtrl.text.trim();
                    if (nombre.isEmpty) return;
                    await ctrl.createCategoria(
                      nombre: nombre,
                      descripcion: descripcion,
                    );
                    nameCtrl.clear();
                    descCtrl.clear();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Categorías',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Cerrar',
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Material(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              TextField(
                                controller: nameCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Nueva categoría',
                                  prefixIcon: Icon(Icons.category_outlined),
                                ),
                                onSubmitted: (_) => create(),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: descCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Descripción (opcional)',
                                  prefixIcon: Icon(Icons.notes_outlined),
                                ),
                                maxLines: 2,
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: FilledButton.icon(
                                  onPressed: st.isLoading ? null : create,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Crear'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: cats.isEmpty
                            ? const Center(child: Text('No hay categorías'))
                            : ListView.separated(
                                itemCount: cats.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, i) {
                                  final c = cats[i];
                                  return ListTile(
                                    dense: true,
                                    leading: Icon(
                                      c.isActive
                                          ? Icons.category_outlined
                                          : Icons.category,
                                      color: c.isActive
                                          ? cs.primary
                                          : cs.onSurfaceVariant,
                                    ),
                                    title: Text(c.nombre),
                                    subtitle:
                                        c.descripcion != null &&
                                            c.descripcion!.trim().isNotEmpty
                                        ? Text(
                                            c.descripcion!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          )
                                        : null,
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: 'Editar',
                                          onPressed: st.isLoading
                                              ? null
                                              : () async {
                                                  final editName =
                                                      TextEditingController(
                                                        text: c.nombre,
                                                      );
                                                  final editDesc =
                                                      TextEditingController(
                                                        text:
                                                            c.descripcion ?? '',
                                                      );
                                                  final ok = await showDialog<bool>(
                                                    context: context,
                                                    builder: (_) => AlertDialog(
                                                      title: const Text(
                                                        'Editar categoría',
                                                      ),
                                                      content: SizedBox(
                                                        width: 520,
                                                        child: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            TextField(
                                                              controller:
                                                                  editName,
                                                              decoration:
                                                                  const InputDecoration(
                                                                    labelText:
                                                                        'Nombre',
                                                                  ),
                                                              autofocus: true,
                                                            ),
                                                            const SizedBox(
                                                              height: 12,
                                                            ),
                                                            TextField(
                                                              controller:
                                                                  editDesc,
                                                              decoration:
                                                                  const InputDecoration(
                                                                    labelText:
                                                                        'Descripción (opcional)',
                                                                  ),
                                                              maxLines: 2,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.of(
                                                                context,
                                                              ).pop(false),
                                                          child: const Text(
                                                            'Cancelar',
                                                          ),
                                                        ),
                                                        FilledButton(
                                                          onPressed: () =>
                                                              Navigator.of(
                                                                context,
                                                              ).pop(true),
                                                          child: const Text(
                                                            'Guardar',
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                  if (ok != true) return;
                                                  final nombre = editName.text
                                                      .trim();
                                                  if (nombre.isEmpty) return;
                                                  await ctrl.updateCategoria(
                                                    c.id,
                                                    nombre: nombre,
                                                    descripcion: editDesc.text
                                                        .trim(),
                                                  );
                                                },
                                          icon: const Icon(Icons.edit_outlined),
                                        ),
                                        IconButton(
                                          tooltip: 'Eliminar',
                                          onPressed:
                                              (!c.isActive || st.isLoading)
                                              ? null
                                              : () async {
                                                  final ok = await showDialog<bool>(
                                                    context: context,
                                                    builder: (_) => AlertDialog(
                                                      title: const Text(
                                                        'Eliminar categoría',
                                                      ),
                                                      content: Text(
                                                        '¿Seguro que deseas eliminar “${c.nombre}”?',
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.of(
                                                                context,
                                                              ).pop(false),
                                                          child: const Text(
                                                            'Cancelar',
                                                          ),
                                                        ),
                                                        FilledButton(
                                                          onPressed: () =>
                                                              Navigator.of(
                                                                context,
                                                              ).pop(true),
                                                          child: const Text(
                                                            'Eliminar',
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                  if (ok != true) return;
                                                  final okDelete = await ctrl
                                                      .deleteCategoria(c.id);
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          okDelete
                                                              ? 'Categoría eliminada'
                                                              : (ref
                                                                        .read(
                                                                          catalogControllerProvider,
                                                                        )
                                                                        .error ??
                                                                    'No se pudo eliminar'),
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                      if (st.error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            st.error!,
                            style: TextStyle(
                              color: cs.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openMarcasManagerDialog(BuildContext context) async {
    final ctrl = ref.read(catalogControllerProvider.notifier);
    final nameCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final screenW = MediaQuery.of(dialogContext).size.width;
        final maxW = screenW < 760 ? screenW - 24 : 760.0;

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 18,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW, maxHeight: 600),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Consumer(
                builder: (context, ref, _) {
                  final st = ref.watch(catalogControllerProvider);
                  final marcas = st.marcas;
                  final cs = Theme.of(context).colorScheme;

                  Future<void> create() async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    await ctrl.createMarca(name);
                    nameCtrl.clear();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Marcas',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Cerrar',
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Material(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: nameCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Nueva marca',
                                    prefixIcon: Icon(Icons.sell_outlined),
                                  ),
                                  onSubmitted: (_) => create(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              FilledButton.icon(
                                onPressed: st.isLoading ? null : create,
                                icon: const Icon(Icons.add),
                                label: const Text('Crear'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: marcas.isEmpty
                            ? const Center(child: Text('No hay marcas'))
                            : ListView.separated(
                                itemCount: marcas.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, i) {
                                  final m = marcas[i];
                                  return ListTile(
                                    dense: true,
                                    leading: const Icon(Icons.sell_outlined),
                                    title: Text(m.nombre),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: 'Editar',
                                          onPressed: st.isLoading
                                              ? null
                                              : () async {
                                                  final editCtrl =
                                                      TextEditingController(
                                                        text: m.nombre,
                                                      );
                                                  final ok = await showDialog<bool>(
                                                    context: context,
                                                    builder: (_) => AlertDialog(
                                                      title: const Text(
                                                        'Editar marca',
                                                      ),
                                                      content: SizedBox(
                                                        width: 480,
                                                        child: TextField(
                                                          controller: editCtrl,
                                                          decoration:
                                                              const InputDecoration(
                                                                labelText:
                                                                    'Nombre',
                                                              ),
                                                          autofocus: true,
                                                        ),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.of(
                                                                context,
                                                              ).pop(false),
                                                          child: const Text(
                                                            'Cancelar',
                                                          ),
                                                        ),
                                                        FilledButton(
                                                          onPressed: () =>
                                                              Navigator.of(
                                                                context,
                                                              ).pop(true),
                                                          child: const Text(
                                                            'Guardar',
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                  if (ok != true) return;
                                                  final nextName = editCtrl.text
                                                      .trim();
                                                  if (nextName.isEmpty) return;
                                                  final okRename = await ctrl
                                                      .renameMarca(
                                                        m.id,
                                                        nextName,
                                                      );
                                                  if (context.mounted &&
                                                      !okRename) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          ref
                                                                  .read(
                                                                    catalogControllerProvider,
                                                                  )
                                                                  .error ??
                                                              'No se pudo actualizar',
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                          icon: const Icon(Icons.edit_outlined),
                                        ),
                                        IconButton(
                                          tooltip: 'Eliminar',
                                          onPressed: st.isLoading
                                              ? null
                                              : () async {
                                                  final ok = await showDialog<bool>(
                                                    context: context,
                                                    builder: (_) => AlertDialog(
                                                      title: const Text(
                                                        'Eliminar marca',
                                                      ),
                                                      content: Text(
                                                        '¿Seguro que deseas eliminar “${m.nombre}”?\n\nEsto quitará la marca de los productos que la usan.',
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.of(
                                                                context,
                                                              ).pop(false),
                                                          child: const Text(
                                                            'Cancelar',
                                                          ),
                                                        ),
                                                        FilledButton(
                                                          onPressed: () =>
                                                              Navigator.of(
                                                                context,
                                                              ).pop(true),
                                                          child: const Text(
                                                            'Eliminar',
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                  if (ok != true) return;
                                                  final okDelete = await ctrl
                                                      .deleteMarca(m.id);
                                                  if (context.mounted &&
                                                      !okDelete) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          ref
                                                                  .read(
                                                                    catalogControllerProvider,
                                                                  )
                                                                  .error ??
                                                              'No se pudo eliminar',
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                      if (st.error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            st.error!,
                            style: TextStyle(
                              color: cs.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openStockAdjustmentDialog(BuildContext context) async {
    final ctrl = ref.read(catalogControllerProvider.notifier);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final cs = Theme.of(dialogContext).colorScheme;
        final products = ref.read(catalogControllerProvider).productos;

        Producto? selected;
        var mode = _StockMode.add;
        final qtyCtrl = TextEditingController();
        final noteCtrl = TextEditingController();
        var isSubmitting = false;

        bool validQty(String raw) {
          final v = raw.trim();
          if (v.isEmpty) return false;
          final n = int.tryParse(v);
          return n != null && n > 0;
        }

        return StatefulBuilder(
          builder: (context, setLocalState) {
            Widget selectedThumb(Producto p) {
              final raw = p.imagenUrl.trim();
              if (raw.isNotEmpty && _isLikelyLocalPath(raw)) {
                if (kIsWeb) {
                  return Container(
                    color: cs.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: cs.onSurfaceVariant,
                      size: 16,
                    ),
                  );
                }
                final path = raw.startsWith('file://')
                    ? Uri.parse(raw).toFilePath()
                    : raw;
                return Image.file(
                  File(path),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: cs.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: cs.onSurfaceVariant,
                      size: 16,
                    ),
                  ),
                );
              }

              final url = resolveCatalogPublicUrl(raw);
              if (url == null) {
                return Container(
                  color: cs.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.photo_outlined,
                    color: cs.onSurfaceVariant,
                    size: 16,
                  ),
                );
              }

              return Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: cs.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: cs.onSurfaceVariant,
                    size: 16,
                  ),
                ),
              );
            }

            Future<Producto?> pickProduct() async {
              final scrollCtrl = ScrollController();
              final picked = await showDialog<Producto>(
                context: dialogContext,
                builder: (pickContext) {
                  final pickCs = Theme.of(pickContext).colorScheme;
                  final searchCtrl = TextEditingController();
                  List<Producto> filtered = List<Producto>.from(products);

                  Color stockColor(Producto p) {
                    if (p.stock <= 0) return pickCs.error;
                    if (p.stock <= p.minStock) return Colors.amber.shade800;
                    return Colors.green.shade700;
                  }

                  Widget thumb(Producto p) {
                    final raw = p.imagenUrl.trim();
                    if (raw.isNotEmpty && _isLikelyLocalPath(raw)) {
                      if (kIsWeb) {
                        return Container(
                          color: pickCs.surfaceContainerHighest,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: pickCs.onSurfaceVariant,
                          ),
                        );
                      }
                      final path = raw.startsWith('file://')
                          ? Uri.parse(raw).toFilePath()
                          : raw;
                      return Image.file(
                        File(path),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: pickCs.surfaceContainerHighest,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: pickCs.onSurfaceVariant,
                          ),
                        ),
                      );
                    }

                    final url = resolveCatalogPublicUrl(raw);
                    if (url == null) {
                      return Container(
                        color: pickCs.surfaceContainerHighest,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.photo_outlined,
                          color: pickCs.onSurfaceVariant,
                        ),
                      );
                    }

                    return Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: pickCs.surfaceContainerHighest,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: pickCs.onSurfaceVariant,
                        ),
                      ),
                    );
                  }

                  void applyFilter(String raw) {
                    final q = raw.trim().toLowerCase();
                    if (q.isEmpty) {
                      filtered = List<Producto>.from(products);
                      return;
                    }
                    filtered = products
                        .where((p) => p.nombre.toLowerCase().contains(q))
                        .toList();
                  }

                  applyFilter('');

                  return StatefulBuilder(
                    builder: (pickContext, setPickState) {
                      final screenW = MediaQuery.of(pickContext).size.width;
                      final maxW = screenW < 760 ? screenW - 24 : 760.0;

                      return Dialog(
                        insetPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: maxW,
                            maxHeight: 620,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Seleccionar producto',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Cerrar',
                                      onPressed: () =>
                                          Navigator.of(pickContext).pop(),
                                      icon: const Icon(Icons.close),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: searchCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Buscar',
                                    prefixIcon: Icon(Icons.search),
                                  ),
                                  onChanged: (v) {
                                    setPickState(() => applyFilter(v));
                                  },
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: filtered.isEmpty
                                      ? Center(
                                          child: Text(
                                            searchCtrl.text.trim().isEmpty
                                                ? 'No hay productos disponibles.'
                                                : 'No hay resultados.',
                                            style: Theme.of(
                                              pickContext,
                                            ).textTheme.titleMedium,
                                          ),
                                        )
                                      : Scrollbar(
                                          controller: scrollCtrl,
                                          thumbVisibility: true,
                                          child: ListView.separated(
                                            controller: scrollCtrl,
                                            primary: false,
                                            itemCount: filtered.length,
                                            separatorBuilder: (_, __) =>
                                                const SizedBox(height: 8),
                                            itemBuilder: (context, i) {
                                              final p = filtered[i];
                                              return Material(
                                                color: pickCs
                                                    .surfaceContainerHighest,
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                child: InkWell(
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                  onTap: () => Navigator.of(
                                                    pickContext,
                                                  ).pop(p),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          10,
                                                        ),
                                                    child: Row(
                                                      children: [
                                                        ClipRRect(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                10,
                                                              ),
                                                          child: SizedBox(
                                                            width: 44,
                                                            height: 44,
                                                            child: thumb(p),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 10,
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            p.nombre,
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: Theme.of(pickContext)
                                                                .textTheme
                                                                .titleSmall
                                                                ?.copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w800,
                                                                ),
                                                          ),
                                                        ),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 10,
                                                                vertical: 6,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: stockColor(p)
                                                                .withValues(
                                                                  alpha: 0.12,
                                                                ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  999,
                                                                ),
                                                            border: Border.all(
                                                              color:
                                                                  stockColor(
                                                                    p,
                                                                  ).withValues(
                                                                    alpha: 0.35,
                                                                  ),
                                                            ),
                                                          ),
                                                          child: Text(
                                                            'Stock: ${p.stock}',
                                                            style: Theme.of(pickContext)
                                                                .textTheme
                                                                .labelSmall
                                                                ?.copyWith(
                                                                  color:
                                                                      stockColor(
                                                                        p,
                                                                      ),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w900,
                                                                ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
              scrollCtrl.dispose();
              return picked;
            }

            Future<void> submit() async {
              final p = selected;
              final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
              if (p == null || qty <= 0) return;
              if (isSubmitting) return;

              final delta = mode == _StockMode.add ? qty : -qty;
              if (delta < 0 && (p.stock + delta) < 0) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'No puedes restar $qty. Stock actual: ${p.stock}',
                    ),
                  ),
                );
                return;
              }

              setLocalState(() => isSubmitting = true);
              final ok = await ctrl.adjustStock(
                p.id,
                delta: delta,
                note: noteCtrl.text.trim().isEmpty
                    ? null
                    : noteCtrl.text.trim(),
              );
              setLocalState(() => isSubmitting = false);

              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ok
                        ? 'Stock actualizado'
                        : (ref.read(catalogControllerProvider).error ??
                              'No se pudo actualizar el stock'),
                  ),
                ),
              );
              if (ok) Navigator.of(dialogContext).pop();
            }

            final canSubmit =
                selected != null && validQty(qtyCtrl.text) && !isSubmitting;

            final screenW = MediaQuery.of(dialogContext).size.width;
            final maxW = screenW < 720 ? screenW - 24 : 720.0;

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 18,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Ajuste de stock',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Cerrar',
                            onPressed: isSubmitting
                                ? null
                                : () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: isSubmitting
                            ? null
                            : () async {
                                final picked = await pickProduct();
                                if (picked == null) return;
                                setLocalState(() => selected = picked);
                              },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Producto',
                            prefixIcon: Icon(Icons.inventory_2_outlined),
                          ),
                          child: Row(
                            children: [
                              if (selected != null) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: selectedThumb(selected!),
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ],
                              Expanded(
                                child: Text(
                                  selected == null
                                      ? 'Seleccionar...'
                                      : selected!.nombre,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: selected == null
                                        ? FontWeight.w600
                                        : FontWeight.w800,
                                  ),
                                ),
                              ),
                              if (selected != null) ...[
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        (selected!.stock <= 0
                                                ? cs.error
                                                : (selected!.stock <=
                                                          selected!.minStock
                                                      ? Colors.amber.shade800
                                                      : Colors.green.shade700))
                                            .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'Stock: ${selected!.stock}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ],
                              const SizedBox(width: 6),
                              const Icon(Icons.expand_more),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<_StockMode>(
                        segments: const [
                          ButtonSegment<_StockMode>(
                            value: _StockMode.add,
                            icon: Icon(Icons.add_circle_outline),
                            label: Text('Agregar'),
                          ),
                          ButtonSegment<_StockMode>(
                            value: _StockMode.subtract,
                            icon: Icon(Icons.remove_circle_outline),
                            label: Text('Restar'),
                          ),
                        ],
                        selected: {mode},
                        onSelectionChanged: isSubmitting
                            ? null
                            : (s) {
                                setLocalState(() => mode = s.first);
                              },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: qtyCtrl,
                        decoration: InputDecoration(
                          labelText: mode == _StockMode.add
                              ? 'Cantidad a agregar'
                              : 'Cantidad a restar',
                          prefixIcon: Icon(
                            mode == _StockMode.add
                                ? Icons.add_circle_outline
                                : Icons.remove_circle_outline,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (_) => setLocalState(() {}),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: noteCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Motivo / nota (opcional)',
                          prefixIcon: Icon(Icons.notes_outlined),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: canSubmit ? submit : null,
                              icon: isSubmitting
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: cs.onPrimary,
                                      ),
                                    )
                                  : const Icon(Icons.check),
                              label: const Text('Confirmar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openCategoriaDialog(BuildContext context) async {
    final controller = ref.read(catalogControllerProvider.notifier);
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nueva categoría'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;
    final nombre = nameCtrl.text.trim();
    final descripcion = descCtrl.text.trim().isEmpty
        ? null
        : descCtrl.text.trim();
    if (nombre.isEmpty) return;
    await controller.createCategoria(nombre: nombre, descripcion: descripcion);
  }

  Future<void> _openProductoDialog(
    BuildContext context, {
    required List<CategoriaProducto> categorias,
    Producto? initial,
  }) async {
    final controller = ref.read(catalogControllerProvider.notifier);
    final marcas = ref.read(catalogControllerProvider).marcas;
    final suppliersFuture = ref
        .read(inventoryRepositoryProvider)
        .listSuppliers();

    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController(text: initial?.nombre ?? '');
    final costoCtrl = TextEditingController(
      text: initial != null ? initial.precioCompra.toStringAsFixed(2) : '',
    );
    final precioCtrl = TextEditingController(
      text: initial != null ? initial.precioVenta.toStringAsFixed(2) : '',
    );
    final imagenCtrl = TextEditingController(text: initial?.imagenUrl ?? '');

    final stockCtrl = TextEditingController(
      text: (initial?.stock ?? 0).toString(),
    );
    final minStockCtrl = TextEditingController(
      text: (initial?.minStock ?? 0).toString(),
    );
    String? selectedMarca = (initial?.brandId ?? '').trim().isEmpty
        ? null
        : initial!.brandId;
    String? selectedSupplierId = (initial?.supplier ?? '').trim().isEmpty
        ? null
        : initial!.supplier;
    final supplierTextCtrl = TextEditingController();

    String? categoriaId = initial?.categoriaId;

    // Prevent letters: allow only digits + decimal separators.
    final moneyInput = FilteringTextInputFormatter.allow(RegExp(r'[0-9\.,]'));

    double? parseMoney(String raw) {
      final v = raw.trim();
      if (v.isEmpty) return null;
      final normalized = v.replaceAll(',', '.');
      return double.tryParse(normalized);
    }

    String? validateMoney(String? raw) {
      final v = (raw ?? '').trim();
      if (v.isEmpty) return 'Requerido';
      if (!RegExp(r'^\d+(?:[\.,]\d{1,2})?$').hasMatch(v)) {
        return 'Solo números (ej: 1500.00)';
      }
      final parsed = parseMoney(v);
      if (parsed == null) return 'Solo números (ej: 1500.00)';
      if (parsed < 0) return 'No puede ser negativo';
      return null;
    }

    var isUploading = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            Future<void> pickAndUpload() async {
              if (isUploading) return;
              final res = await FilePicker.platform.pickFiles(
                allowMultiple: false,
                type: FileType.custom,
                allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
                withData: false,
              );
              final path = res?.files.single.path;
              if (path == null || path.trim().isEmpty) return;

              setLocalState(() => isUploading = true);
              final url = await controller.uploadProductImage(path);
              setLocalState(() => isUploading = false);

              if (url != null && url.trim().isNotEmpty) {
                imagenCtrl.text = url.trim();
              } else {
                final err = ref.read(catalogControllerProvider).error;
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        err ??
                            'No se pudo subir la imagen. Verifica conexión y permisos.',
                      ),
                    ),
                  );
                }
              }
            }

            return AlertDialog(
              title: Text(
                initial == null ? 'Nuevo producto' : 'Editar producto',
              ),
              content: SizedBox(
                width: 640,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nombreCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nombre',
                            prefixIcon: Icon(Icons.inventory_2_outlined),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Requerido'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: costoCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Costo',
                                  prefixIcon: Icon(Icons.payments_outlined),
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [moneyInput],
                                validator: validateMoney,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: precioCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Precio',
                                  prefixIcon: Icon(Icons.sell_outlined),
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [moneyInput],
                                validator: (v) {
                                  final base = validateMoney(v);
                                  if (base != null) return base;
                                  final costo = parseMoney(costoCtrl.text) ?? 0;
                                  final precio =
                                      parseMoney(precioCtrl.text) ?? 0;
                                  if (precio < costo) {
                                    return 'Precio debe ser >= costo';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: categoriaId,
                                items: [
                                  for (final c in categorias.where(
                                    (c) => c.isActive,
                                  ))
                                    DropdownMenuItem(
                                      value: c.id,
                                      child: Text(c.nombre),
                                    ),
                                ],
                                onChanged: (v) =>
                                    setLocalState(() => categoriaId = v),
                                decoration: const InputDecoration(
                                  labelText: 'Categoría',
                                  prefixIcon: Icon(Icons.category_outlined),
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'Selecciona una categoría'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Tooltip(
                              message: 'Crear nueva categoría',
                              child: FilledButton.icon(
                                onPressed: () async {
                                  final newCategoria =
                                      await _showCreateCategoriaDialog(context);
                                  if (newCategoria != null) {
                                    setLocalState(() {
                                      categorias = [
                                        ...categorias,
                                        newCategoria,
                                      ];
                                      categoriaId = newCategoria.id;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Nueva'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: stockCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Stock',
                                  prefixIcon: Icon(Icons.inventory_outlined),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (v) {
                                  final raw = (v ?? '').trim();
                                  if (raw.isEmpty) return 'Requerido';
                                  final n = int.tryParse(raw);
                                  if (n == null) return 'Solo números';
                                  if (n < 0) return 'No puede ser negativo';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: minStockCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Mínimo stock',
                                  prefixIcon: Icon(
                                    Icons.warning_amber_outlined,
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (v) {
                                  final raw = (v ?? '').trim();
                                  if (raw.isEmpty) return 'Requerido';
                                  final n = int.tryParse(raw);
                                  if (n == null) return 'Solo números';
                                  if (n < 0) return 'No puede ser negativo';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedMarca,
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('(Sin marca)'),
                                  ),
                                  for (final m in marcas)
                                    DropdownMenuItem<String>(
                                      value: m.nombre,
                                      child: Text(
                                        m.nombre,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                                onChanged: (v) =>
                                    setLocalState(() => selectedMarca = v),
                                decoration: const InputDecoration(
                                  labelText: 'Marca (opcional)',
                                  prefixIcon: Icon(Icons.sell_outlined),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FutureBuilder<List<Map<String, dynamic>>>(
                                future: suppliersFuture,
                                builder: (context, snap) {
                                  final suppliers =
                                      snap.data ??
                                      const <Map<String, dynamic>>[];
                                  if (supplierTextCtrl.text.trim().isEmpty &&
                                      selectedSupplierId != null) {
                                    final match = suppliers
                                        .where(
                                          (s) =>
                                              (s['id'] ?? '').toString() ==
                                              selectedSupplierId,
                                        )
                                        .firstWhere(
                                          (_) => true,
                                          orElse: () =>
                                              const <String, dynamic>{},
                                        );
                                    final name = (match['name'] ?? '')
                                        .toString();
                                    if (name.trim().isNotEmpty)
                                      supplierTextCtrl.text = name;
                                  }

                                  return Autocomplete<Map<String, dynamic>>(
                                    optionsBuilder: (textEditingValue) {
                                      final q = textEditingValue.text
                                          .trim()
                                          .toLowerCase();
                                      if (q.isEmpty)
                                        return const Iterable<
                                          Map<String, dynamic>
                                        >.empty();
                                      return suppliers
                                          .where((s) {
                                            final name = (s['name'] ?? '')
                                                .toString()
                                                .toLowerCase();
                                            return name.contains(q);
                                          })
                                          .take(20);
                                    },
                                    displayStringForOption: (s) =>
                                        (s['name'] ?? '').toString(),
                                    onSelected: (s) {
                                      final id = (s['id'] ?? '')
                                          .toString()
                                          .trim();
                                      final name = (s['name'] ?? '').toString();
                                      setLocalState(() {
                                        selectedSupplierId = id.isEmpty
                                            ? null
                                            : id;
                                        supplierTextCtrl.text = name;
                                      });
                                    },
                                    fieldViewBuilder:
                                        (
                                          context,
                                          textCtrl,
                                          focusNode,
                                          onFieldSubmitted,
                                        ) {
                                          if (textCtrl.text.isEmpty &&
                                              supplierTextCtrl
                                                  .text
                                                  .isNotEmpty) {
                                            textCtrl.text =
                                                supplierTextCtrl.text;
                                          }
                                          return TextFormField(
                                            controller: textCtrl,
                                            focusNode: focusNode,
                                            decoration: InputDecoration(
                                              labelText: 'Proveedor (opcional)',
                                              prefixIcon: const Icon(
                                                Icons.local_shipping_outlined,
                                              ),
                                              suffixIcon:
                                                  selectedSupplierId == null
                                                  ? null
                                                  : IconButton(
                                                      tooltip:
                                                          'Quitar proveedor',
                                                      onPressed: () =>
                                                          setLocalState(() {
                                                            selectedSupplierId =
                                                                null;
                                                            supplierTextCtrl
                                                                .clear();
                                                            textCtrl.clear();
                                                          }),
                                                      icon: const Icon(
                                                        Icons.clear,
                                                      ),
                                                    ),
                                            ),
                                          );
                                        },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: imagenCtrl,
                          decoration: InputDecoration(
                            labelText: 'URL de imagen',
                            prefixIcon: const Icon(Icons.image_outlined),
                            suffixIcon: IconButton(
                              tooltip: 'Subir imagen',
                              onPressed: isUploading ? null : pickAndUpload,
                              icon: isUploading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.upload_file_outlined),
                            ),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Agrega una URL o sube una imagen'
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isUploading
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: isUploading
                      ? null
                      : () => Navigator.of(context).pop(true),
                  child: Text(initial == null ? 'Crear' : 'Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok != true) return;
    if (!(formKey.currentState?.validate() ?? false)) return;

    final nombre = nombreCtrl.text.trim();
    final imagenUrl = imagenCtrl.text.trim();
    final costo = parseMoney(costoCtrl.text) ?? 0;
    final precio = parseMoney(precioCtrl.text) ?? 0;
    final catId = categoriaId?.trim();
    final stock = int.tryParse(stockCtrl.text.trim()) ?? 0;
    final minStock = int.tryParse(minStockCtrl.text.trim()) ?? 0;
    if (catId == null || catId.isEmpty) return;

    if (initial == null) {
      await controller.createProducto(
        nombre: nombre,
        precioCompra: costo,
        precioVenta: precio,
        imagenUrl: imagenUrl,
        categoriaId: catId,
        stock: stock,
        minStock: minStock,
        brandId: selectedMarca,
        supplierId: selectedSupplierId,
      );
    } else {
      await controller.updateProducto(
        id: initial.id,
        nombre: nombre,
        precioCompra: costo,
        precioVenta: precio,
        imagenUrl: imagenUrl,
        categoriaId: catId,
        stock: stock,
        minStock: minStock,
        brandId: selectedMarca,
        supplierId: selectedSupplierId,
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, Producto p) async {
    final controller = ref.read(catalogControllerProvider.notifier);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Seguro que deseas eliminar “${p.nombre}”?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    await controller.deleteProducto(p.id);
  }

  Future<void> _openProductoDetailsDialog(
    BuildContext context, {
    required Producto producto,
    required List<CategoriaProducto> categorias,
  }) async {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final categoriaNombre = producto.categoria?.nombre.isNotEmpty == true
        ? producto.categoria!.nombre
        : categorias
              .where((c) => c.id == producto.categoriaId)
              .map((c) => c.nombre)
              .cast<String?>()
              .firstWhere(
                (v) => v != null && v.trim().isNotEmpty,
                orElse: () => null,
              );

    Widget buildImage() {
      final raw = producto.imagenUrl.trim();

      if (raw.isNotEmpty && _isLikelyLocalPath(raw)) {
        if (kIsWeb) {
          return Container(
            color: cs.surfaceContainerHighest,
            alignment: Alignment.center,
            child: Icon(
              Icons.image_not_supported_outlined,
              color: cs.onSurfaceVariant,
              size: 48,
            ),
          );
        }

        final path = raw.startsWith('file://')
            ? Uri.parse(raw).toFilePath()
            : raw;

        return Image.file(
          File(path),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stack) {
            return Container(
              color: cs.surfaceContainerHighest,
              alignment: Alignment.center,
              child: Icon(
                Icons.image_not_supported_outlined,
                color: cs.onSurfaceVariant,
                size: 48,
              ),
            );
          },
        );
      }

      final url = resolveCatalogPublicUrl(raw);
      if (url == null) {
        return Container(
          color: cs.surfaceContainerHighest,
          alignment: Alignment.center,
          child: Icon(
            Icons.image_not_supported_outlined,
            color: cs.onSurfaceVariant,
            size: 48,
          ),
        );
      }

      return Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stack) {
          return Container(
            color: cs.surfaceContainerHighest,
            alignment: Alignment.center,
            child: Icon(
              Icons.image_not_supported_outlined,
              color: cs.onSurfaceVariant,
              size: 48,
            ),
          );
        },
      );
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final screenW = MediaQuery.of(dialogContext).size.width;
        final maxW = screenW < 720 ? screenW - 24 : 720.0;

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 18,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            producto.nombre,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: (textTheme.titleLarge ?? const TextStyle())
                                .copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Cerrar',
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Container(
                    color: cs.surfaceContainerHighest,
                    padding: const EdgeInsets.all(12),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ColoredBox(
                          color: cs.surface,
                          child: buildImage(),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _DetailChip(
                              label: 'Estado',
                              value: producto.isActive ? 'Activo' : 'Inactivo',
                            ),
                            _DetailChip(
                              label: 'Categoría',
                              value: categoriaNombre ?? '—',
                            ),
                            _DetailChip(label: 'ID', value: producto.id),
                            _DetailChip(
                              label: 'Búsquedas',
                              value: producto.searchCount.toString(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _DetailAmount(
                                label: 'Costo',
                                value: producto.precioCompra,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _DetailAmount(
                                label: 'Precio',
                                value: producto.precioVenta,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('Cerrar'),
                        ),
                        const Spacer(),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            _confirmDelete(context, producto);
                          },
                          child: const Text('Eliminar'),
                        ),
                        const SizedBox(width: 10),
                        FilledButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            _openProductoDialog(
                              context,
                              categorias: categorias,
                              initial: producto,
                            );
                          },
                          child: const Text('Editar'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DetailChip extends StatelessWidget {
  final String label;
  final String value;

  const _DetailChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: (textTheme.labelSmall ?? const TextStyle()).copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: (textTheme.bodyMedium ?? const TextStyle()).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailAmount extends StatelessWidget {
  final String label;
  final double value;

  const _DetailAmount({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: (textTheme.labelSmall ?? const TextStyle()).copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.toStringAsFixed(2),
            style: (textTheme.titleLarge ?? const TextStyle()).copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final List<CategoriaProducto> categorias;
  final String? selectedCategoriaId;
  final bool includeInactive;
  final bool isOnline;
  final bool isLoading;

  final ValueChanged<String> onChangedQuery;
  final ValueChanged<String?> onChangedCategoria;
  final ValueChanged<bool> onChangedIncludeInactive;
  final VoidCallback onSync;
  final VoidCallback onCreateProducto;
  final VoidCallback onManageCategorias;
  final VoidCallback onAdjustStock;
  final VoidCallback onManageMarcas;

  const _FiltersBar({
    required this.searchCtrl,
    required this.categorias,
    required this.selectedCategoriaId,
    required this.includeInactive,
    required this.isOnline,
    required this.isLoading,
    required this.onChangedQuery,
    required this.onChangedCategoria,
    required this.onChangedIncludeInactive,
    required this.onSync,
    required this.onCreateProducto,
    required this.onManageCategorias,
    required this.onAdjustStock,
    required this.onManageMarcas,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final headerBg = cs.surfaceContainerHigh;
    final onHeader = cs.onSurface;
    final outlineColor = cs.outlineVariant;

    InputDecoration decorateInput(InputDecoration base, {Widget? prefixIcon}) {
      return base.copyWith(
        filled: true,
        fillColor: cs.surface,
        prefixIcon: prefixIcon,
        labelStyle: TextStyle(color: cs.onSurfaceVariant),
      );
    }

    ButtonStyle outlineOnHeader() {
      return OutlinedButton.styleFrom(
        foregroundColor: cs.primary,
        side: BorderSide(color: cs.primary.withValues(alpha: 0.72)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );
    }

    ButtonStyle stockHighlight() {
      return FilledButton.styleFrom(
        backgroundColor: cs.tertiaryContainer,
        foregroundColor: cs.onTertiaryContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );
    }

    return Material(
      elevation: 1,
      color: headerBg,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: outlineColor, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: IconTheme(
                    data: IconThemeData(color: onHeader),
                    child: DefaultTextStyle(
                      style: TextStyle(color: onHeader),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: isMobile ? 300 : 400,
                            child: TextField(
                              controller: searchCtrl,
                              decoration: decorateInput(
                                const InputDecoration(
                                  labelText: 'Buscar producto',
                                ),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Colors.black54,
                                ),
                              ),
                              onChanged: onChangedQuery,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 250,
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedCategoriaId,
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('Todas las categorías'),
                                ),
                                for (final c in categorias)
                                  DropdownMenuItem<String>(
                                    value: c.id,
                                    child: Text(
                                      c.nombre,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: onChangedCategoria,
                              decoration: decorateInput(
                                const InputDecoration(labelText: 'Categoría'),
                                prefixIcon: const Icon(
                                  Icons.category_outlined,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            style: outlineOnHeader(),
                            onPressed: isLoading ? null : onManageCategorias,
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('+ Categoría'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            style: stockHighlight(),
                            onPressed: isLoading ? null : onAdjustStock,
                            icon: const Icon(Icons.inventory_2_outlined),
                            label: const Text('Ajuste de stock'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            style: outlineOnHeader(),
                            onPressed: isLoading ? null : onManageMarcas,
                            icon: const Icon(Icons.sell_outlined),
                            label: const Text('Marca'),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Sincronizar',
                            onPressed: isLoading ? null : onSync,
                            icon: const Icon(Icons.sync),
                            color: onHeader,
                          ),
                          const SizedBox(width: 4),
                          FilledButton.icon(
                            onPressed: isLoading ? null : onCreateProducto,
                            icon: const Icon(Icons.add),
                            label: const Text('+ Nuevo'),
                          ),
                          const SizedBox(width: 8),
                          Tooltip(
                            message: 'Mostrar inactivos',
                            child: Switch(
                              value: includeInactive,
                              onChanged: isLoading
                                  ? null
                                  : onChangedIncludeInactive,
                            ),
                          ),
                          if (!isOnline) ...[
                            const SizedBox(width: 10),
                            Icon(
                              Icons.wifi_off,
                              size: 18,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Offline',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProductsGrid extends StatelessWidget {
  final List<Producto> productos;
  final bool isMobile;
  final ValueChanged<Producto> onOpen;
  final ValueChanged<Producto> onEdit;
  final ValueChanged<Producto> onDelete;

  const _ProductsGrid({
    required this.productos,
    required this.isMobile,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(6),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        // Prevent cards from becoming too tiny (which causes overflows), while
        // still allowing more columns on wide screens.
        maxCrossAxisExtent: isMobile ? 260 : 230,
        // Fixed height so the bottom area never overflows.
        mainAxisExtent: 240,
        childAspectRatio: 1,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: productos.length,
      itemBuilder: (context, i) {
        final p = productos[i];
        return _ProductCard(
          producto: p,
          onTap: () => onOpen(p),
          onEdit: () => onEdit(p),
          onDelete: () => onDelete(p),
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Producto producto;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.producto,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  Color _stockColor(ColorScheme cs) {
    final qty = producto.stock;
    final min = producto.minStock;
    if (qty <= 0) return cs.error;
    if (qty <= min) return Colors.amber.shade800;
    return Colors.green.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget buildImageContent() {
      final raw = producto.imagenUrl.trim();

      if (raw.isNotEmpty && _isLikelyLocalPath(raw)) {
        if (kIsWeb) {
          return Container(
            color: cs.surfaceContainerHighest,
            alignment: Alignment.center,
            child: Icon(
              Icons.image_not_supported_outlined,
              color: cs.onSurfaceVariant,
            ),
          );
        }

        final path = raw.startsWith('file://')
            ? Uri.parse(raw).toFilePath()
            : raw;

        return Image.file(
          File(path),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) {
            return Container(
              color: cs.surfaceContainerHighest,
              alignment: Alignment.center,
              child: Icon(
                Icons.image_not_supported_outlined,
                color: cs.onSurfaceVariant,
              ),
            );
          },
        );
      }

      final url = resolveCatalogPublicUrl(raw);
      if (url == null) {
        return Container(
          color: cs.surfaceContainerHighest,
          alignment: Alignment.center,
          child: Icon(
            Icons.image_not_supported_outlined,
            color: cs.onSurfaceVariant,
          ),
        );
      }

      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) {
          return Container(
            color: cs.surfaceContainerHighest,
            alignment: Alignment.center,
            child: Icon(
              Icons.image_not_supported_outlined,
              color: cs.onSurfaceVariant,
            ),
          );
        },
      );
    }

    return SizedBox(
      height: 240,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        border: Border.all(
                          color: cs.outlineVariant.withOpacity(0.35),
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          buildImageContent(),
                          Positioned(
                            left: 8,
                            top: 8,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: cs.surface.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: cs.outlineVariant.withOpacity(0.35),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                child: Text(
                                  producto.isActive ? 'Activo' : 'Inactivo',
                                  style:
                                      (textTheme.labelSmall ??
                                              const TextStyle())
                                          .copyWith(
                                            fontWeight: FontWeight.w900,
                                            color: producto.isActive
                                                ? cs.primary
                                                : cs.onSurfaceVariant,
                                          ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 6,
                            top: 6,
                            child: PopupMenuButton<String>(
                              tooltip: 'Acciones',
                              icon: const Icon(
                                Icons.more_vert,
                                color: Colors.white,
                                size: 20,
                              ),
                              onSelected: (v) {
                                if (v == 'edit') onEdit();
                                if (v == 'delete') onDelete();
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.edit, size: 18),
                                      const SizedBox(width: 8),
                                      const Text('Editar'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.delete,
                                        size: 18,
                                        color: Colors.red,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Eliminar',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Flexible(
                        child: Text(
                          producto.nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: (textTheme.labelMedium ?? const TextStyle())
                              .copyWith(
                                fontWeight: FontWeight.w900,
                                color: Colors.black87,
                              ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      SizedBox(
                        height: 28,
                        child: Row(
                          children: [
                            Expanded(
                              child: _PriceChip(
                                label: 'Stock',
                                value: producto.stock.toString(),
                                color: _stockColor(cs),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _PriceChip(
                                label: 'Costo',
                                value: producto.precioCompra.toStringAsFixed(2),
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _PriceChip(
                                label: 'Precio',
                                value: producto.precioVenta.toStringAsFixed(2),
                                color: Colors.blue,
                              ),
                            ),
                          ],
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
    );
  }
}

class _PriceChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _PriceChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2), width: 0.8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: (textTheme.labelSmall ?? const TextStyle()).copyWith(
              color: cs.onSurfaceVariant,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: (textTheme.labelMedium ?? const TextStyle()).copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 10,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsPanel extends StatelessWidget {
  final int totalProductos;
  final int totalCategorias;
  final List<Producto> ultimos;
  final List<Producto> masBuscados;

  const _StatsPanel({
    required this.totalProductos,
    required this.totalCategorias,
    required this.ultimos,
    required this.masBuscados,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.max,
          children: [
            // Título
            Text(
              'Resumen de Catálogo',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 20),

            // Estadísticas principales
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.inventory_2_outlined,
                    label: 'Productos',
                    value: totalProductos.toString(),
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    icon: Icons.category_outlined,
                    label: 'Categorías',
                    value: totalCategorias.toString(),
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Últimos agregados
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionTitle(title: 'Últimos Agregados'),
                  const SizedBox(height: 12),
                  if (ultimos.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Sin productos',
                        style: textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    Expanded(
                      child: ListView(
                        children: ultimos.asMap().entries.map((e) {
                          return _ProductListItem(
                            index: e.key + 1,
                            producto: e.value,
                            color: Colors.green,
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Más buscados
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionTitle(title: 'Más Buscados'),
                  const SizedBox(height: 12),
                  if (masBuscados.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Sin búsquedas aún',
                        style: textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    Expanded(
                      child: ListView(
                        children: masBuscados.asMap().entries.map((e) {
                          return _ProductListItem(
                            index: e.key + 1,
                            producto: e.value,
                            color: Colors.red,
                            showCount: true,
                          );
                        }).toList(),
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Text(
      title,
      style: textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: cs.onSurface,
      ),
    );
  }
}

class _ProductListItem extends StatelessWidget {
  final int index;
  final Producto producto;
  final Color color;
  final bool showCount;

  const _ProductListItem({
    required this.index,
    required this.producto,
    required this.color,
    this.showCount = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              index.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  producto.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '\$${producto.precioVenta.toStringAsFixed(2)}',
                  style: textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (showCount)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${producto.searchCount}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
