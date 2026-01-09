import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/app_config.dart';
import '../../../../core/widgets/module_page.dart';
import '../../../../features/auth/state/auth_providers.dart';
import '../../../../features/auth/state/auth_state.dart';
import '../../../../features/catalogo/models/producto.dart';
import '../../../../features/presupuesto/state/presupuesto_catalog_controller.dart';
import '../../../../features/presupuesto/state/presupuesto_catalog_state.dart';
import '../../models/pos_models.dart';
import '../../state/pos_providers.dart';
import '../../state/pos_tpv_controller.dart';
import 'pos_invoice_viewer_screen.dart';
import '../widgets/pos_invoice_pdf.dart';
import '../../../../core/widgets/catalog_product_grid_card.dart';

class PosTpvPage extends ConsumerStatefulWidget {
  const PosTpvPage({super.key});

  @override
  ConsumerState<PosTpvPage> createState() => _PosTpvPageState();
}

class _PosTpvPageState extends ConsumerState<PosTpvPage> {
  final _searchCtrl = TextEditingController();
  late final ScrollController _productsScroll;

  @override
  void initState() {
    super.initState();
    _productsScroll = ScrollController();

    // Initialize catalog data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(presupuestoCatalogControllerProvider.notifier).bootstrap();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sync search controller with catalog state
    final catalogState = ref.read(presupuestoCatalogControllerProvider);
    if (_searchCtrl.text != catalogState.query) {
      _searchCtrl.text = catalogState.query;
    }
  }

  // Convert Producto (catalog) to PosProduct for TPV compatibility
  PosProduct _convertToTPVProduct(Producto producto) {
    return PosProduct(
      id: producto.id,
      nombre: producto.nombre,
      precioVenta: producto.precioVenta,
      costPrice: producto.precioCompra,
      stockQty: 0, // Default values since catalog doesn't have stock info
      minStock: 0,
      maxStock: 0,
      allowNegativeStock: true,
      lowStock: false,
      suggestedReorderQty: 0,
      categoria: producto.categoria != null
          ? PosCategory(
              id: producto.categoria!.id,
              nombre: producto.categoria!.nombre,
            )
          : null,
      imagenUrl: producto.imagenUrl.isEmpty ? null : producto.imagenUrl,
    );
  }

