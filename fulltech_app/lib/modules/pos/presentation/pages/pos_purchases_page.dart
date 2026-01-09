import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/module_page.dart';
import '../../models/pos_models.dart';
import 'pos_purchase_pdf_preview_page.dart';
import '../../state/pos_providers.dart';
import '../widgets/pos_supplier_form_dialog.dart';

// FIX: debe ser ConsumerStatefulWidget para poder usar ConsumerState + ref
class PosPurchasesPage extends ConsumerStatefulWidget {
  const PosPurchasesPage({super.key});

  @override
  ConsumerState<PosPurchasesPage> createState() => _PosPurchasesPageState();
}

class _PosPurchasesPageState extends ConsumerState<PosPurchasesPage> {
  final _supplierSearch = TextEditingController();
  Future<List<PosSupplier>>? _suppliersFuture;
  String _supplierQuery = '';

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void initState() {
    super.initState();
    _refreshSuppliers();
  }

  @override
  void dispose() {
    _supplierSearch.dispose();
    super.dispose();
  }

  void _refreshSuppliers() {
    final repo = ref.read(posRepositoryProvider);
    setState(() {
      _suppliersFuture = repo.listSuppliers(search: _supplierQuery);
    });
  }

  Future<void> _createSupplierQuick() async {
    final created = await showDialog<PosSupplier>(
      context: context,
      builder: (_) => const PosSupplierFormDialog(),
    );
    if (created != null && mounted) {
      _refreshSuppliers();
    }
  }

  Future<List<PosPurchaseOrder>> _load() async {
    final repo = ref.read(posRepositoryProvider);
    return repo.listPurchases();
  }

  Widget _buildPurchasesList() {
    return FutureBuilder<List<PosPurchaseOrder>>(
      future: _load(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }

        final rows = snap.data ?? const [];
        if (rows.isEmpty) {
          return const Center(child: Text('No hay compras'));
        }

        return ListView.separated(
          itemCount: rows.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final p = rows[i];
            return ListTile(
              title: Text(p.supplierName.isEmpty ? '(Sin proveedor)' : p.supplierName),
              subtitle: Text(
                'Estado: ${p.status}  Total: ${money(p.total)}  Fecha: ${p.createdAt.toIso8601String().split('T').first}',
              ),
              onTap: () async {
                try {
                  final repo = ref.read(posRepositoryProvider);
                  final full = await repo.getPurchase(p.id);
                  if (!context.mounted) return;
                  await showDialog<void>(
                    context: context,
                    builder: (_) => _PurchaseDetailDialog(order: full),
                  );
                  if (context.mounted) setState(() {});
                } catch (e) {
                  _toast('Error cargando detalle: $e');
                }
              },
              trailing: Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () async {
                      try {
                        final repo = ref.read(posRepositoryProvider);
                        final full = await repo.getPurchase(p.id);
                        if (!context.mounted) return;
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PosPurchasePdfPreviewPage(order: full),
                          ),
                        );
                      } catch (e) {
                        _toast('Error abriendo PDF: $e');
                      }
                    },
                    child: const Text('PDF'),
                  ),
                  if (p.status != 'RECEIVED')
                    OutlinedButton(
                      onPressed: () async {
                        try {
                          final repo = ref.read(posRepositoryProvider);
                          await repo.receivePurchase(p.id);
                          if (!mounted) return;
                          setState(() {});
                        } catch (e) {
                          _toast('Error recibiendo: $e');
                        }
                      },
                      child: const Text('Recibir'),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ModulePage(
      title: 'POS / Compras',
      actions: [
        IconButton(
          tooltip: 'Proveedores',
          onPressed: () => context.go(AppRoutes.posSuppliers),
          icon: const Icon(Icons.business_outlined),
        ),
        IconButton(
          tooltip: 'Nueva orden de compra',
          onPressed: () async {
            final created = await showDialog<PosPurchaseOrder>(
              context: context,
              builder: (_) => const _CreatePurchaseDialog(),
            );
            if (created != null && mounted) setState(() {});
          },
          icon: const Icon(Icons.add_shopping_cart_outlined),
        ),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1050;
          if (!isWide) return _buildPurchasesList();

          return Row(
            children: [
              Expanded(child: _buildPurchasesList()),
              const VerticalDivider(width: 1),
              SizedBox(
                width: 360,
                child: _SuppliersPanel(
                  searchController: _supplierSearch,
                  suppliersFuture: _suppliersFuture,
                  onSearch: (q) {
                    _supplierQuery = q;
                    _refreshSuppliers();
                  },
                  onCreate: _createSupplierQuick,
                  onManage: () => context.go(AppRoutes.posSuppliers),
                  onRefresh: _refreshSuppliers,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SuppliersPanel extends StatelessWidget {
  const _SuppliersPanel({
    required this.searchController,
    required this.suppliersFuture,
    required this.onSearch,
    required this.onCreate,
    required this.onManage,
    required this.onRefresh,
  });

  final TextEditingController searchController;
  final Future<List<PosSupplier>>? suppliersFuture;
  final ValueChanged<String> onSearch;
  final VoidCallback onCreate;
  final VoidCallback onManage;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Proveedores', style: Theme.of(context).textTheme.titleMedium),
              ),
              IconButton(
                tooltip: 'Nuevo proveedor',
                onPressed: onCreate,
                icon: const Icon(Icons.add_business_outlined),
              ),
              IconButton(
                tooltip: 'Administrar',
                onPressed: onManage,
                icon: const Icon(Icons.open_in_new),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    isDense: true,
                    prefixIcon: Icon(Icons.search),
                    labelText: 'Buscar',
                  ),
                  onSubmitted: (v) => onSearch(v.trim()),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => onSearch(searchController.text.trim()),
                child: const Text('Buscar'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: FutureBuilder<List<PosSupplier>>(
              future: suppliersFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                final rows = snap.data ?? const [];
                if (rows.isEmpty) {
                  return const Center(child: Text('No hay proveedores'));
                }

                return ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final s = rows[i];
                    return ListTile(
                      dense: true,
                      title: Text(s.name),
                      subtitle: s.phone == null ? null : Text(s.phone!),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseDetailDialog extends StatelessWidget {
  final PosPurchaseOrder order;

  const _PurchaseDetailDialog({required this.order});

  @override
  Widget build(BuildContext context) {
    final totalItems = order.items.length;
    return AlertDialog(
      title: const Text('Orden de compra'),
      content: SizedBox(
        width: 920,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Proveedor: ${order.supplierName}'),
            Text('Estado: ${order.status}'),
            Text('Fecha: ${order.createdAt.toIso8601String()}'),
            const SizedBox(height: 10),
            Text('Ítems ($totalItems)', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            SizedBox(
              height: 320,
              child: totalItems == 0
                  ? const Center(child: Text('Sin ítems'))
                  : ListView.separated(
                      itemCount: totalItems,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final it = order.items[i];
                        return ListTile(
                          dense: true,
                          title: Text(it.productName),
                          // REMOVE "Costo" del detalle
                          subtitle: Text('Cant: ${it.qty.toStringAsFixed(2)}'),
                          trailing: Text(money(it.lineTotal)),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Total: ${money(order.total)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        OutlinedButton(
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => PosPurchasePdfPreviewPage(order: order)),
            );
          },
          child: const Text('Abrir PDF'),
        ),
      ],
    );
  }
}

class _CreatePurchaseDialog extends ConsumerStatefulWidget {
  const _CreatePurchaseDialog();

  @override
  ConsumerState<_CreatePurchaseDialog> createState() => _CreatePurchaseDialogState();
}

class _CreatePurchaseDialogState extends ConsumerState<_CreatePurchaseDialog> {
  final _supplier = TextEditingController();
  final _search = TextEditingController();

  PosSupplier? _selectedSupplier;

  List<PosProduct> _products = const [];
  bool _loadingProducts = false;

  bool _creating = false;
  _CreateMode _mode = _CreateMode.manual;

  final List<({PosProduct product, double qty, double unitCost})> _items = [];

  // NEW: estado fiscal/ITBIS (aquí es donde se usa)
  bool _isFiscalInvoice = false;
  bool _includeItbis = true;

  static const List<Map<String, String>> _ncfTypes = [
    {'code': 'B01', 'label': 'B01 - Crédito Fiscal'},
    {'code': 'B02', 'label': 'B02 - Consumidor Final'},
    {'code': 'B14', 'label': 'B14 - Régimen Especial'},
    {'code': 'B15', 'label': 'B15 - Gubernamental'},
  ];
  String _selectedNcfType = 'B02';

  static const double _itbisRate = 0.18;
  num _itbisIfIncluded(num itbis) => _includeItbis ? itbis : 0;

  Widget _moneyRow(BuildContext context, {required String label, required String value, bool strong = false}) {
    final t = Theme.of(context).textTheme;
    final labelStyle = strong ? t.titleMedium?.copyWith(fontWeight: FontWeight.w800) : t.bodyMedium;
    final valueStyle = strong ? t.titleMedium?.copyWith(fontWeight: FontWeight.w900) : t.bodyMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: labelStyle)),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }

  Widget _buildTotalsPanel(BuildContext context, {required num subTotal, required num itbis, required num total}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Totales', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),

            _moneyRow(context, label: 'Subtotal', value: money(subTotal)),

            Row(
              children: [
                const Expanded(child: Text('ITBIS')),
                Switch(
                  value: _includeItbis,
                  onChanged: (v) => setState(() => _includeItbis = v),
                ),
              ],
            ),
            _moneyRow(context, label: 'ITBIS', value: money(_itbisIfIncluded(itbis))),

            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),

            Row(
              children: [
                const Expanded(
                  child: Text('Factura fiscal', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                Switch(
                  value: _isFiscalInvoice,
                  onChanged: (v) => setState(() => _isFiscalInvoice = v),
                ),
              ],
            ),
            if (_isFiscalInvoice) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedNcfType,
                decoration: const InputDecoration(
                  labelText: 'Comprobante fiscal (NCF)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: _ncfTypes
                    .map((e) => DropdownMenuItem<String>(
                          value: e['code'],
                          child: Text(e['label'] ?? e['code'] ?? ''),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedNcfType = v ?? _selectedNcfType),
              ),
            ],

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _moneyRow(context, label: 'TOTAL', value: money(total), strong: true),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickSupplier() async {
    final selected = await showDialog<PosSupplier>(
      context: context,
      builder: (_) => const _SupplierSelectDialog(),
    );

    if (selected == null || !mounted) return;
    setState(() {
      _selectedSupplier = selected;
      _supplier.text = selected.name;
    });
  }

  Future<void> _createSupplierInline() async {
    final created = await showDialog<PosSupplier>(
      context: context,
      builder: (_) => const PosSupplierFormDialog(),
    );

    if (created == null || !mounted) return;
    setState(() {
      _selectedSupplier = created;
      _supplier.text = created.name;
    });
  }

  Future<void> _loadProducts() async {
    setState(() => _loadingProducts = true);
    try {
      final repo = ref.read(posRepositoryProvider);
      final products = await repo.listProducts(search: _search.text);
      if (!mounted) return;
      setState(() => _products = products);
    } catch (e) {
      _toast('Error cargando productos: $e');
    } finally {
      if (mounted) setState(() => _loadingProducts = false);
    }
  }

  Future<void> _loadAutomaticItems() async {
    setState(() => _loadingProducts = true);
    try {
      final repo = ref.read(posRepositoryProvider);
      final low = await repo.listProducts(lowStock: true);
      if (!mounted) return;

      final suggested = low
          .where((p) => p.suggestedReorderQty > 0)
          .map((p) => (product: p, qty: p.suggestedReorderQty, unitCost: p.costPrice))
          .toList();

      setState(() {
        _items
          ..clear()
          ..addAll(suggested);
      });

      if (suggested.isEmpty) {
        _toast('No hay productos con sugerencia de compra.');
      }
    } catch (e) {
      _toast('Error generando automático: $e');
    } finally {
      if (mounted) setState(() => _loadingProducts = false);
    }
  }

  bool get _canCreate => _selectedSupplier != null && _items.isNotEmpty && !_creating;

  // FIX: faltaba este método (se usa muchas veces en este State)
  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // FIX: liberar controllers del dialog
  @override
  void dispose() {
    _supplier.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // NEW: totales reales (y sin variables fantasma)
    final num subTotal = _items.fold<num>(0, (sum, it) => sum + (it.qty * it.unitCost));
    final num itbis = subTotal * _itbisRate;
    final num total = subTotal + _itbisIfIncluded(itbis);

    return AlertDialog(
      title: const Text('Nueva orden de compra'),
      content: SizedBox(
        width: 820,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _supplier,
                    readOnly: true,
                    onTap: _pickSupplier,
                    decoration: const InputDecoration(
                      labelText: 'Proveedor *',
                      isDense: true,
                      prefixIcon: Icon(Icons.business_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _pickSupplier,
                  child: const Text('Seleccionar'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _createSupplierInline,
                  child: const Text('Crear'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<_CreateMode>(
                    segments: const [
                      ButtonSegment(value: _CreateMode.manual, label: Text('Manual')),
                      ButtonSegment(value: _CreateMode.automatic, label: Text('Automático')),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (s) {
                      setState(() => _mode = s.first);
                      if (s.first == _CreateMode.automatic) {
                        _loadAutomaticItems();
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    decoration: const InputDecoration(
                      labelText: 'Buscar producto',
                      isDense: true,
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _loadProducts(),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _loadingProducts ? null : _loadProducts,
                  child: const Text('Buscar'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 240,
              child: _loadingProducts
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      itemCount: _products.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final p = _products[i];
                        return ListTile(
                          dense: true,
                          title: Text(p.nombre),
                          // REMOVE "Costo" del listado (más limpio / más pro)
                          subtitle: Text('Stock: ${p.stockQty.toStringAsFixed(2)}'),
                          trailing: OutlinedButton(
                            onPressed: () async {
                              if (_mode == _CreateMode.automatic) {
                                _toast('En modo Automático, edita ítems sugeridos abajo.');
                                return;
                              }
                              final res = await showDialog<_PurchaseLine>(
                                context: context,
                                builder: (_) => _AddPurchaseLineDialog(product: p),
                              );
                              if (res == null) return;
                              setState(() {
                                _items.add((product: p, qty: res.qty, unitCost: res.unitCost));
                              });
                            },
                            child: const Text('Agregar'),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Ítems (${_items.length})', style: Theme.of(context).textTheme.titleSmall),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 220,
              child: _items.isEmpty
                  ? const Center(child: Text('Sin ítems'))
                  : ListView.separated(
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final it = _items[i];
                        return ListTile(
                          dense: true,
                          title: Text(it.product.nombre),
                          // REMOVE "Costo" del resumen del ítem
                          subtitle: Text('Cant: ${it.qty.toStringAsFixed(2)}  Total: ${money(it.qty * it.unitCost)}'),
                          trailing: IconButton(
                            tooltip: 'Quitar',
                            onPressed: () => setState(() => _items.removeAt(i)),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 10),

            // REPLACE: panel viejo de Factura fiscal + ITBIS + filas sueltas por panel profesional
            _buildTotalsPanel(context, subTotal: subTotal, itbis: itbis, total: total),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: !_canCreate
              ? null
              : () async {
                  final supplier = _selectedSupplier;
                  if (supplier == null) {
                    _toast('Debes seleccionar o crear el proveedor.');
                    return;
                  }
                  if (_items.isEmpty) {
                    _toast('Agrega al menos un producto.');
                    return;
                  }

                  try {
                    setState(() => _creating = true);
                    final repo = ref.read(posRepositoryProvider);

                    final created = await repo.createPurchase(
                      supplierId: supplier.id,
                      supplierName: supplier.name,
                      items: _items,
                      // Nota: si luego quieres guardar fiscal/NCF/itbis en backend,
                      // habría que ampliar el método y el modelo.
                    );

                    if (!context.mounted) return;
                    Navigator.pop(context, created);
                  } catch (e) {
                    _toast('Error creando compra: $e');
                  } finally {
                    if (mounted) setState(() => _creating = false);
                  }
                },
          child: Text(_creating ? 'Creando...' : 'Crear'),
        ),
      ],
    );
  }
}

class _SupplierSelectDialog extends ConsumerStatefulWidget {
  const _SupplierSelectDialog();

  @override
  ConsumerState<_SupplierSelectDialog> createState() => _SupplierSelectDialogState();
}

class _SupplierSelectDialogState extends ConsumerState<_SupplierSelectDialog> {
  final _search = TextEditingController();
  Future<List<PosSupplier>>? _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _refresh() {
    final repo = ref.read(posRepositoryProvider);
    setState(() {
      _future = repo.listSuppliers(search: _query);
    });
  }

  Future<void> _createAndSelect() async {
    final created = await showDialog<PosSupplier>(
      context: context,
      builder: (_) => const PosSupplierFormDialog(),
    );
    if (!mounted) return;
    if (created != null) {
      Navigator.pop(context, created);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seleccionar proveedor'),
      content: SizedBox(
        width: 640,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    decoration: const InputDecoration(
                      isDense: true,
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Buscar',
                    ),
                    onSubmitted: (v) {
                      _query = v.trim();
                      _refresh();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    _query = _search.text.trim();
                    _refresh();
                  },
                  child: const Text('Buscar'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _createAndSelect,
                  child: const Text('Crear'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 360,
              child: FutureBuilder<List<PosSupplier>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Error: ${snap.error}'));
                  }
                  final rows = snap.data ?? const [];
                  if (rows.isEmpty) {
                    return const Center(child: Text('No hay proveedores'));
                  }
                  return ListView.separated(
                    itemCount: rows.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final s = rows[i];
                      return ListTile(
                        title: Text(s.name),
                        subtitle: s.phone == null ? null : Text(s.phone!),
                        onTap: () => Navigator.pop(context, s),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
      ],
    );
  }
}

enum _CreateMode { manual, automatic }

class _PurchaseLine {
  final double qty;
  final double unitCost;

  const _PurchaseLine({required this.qty, required this.unitCost});
}

class _AddPurchaseLineDialog extends StatefulWidget {
  final PosProduct product;

  const _AddPurchaseLineDialog({required this.product});

  @override
  State<_AddPurchaseLineDialog> createState() => _AddPurchaseLineDialogState();
}

class _AddPurchaseLineDialogState extends State<_AddPurchaseLineDialog> {
  late final TextEditingController _qty;
  late final TextEditingController _cost;

  @override
  void initState() {
    super.initState();
    _qty = TextEditingController(text: '1');
    _cost = TextEditingController(text: widget.product.costPrice.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _qty.dispose();
    _cost.dispose();
    super.dispose();
  }

  double _parse(String s) => double.tryParse(s.replaceAll(',', '.')) ?? 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product.nombre),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _qty,
              decoration: const InputDecoration(labelText: 'Cantidad', isDense: true),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _cost,
              decoration: const InputDecoration(labelText: 'Costo unitario', isDense: true),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            final qty = _parse(_qty.text);
            final cost = _parse(_cost.text);
            if (qty <= 0) return;
            Navigator.pop(context, _PurchaseLine(qty: qty, unitCost: cost < 0 ? 0 : cost));
          },
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}