  @override
  void dispose() {
    _productsScroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(posTpvControllerProvider);
    final ctrl = ref.read(posTpvControllerProvider.notifier);

    final auth = ref.watch(authControllerProvider);
    final role = auth is AuthAuthenticated ? auth.user.role : 'unknown';
    final canSeeCost = role == 'admin' || role == 'administrador';

    return ModulePage(
      title: '',
      actions: const [],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 980;
          if (isDesktop) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _PosCatalogPane(
                    productsScroll: _productsScroll,
                    searchCtrl: _searchCtrl,
                    onBarcode: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Escaner: pendiente integracion'),
                        ),
                      );
                    },
                    onFilters: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Filtros: pendiente')),
                      );
                    },
                    onAddProduct: (producto) =>
                        ctrl.addProduct(_convertToTPVProduct(producto)),
                    canSeeCost: canSeeCost,
                    onOpenVentas: () => context.go(AppRoutes.ventas),
                    onOpenDevoluciones: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Devoluciones: pendiente de implementación',
                          ),
                        ),
                      );
                    },
                    onPrintLastTicket: () => _printLastTicket(context, state),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 540,
                  child: Material(
                    color: Theme.of(context).colorScheme.surface,
                    elevation: 3,
                    borderRadius: BorderRadius.circular(16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _PosSalePane(
                        state: state,
                        canSeeCost: canSeeCost,
                        onPickCustomer: () => _pickCustomer(context, ctrl),
                        onAddManual: () async {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Agregar manual: pendiente (requiere soporte backend)',
                              ),
                            ),
                          );
                        },
                        onEditLine: (line) => _editLine(context, ctrl, line),
                        onCheckout: () => _checkout(context, ref, state, ctrl),
                        onOpenInvoice: () => _openLastInvoice(context, state),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                flex: 5,
                child: _PosCatalogPane(
                  productsScroll: _productsScroll,
                  searchCtrl: _searchCtrl,
                  onBarcode: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Escaner: pendiente integracion'),
                      ),
                    );
                  },
                  onFilters: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Filtros: pendiente')),
                    );
                  },
                  onAddProduct: (producto) =>
                      ctrl.addProduct(_convertToTPVProduct(producto)),
                  canSeeCost: canSeeCost,
                  onOpenVentas: () => context.go(AppRoutes.ventas),
                  onOpenDevoluciones: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Devoluciones: pendiente de implementación',
                        ),
                      ),
                    );
                  },
                  onPrintLastTicket: () => _printLastTicket(context, state),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 560,
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  elevation: 3,
                  borderRadius: BorderRadius.circular(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _PosSalePane(
                      state: state,
                      canSeeCost: canSeeCost,
                      onPickCustomer: () => _pickCustomer(context, ctrl),
                      onAddManual: () async {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Agregar manual: pendiente (requiere soporte backend)',
                            ),
                          ),
                        );
                      },
                      onEditLine: (line) => _editLine(context, ctrl, line),
                      onCheckout: () => _checkout(context, ref, state, ctrl),
                      onOpenInvoice: () => _openLastInvoice(context, state),
                    ),
                  ),
                ),
              ),
              if (state.error != null) ...[
                const SizedBox(height: 8),
                Text(
                  state.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickCustomer(
    BuildContext context,
    PosTpvController ctrl,
  ) async {
    final st = ref.read(posTpvControllerProvider);
    final ticket = st.activeTicket;
    final nameCtrl = TextEditingController(text: ticket.customerName ?? '');
    final rncCtrl = TextEditingController(text: ticket.customerRnc ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cliente'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
                autofocus: true,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: rncCtrl,
                decoration: const InputDecoration(labelText: 'RNC (opcional)'),
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
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    ctrl.setCustomer(
      customerId: null,
      name: nameCtrl.text.trim(),
      rnc: rncCtrl.text.trim(),
    );
  }

  Future<void> _editLine(
    BuildContext context,
    PosTpvController ctrl,
    PosSaleItemDraft line,
  ) async {
    final res = await showDialog<PosSaleItemDraft>(
      context: context,
      builder: (_) => _EditLineDialog(line: line),
    );
    if (res == null) return;
    ctrl.updateLine(line, res);
  }

  Future<void> _checkout(
    BuildContext context,
    WidgetRef ref,
    PosTpvState state,
    PosTpvController ctrl,
  ) async {
    final ticket = state.activeTicket;
    if (ticket.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega productos antes de cobrar')),
      );
      return;
    }

    double clamp0(double v) => v < 0 ? 0 : v;
    final grossSubtotal = ticket.subtotal;
    final discountTotal = ticket.lineDiscounts + ticket.globalDiscount;
    final base = clamp0(grossSubtotal - discountTotal);
    final itbis = base * 0.18;
    final total = base + itbis;

    final res = await showDialog<_CheckoutResult>(
      context: context,
      builder: (_) =>
          _CheckoutDialog(invoiceType: ticket.invoiceType, total: total),
    );
    if (res == null) return;

    try {
      final sale = await ctrl.checkout(
        paymentMethod: res.paymentMethod,
        paidAmount:
            (res.paymentMethod == 'CREDIT' || res.paymentMethod == 'CASH')
            ? 0
            : total,
        receivedAmount:
            res.receivedAmount ?? (res.paymentMethod == 'CASH' ? total : null),
        dueDate: res.dueDate,
        initialPayment: res.initialPayment,
        docType: res.docType,
      );

      if (!context.mounted) return;
      if (sale == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Venta guardada offline. Se sincronizará al volver internet.',
            ),
          ),
        );
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PosInvoiceViewerScreen(sale: sale),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error cobrando: $e')));
    }
  }

  Future<void> _printLastTicket(BuildContext context, PosTpvState state) async {
    final sale = state.lastPaidSale;
    if (sale == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay un ticket reciente para imprimir'),
        ),
      );
      return;
    }

    try {
      final bytes = await buildPosInvoicePdf(sale);
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: sale.invoiceNo.trim().isEmpty ? 'Ticket' : sale.invoiceNo.trim(),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo imprimir: $e')));
    }
  }

  Future<void> _openLastInvoice(BuildContext context, PosTpvState state) async {
    final sale = state.lastPaidSale;
    if (sale == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay una factura reciente')),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PosInvoiceViewerScreen(sale: sale),
      ),
    );
  }
}

class _PosCatalogPane extends ConsumerWidget {
  final ScrollController productsScroll;
  final TextEditingController searchCtrl;
  final VoidCallback onBarcode;
  final VoidCallback onFilters;
  final ValueChanged<Producto> onAddProduct;
  final bool canSeeCost;
  final VoidCallback onOpenVentas;
  final VoidCallback onOpenDevoluciones;
  final VoidCallback onPrintLastTicket;

  const _PosCatalogPane({
    required this.productsScroll,
    required this.searchCtrl,
    required this.onBarcode,
    required this.onFilters,
    required this.onAddProduct,
    required this.canSeeCost,
    required this.onOpenVentas,
    required this.onOpenDevoluciones,
    required this.onPrintLastTicket,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(posTpvControllerProvider);
    final catalogSt = ref.watch(presupuestoCatalogControllerProvider);
    final catalogCtrl = ref.read(presupuestoCatalogControllerProvider.notifier);

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final allSelected =
        catalogSt.selectedCategoriaId == null ||
        catalogSt.selectedCategoriaId!.trim().isEmpty;
    final categorias = catalogSt.categorias;

    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 1400
        ? 7
        : (width >= 1200
              ? 6
              : (width >= 980
                    ? 5
                    : (width >= 760 ? 4 : (width >= 520 ? 3 : 2))));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (st.loading) const LinearProgressIndicator(),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchCtrl,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'Buscar producto',
                    isDense: true,
                  ),
                  onChanged: catalogCtrl.setQuery,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Escanear',
                onPressed: onBarcode,
                icon: const Icon(Icons.qr_code_scanner),
              ),
              IconButton(
                tooltip: 'Filtros',
                onPressed: onFilters,
                icon: const Icon(Icons.tune),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: const Text('TODAS'),
                  selected: allSelected,
                  backgroundColor: cs.primaryContainer,
                  selectedColor: cs.primary,
                  side: BorderSide(
                    color: (allSelected ? cs.onPrimary : cs.onPrimaryContainer)
                        .withValues(alpha: 0.35),
                  ),
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    color: allSelected ? cs.onPrimary : cs.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                  onSelected: (_) => catalogCtrl.setCategoria(null),
                ),
              ),
              for (final c in categorias)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(c.nombre.toUpperCase()),
                    selected: catalogSt.selectedCategoriaId == c.id,
                    backgroundColor: cs.primaryContainer,
                    selectedColor: cs.primary,
                    side: BorderSide(
                      color:
                          (catalogSt.selectedCategoriaId == c.id
                                  ? cs.onPrimary
                                  : cs.onPrimaryContainer)
                              .withValues(alpha: 0.35),
                    ),
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      color: catalogSt.selectedCategoriaId == c.id
                          ? cs.onPrimary
                          : cs.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                    onSelected: (_) => catalogCtrl.setCategoria(c.id),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _buildProductsContent(
            context,
            catalogSt,
            crossAxisCount,
            canSeeCost,
            onAddProduct,
            catalogCtrl,
            productsScroll,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: onOpenVentas,
                icon: const Icon(Icons.point_of_sale_outlined),
                label: const Text('Ventas'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: onOpenDevoluciones,
                icon: const Icon(Icons.assignment_return_outlined),
                label: const Text('Devoluciones'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPrintLastTicket,
                icon: const Icon(Icons.print_outlined),
                label: const Text('Imprimir último ticket'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProductsContent(
    BuildContext context,
    PresupuestoCatalogState st,
    int crossAxisCount,
    bool canSeeCost,
    ValueChanged<Producto> onAddProduct,
    PresupuestoCatalogController ctrl,
    ScrollController productsScroll,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final money0 = NumberFormat('#,##0', 'en_US');

    // Show loading state
    if (st.isLoading && st.productos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando productos...'),
          ],
        ),
      );
    }

    // Show error state
    if (st.error != null && st.productos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: cs.error),
            const SizedBox(height: 16),
            Text(
              'Error cargando productos',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              st.error!,
              style: theme.textTheme.bodyMedium?.copyWith(color: cs.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => ctrl.refreshProductos(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    // Show empty state
    if (st.productos.isEmpty) {
      final hasFilters =
          st.query.trim().isNotEmpty ||
          (st.selectedCategoriaId != null &&
              st.selectedCategoriaId!.trim().isNotEmpty);
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFilters ? Icons.search_off : Icons.inventory_2_outlined,
              size: 48,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters
                  ? 'No se encontraron productos'
                  : 'No hay productos disponibles',
              style: theme.textTheme.titleMedium,
            ),
            if (hasFilters) ...[
              const SizedBox(height: 8),
              Text(
                'Intenta modificar los filtros de búsqueda',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  ctrl.setQuery('');
                  ctrl.setCategoria(null);
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Limpiar filtros'),
              ),
            ],
          ],
        ),
      );
    }

    // Show products grid with loading overlay if refreshing
    return Stack(
      children: [
        GridView.builder(
          controller: productsScroll,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.95,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: st.productos.length,
          itemBuilder: (context, i) {
            final p = st.productos[i];
            final priceText = money0.format(p.precioVenta.round());
            final costText = money0.format(p.precioCompra.round());

            return CatalogProductGridCard(
              nombre: p.nombre,
              priceText: priceText,
              costText: costText,
              canSeeCost: canSeeCost,
              imageRaw: p.imagenUrl,
              onTap: () => onAddProduct(p),
            );
          },
        ),
        // Loading overlay when refreshing with existing products
        if (st.isLoading && st.productos.isNotEmpty)
          Positioned.fill(
            child: Container(
              color: cs.surface.withValues(alpha: 0.7),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}

class _PosSalePane extends ConsumerWidget {
  final PosTpvState state;
  final bool canSeeCost;
  final VoidCallback onPickCustomer;
  final Future<void> Function() onAddManual;
  final Future<void> Function(PosSaleItemDraft line) onEditLine;
  final Future<void> Function() onCheckout;
  final Future<void> Function() onOpenInvoice;

  const _PosSalePane({
    required this.state,
    required this.canSeeCost,
    required this.onPickCustomer,
    required this.onAddManual,
    required this.onEditLine,
    required this.onCheckout,
    required this.onOpenInvoice,
  });

  Future<void> _renameTicket(
    BuildContext context,
    WidgetRef ref,
    PosTicket ticket,
  ) async {
    final ctrl = TextEditingController(text: ticket.name);
    final next = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Renombrar ticket'),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: ctrl,
            decoration: const InputDecoration(labelText: 'Nombre'),
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(ctrl.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (next == null) return;
    ref.read(posTpvControllerProvider.notifier).renameTicket(ticket.id, next);
  }

  String _publicUrlFromMaybeRelative(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return '';
    if (v.startsWith('http://') || v.startsWith('https://')) return v;
    final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/api$'), '');
    if (v.startsWith('/')) return '$base$v';
    return '$base/$v';
  }

  String? _imageUrlFor(PosSaleItemDraft it) {
    final raw = (it.product.imagenUrl ?? '').trim();
    if (raw.isEmpty) return null;
    return _publicUrlFromMaybeRelative(raw);
  }

  Widget _itemCard({
    required BuildContext context,
    required PosSaleItemDraft it,
    required bool canSeeCost,
    required String? imageUrl,
    required Future<void> Function() onEdit,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final hasDiscount = it.discountAmount > 0;
    final discountLabel = '-${it.discountAmount.toStringAsFixed(2)}';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 34,
                height: 34,
                child: ClipOval(
                  child: (imageUrl != null && imageUrl.trim().isNotEmpty)
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: cs.surfaceContainerHighest,
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 18,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        )
                      : Container(
                          color: cs.surfaceContainerHighest,
                          child: Icon(
                            Icons.photo_outlined,
                            size: 18,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            it.product.nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (hasDiscount)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: cs.tertiaryContainer,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              discountLabel,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: cs.onTertiaryContainer,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'P: ${it.unitPrice.toStringAsFixed(2)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (canSeeCost) ...[
                          const SizedBox(width: 10),
                          Text(
                            'C: ${it.product.costPrice.toStringAsFixed(2)}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.error,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                        const SizedBox(width: 10),
                        Text(
                          'x${it.qty.toStringAsFixed(0)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                (it.lineSubtotal < 0 ? 0 : it.lineSubtotal).toStringAsFixed(2),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final ticket = state.activeTicket;

    double clamp0(double v) => v < 0 ? 0 : v;
    final grossSubtotal = ticket.subtotal;
    final discountTotal = ticket.lineDiscounts + ticket.globalDiscount;
    final base = clamp0(grossSubtotal - discountTotal);
    final itbis = base * 0.18;
    final total = base + itbis;

    final totalsLabelStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w800,
    );
    final totalsValueStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w900,
    );
    final totalLabelStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w900,
      letterSpacing: 0.2,
    );
    final totalValueStyle = theme.textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w900,
      color: cs.primary,
      letterSpacing: 0.2,
    );

    return LayoutBuilder(
      builder: (context, pane) {
        final paneH = pane.maxHeight;
        final paneTightH = paneH.isFinite && paneH < 620;
        final paneUltraTightH = paneH.isFinite && paneH < 520;

        final content = Column(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    cs.surface.withValues(alpha: 0.9),
                    cs.surface.withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'TPV',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Agregar ticket',
                          onPressed: () => ref
                              .read(posTpvControllerProvider.notifier)
                              .addTicket(),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    SizedBox(height: paneUltraTightH ? 6 : 8),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: state.tickets.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final t = state.tickets[i];
                          final selected = t.id == state.activeTicketId;
                          return GestureDetector(
                            onLongPress: () => _renameTicket(context, ref, t),
                            child: InputChip(
                              label: Text(
                                t.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              showCheckmark: false,
                              selected: selected,
                              backgroundColor: cs.surfaceContainerHighest,
                              selectedColor: cs.primary,
                              side: BorderSide(
                                color:
                                    (selected ? cs.primary : cs.outlineVariant)
                                        .withValues(alpha: 0.5),
                              ),
                              labelStyle: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: selected ? cs.onPrimary : cs.onSurface,
                              ),
                              onPressed: () => ref
                                  .read(posTpvControllerProvider.notifier)
                                  .selectTicket(t.id),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: paneUltraTightH ? 6 : 10),
                    LayoutBuilder(
                      builder: (context, c) {
                        final isCompact = c.maxWidth < 420;
                        final tightH = paneTightH;
                        final ultraTightH = paneUltraTightH;

                        final minH = ultraTightH
                            ? 52.0
                            : (isCompact ? 60.0 : 68.0);
                        final padV = ultraTightH ? 6.0 : (tightH ? 8.0 : 10.0);
                        final avatarSize = ultraTightH
                            ? 28.0
                            : (tightH ? 30.0 : 34.0);
                        final labelFontSize = ultraTightH ? 11.0 : 12.0;
                        final nameFontSize = ultraTightH ? 14.0 : 16.0;

                        final customerName = (ticket.customerName ?? '').trim();
                        final hasCustomer = customerName.isNotEmpty;

                        final maxNameLines =
                            (!isCompact && !ultraTightH && c.maxWidth >= 520)
                            ? 2
                            : 1;
                        final showItemsText = !isCompact && c.maxWidth >= 460;

                        return ConstrainedBox(
                          constraints: BoxConstraints(minHeight: minH),
                          child: Material(
                            color: cs.primary,
                            elevation: 4,
                            shadowColor: cs.shadow.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: onPickCustomer,
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: padV,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: avatarSize,
                                      height: avatarSize,
                                      decoration: BoxDecoration(
                                        color: cs.onPrimary.withValues(
                                          alpha: 0.18,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.person,
                                        size: ultraTightH ? 18 : 20,
                                        color: cs.onPrimary.withValues(
                                          alpha: 0.95,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Cliente',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  fontSize: labelFontSize,
                                                  fontWeight: FontWeight.w600,
                                                  color: cs.onPrimary
                                                      .withValues(alpha: 0.85),
                                                ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            hasCustomer
                                                ? customerName
                                                : 'Seleccionar cliente',
                                            maxLines: maxNameLines,
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: false,
                                            style: theme.textTheme.bodyLarge
                                                ?.copyWith(
                                                  fontSize: nameFontSize,
                                                  fontWeight: FontWeight.w700,
                                                  height: 1.1,
                                                  color: cs.onPrimary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: showItemsText ? 130 : 44,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          if (showItemsText) ...[
                                            Flexible(
                                              child: Text(
                                                'Items: ${ticket.items.length}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.right,
                                                style: theme
                                                    .textTheme
                                                    .labelMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: cs.onPrimary
                                                          .withValues(
                                                            alpha: 0.95,
                                                          ),
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                          ],
                                          IconButton(
                                            tooltip: hasCustomer
                                                ? 'Cambiar cliente'
                                                : 'Seleccionar cliente',
                                            onPressed: onPickCustomer,
                                            visualDensity:
                                                VisualDensity.compact,
                                            padding: EdgeInsets.zero,
                                            constraints:
                                                const BoxConstraints.tightFor(
                                                  width: 36,
                                                  height: 36,
                                                ),
                                            icon: Icon(
                                              Icons.person_add_alt_1,
                                              size: ultraTightH ? 18 : 20,
                                              color: cs.onPrimary,
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
                        );
                      },
                    ),
                    SizedBox(height: paneUltraTightH ? 6 : 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onAddManual,
                            icon: const Icon(Icons.playlist_add),
                            label: const Text('Agregar manual'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                children: [
                  if (ticket.items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Agrega productos desde el catálogo'),
                    )
                  else ...[
                    Text(
                      'Catálogo',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final it in ticket.items)
                      _itemCard(
                        context: context,
                        it: it,
                        canSeeCost: canSeeCost,
                        imageUrl: _imageUrlFor(it),
                        onEdit: () => onEditLine(it),
                      ),
                  ],
                  if (state.error != null) ...[
                    const SizedBox(height: 8),
                    Text(state.error!, style: TextStyle(color: cs.error)),
                  ],
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                12,
                paneUltraTightH ? 8 : 10,
                12,
                paneUltraTightH ? 10 : 12,
              ),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(top: BorderSide(color: cs.outlineVariant)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: true,
                          onChanged: null,
                          title: Text('ITBIS'),
                          dense: true,
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: TextFormField(
                          initialValue: '18',
                          enabled: false,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            suffixText: '%',
                            isDense: true,
                          ),
                          onFieldSubmitted: (_) {},
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: paneUltraTightH ? 6 : 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Subtotal', style: totalsLabelStyle),
                      Text(
                        grossSubtotal.toStringAsFixed(2),
                        style: totalsValueStyle,
                      ),
                    ],
                  ),
                  SizedBox(height: paneUltraTightH ? 4 : 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Descuento', style: totalsLabelStyle),
                      Text(
                        discountTotal.toStringAsFixed(2),
                        style: totalsValueStyle,
                      ),
                    ],
                  ),
                  SizedBox(height: paneUltraTightH ? 4 : 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('ITBIS monto', style: totalsLabelStyle),
                      Text(itbis.toStringAsFixed(2), style: totalsValueStyle),
                    ],
                  ),
                  SizedBox(height: paneUltraTightH ? 6 : 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: totalLabelStyle),
                      Text(total.toStringAsFixed(2), style: totalValueStyle),
                    ],
                  ),
                  if (canSeeCost)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Costo visible (admin)',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  SizedBox(height: paneUltraTightH ? 12 : 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: cs.outline.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: const Divider(),
                  ),
                  SizedBox(height: paneUltraTightH ? 12 : 16),
                  Container(
                    width: double.infinity,
                    height: paneUltraTightH ? 52 : 58,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: FilledButton.icon(
                      onPressed: ticket.items.isEmpty ? null : onCheckout,
                      icon: const Icon(Icons.point_of_sale_outlined, size: 24),
                      label: Text(
                        'COBRAR',
                        style: TextStyle(
                          fontSize: paneUltraTightH ? 16 : 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        return Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: cs.outline.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: content,
          ),
        );
      },
    );
  }
}

class _EditLineDialog extends StatefulWidget {
  final PosSaleItemDraft line;

  const _EditLineDialog({required this.line});

  @override
  State<_EditLineDialog> createState() => _EditLineDialogState();
}

class _EditLineDialogState extends State<_EditLineDialog> {
  late final TextEditingController _qty;
  late final TextEditingController _price;
  late final TextEditingController _disc;

  @override
  void initState() {
    super.initState();
    _qty = TextEditingController(text: widget.line.qty.toStringAsFixed(2));
    _price = TextEditingController(
      text: widget.line.unitPrice.toStringAsFixed(2),
    );
    _disc = TextEditingController(
      text: widget.line.discountAmount.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _qty.dispose();
    _price.dispose();
    _disc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.line.product.nombre),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _qty,
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                isDense: true,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _price,
              decoration: const InputDecoration(
                labelText: 'Precio unitario',
                isDense: true,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _disc,
              decoration: const InputDecoration(
                labelText: 'Descuento línea',
                isDense: true,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            double parse(String s) =>
                double.tryParse(s.replaceAll(',', '.')) ?? 0;

            final qty = parse(_qty.text);
            final price = parse(_price.text);
            final disc = parse(_disc.text);

            if (qty <= 0) return;
            Navigator.pop(
              context,
              widget.line.copyWith(
                qty: qty,
                unitPrice: price < 0 ? 0 : price,
                discountAmount: disc < 0 ? 0 : disc,
              ),
            );
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _CheckoutResult {
  final String paymentMethod;
  final double? receivedAmount;
  final DateTime? dueDate;
  final double initialPayment;
  final String? docType;

  const _CheckoutResult({
    required this.paymentMethod,
    required this.receivedAmount,
    required this.dueDate,
    required this.initialPayment,
    required this.docType,
  });
}

class _CheckoutDialog extends StatefulWidget {
  final String invoiceType;
  final double total;

  const _CheckoutDialog({required this.invoiceType, required this.total});

  @override
  State<_CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<_CheckoutDialog> {
  String _payment = 'CASH';
  final _received = TextEditingController();
  final _initialPayment = TextEditingController();
  final _docType = TextEditingController(text: 'B02');
  DateTime? _dueDate;

  @override
  void dispose() {
    _received.dispose();
    _initialPayment.dispose();
    _docType.dispose();
    super.dispose();
  }

  double _parse(String s) => double.tryParse(s.replaceAll(',', '.')) ?? 0;

  String money(double value) => NumberFormat('#,##0.00', 'en_US').format(value);

  @override
  Widget build(BuildContext context) {
    final isCredit = _payment == 'CREDIT';
    final isCash = _payment == 'CASH';
    final needsDocType = widget.invoiceType == 'FISCAL';

    return AlertDialog(
      title: const Text('Cobrar'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Total: ${money(widget.total)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _payment,
              items: const [
                DropdownMenuItem(value: 'CASH', child: Text('Efectivo')),
                DropdownMenuItem(value: 'CARD', child: Text('Tarjeta')),
                DropdownMenuItem(
                  value: 'TRANSFER',
                  child: Text('Transferencia'),
                ),
                DropdownMenuItem(value: 'CREDIT', child: Text('Crédito')),
              ],
              onChanged: (v) => setState(() => _payment = v ?? 'CASH'),
              decoration: const InputDecoration(
                labelText: 'Método de pago',
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            if (isCash)
              TextField(
                controller: _received,
                decoration: const InputDecoration(
                  labelText: 'Recibido',
                  isDense: true,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            if (isCredit) ...[
              TextField(
                controller: _initialPayment,
                decoration: const InputDecoration(
                  labelText: 'Abono inicial',
                  isDense: true,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (picked != null) setState(() => _dueDate = picked);
                },
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  _dueDate == null
                      ? 'Seleccionar vencimiento'
                      : 'Vence: ${_dueDate!.toIso8601String().substring(0, 10)}',
                ),
              ),
            ],
            if (needsDocType) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _docType,
                decoration: const InputDecoration(
                  labelText: 'Doc type (NCF)',
                  isDense: true,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (needsDocType && _docType.text.trim().isEmpty) return;

            final received = isCash ? _parse(_received.text) : null;
            final initPay = isCredit ? _parse(_initialPayment.text) : 0.0;

            Navigator.pop(
              context,
              _CheckoutResult(
                paymentMethod: _payment,
                receivedAmount: received,
                dueDate: _dueDate,
                initialPayment: initPay,
                docType: needsDocType ? _docType.text.trim() : null,
              ),
            );
          },
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
