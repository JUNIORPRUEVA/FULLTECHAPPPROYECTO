import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/app_config.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/module_page.dart';
import '../../../core/widgets/adaptive_image.dart';
import '../../../core/widgets/catalog_product_grid_card.dart';
import '../../auth/state/auth_providers.dart';
import '../../auth/state/auth_state.dart';
import '../../catalogo/models/producto.dart';
import '../../configuracion/state/company_profile_providers.dart';
import '../../crm/data/models/crm_thread.dart';
import '../models/quotation_models.dart';
import '../services/quotation_pdf_service.dart';
import '../state/presupuesto_catalog_controller.dart';
import '../state/quotation_builder_controller.dart';
import '../state/quotation_builder_state.dart';
import '../widgets/crm_chat_picker_dialog.dart';
import '../widgets/manual_item_dialog.dart';
import '../widgets/presupuesto_filters_dialog.dart';
import '../widgets/quotation_item_edit_dialog.dart';
import 'quotation_pdf_viewer_screen.dart';

String _digitsOnly(String raw) => raw.replaceAll(RegExp(r'[^0-9]'), '');

String? _normalizeWhatsAppPhone(String? raw) {
  if (raw == null) return null;
  final digits = _digitsOnly(raw.trim());
  if (digits.isEmpty) return null;
  if (digits.length == 10) return '1$digits';
  if (digits.length >= 11) return digits;
  return null;
}

Future<bool> _openWhatsAppChat(String phoneDigits, String message) async {
  final uri = Uri.parse(
    'https://wa.me/$phoneDigits?text=${Uri.encodeComponent(message)}',
  );
  if (!await canLaunchUrl(uri)) return false;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
  return true;
}

class PresupuestoDetailScreen extends ConsumerStatefulWidget {
  const PresupuestoDetailScreen({super.key});

  @override
  ConsumerState<PresupuestoDetailScreen> createState() =>
      _PresupuestoDetailScreenState();
}

class _PresupuestoDetailScreenState
    extends ConsumerState<PresupuestoDetailScreen> {
  final _searchCtrl = TextEditingController();
  late final ScrollController _productsScroll;

  @override
  void initState() {
    super.initState();
    _productsScroll = ScrollController();
    _productsScroll.addListener(_onProductsScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(presupuestoCatalogControllerProvider.notifier).bootstrap();
    });
  }

  @override
  void dispose() {
    _productsScroll.removeListener(_onProductsScroll);
    _productsScroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onProductsScroll() {
    if (!_productsScroll.hasClients) return;
    final pos = _productsScroll.position;
    if (pos.pixels > pos.maxScrollExtent - 600) {
      ref.read(presupuestoCatalogControllerProvider.notifier).loadMore();
    }
  }

  Future<void> _openFilters() async {
    final st = ref.read(presupuestoCatalogControllerProvider);
    final result = await showDialog<PresupuestoFiltersResult>(
      context: context,
      builder: (_) => PresupuestoFiltersDialog(
        initialMinPrice: st.minPrice,
        initialMaxPrice: st.maxPrice,
        initialOrder: st.order,
        initialProductType: st.productType,
      ),
    );

    if (result == null) return;
    ref
        .read(presupuestoCatalogControllerProvider.notifier)
        .setFilters(
          minPrice: result.minPrice,
          maxPrice: result.maxPrice,
          order: result.order,
          productType: result.productType,
        );
  }

  Future<void> _pickCustomer() async {
    final selected = await showDialog<CrmThread>(
      context: context,
      builder: (_) => const CrmChatPickerDialog(),
    );
    if (selected == null) return;

    final name = (selected.displayName ?? '').trim().isNotEmpty
        ? selected.displayName!.trim()
        : (selected.phone ?? selected.waId).trim();

    final draft = QuotationCustomerDraft(
      id: null,
      nombre: name,
      telefono: (selected.phone ?? '').trim().isEmpty ? null : selected.phone,
      email: null,
    );

    final ctrl = ref.read(quotationBuilderControllerProvider.notifier);
    ctrl.setCustomer(draft);
    ctrl.setCrmChatId(selected.id);
  }

  Future<void> _editItem(String localId) async {
    final ctrl = ref.read(quotationBuilderControllerProvider.notifier);
    final st = ref.read(quotationBuilderControllerProvider);
    final item = st.items.firstWhere((it) => it.localId == localId);

    final res = await showDialog<QuotationItemEditResult>(
      context: context,
      builder: (_) => QuotationItemEditDialog(
        item: item,
        canEditCost: ctrl.canSeeCost,
        initialDontAutoShowAgain: st.skipAutoEditDialog,
      ),
    );

    if (res == null) return;
    ctrl.updateItem(localId, res.item);
    if (res.dontAutoShowAgain != st.skipAutoEditDialog) {
      await ctrl.setSkipAutoEditDialog(res.dontAutoShowAgain);
    }
  }

  Future<void> _addManualItem() async {
    final res = await showDialog<ManualItemResult>(
      context: context,
      builder: (_) => ManualItemDialog(
        canEditCost: ref
            .read(quotationBuilderControllerProvider.notifier)
            .canSeeCost,
      ),
    );
    if (res == null) return;

    final ctrl = ref.read(quotationBuilderControllerProvider.notifier);
    final id = ctrl.addManualItem(
      nombre: res.nombre,
      unitPrice: res.unitPrice,
      unitCost: res.unitCost,
    );
    final st = ref.read(quotationBuilderControllerProvider);
    if (st.items.length == 1 && !st.skipAutoEditDialog) {
      await _editItem(id);
    }
  }

  Future<void> _addProduct(Producto p) async {
    final ctrl = ref.read(quotationBuilderControllerProvider.notifier);

    final id = ctrl.addProduct(
      productId: p.id,
      nombre: p.nombre,
      unitPrice: p.precioVenta,
      unitCost: ctrl.canSeeCost ? p.precioCompra : null,
    );

    final st = ref.read(quotationBuilderControllerProvider);
    if (st.items.length == 1 && !st.skipAutoEditDialog) {
      await _editItem(id);
    }
  }

  Future<void> _openPreview() async {
    final ctrl = ref.read(quotationBuilderControllerProvider.notifier);
    final draft = ref.read(quotationBuilderControllerProvider);

    Map<String, dynamic>? created;
    try {
      created = await ctrl.saveQuotation();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error guardando cotización: $e')));
      return;
    }

    if (!mounted || created == null) return;
    final createdMeta = created;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            QuotationPdfViewerScreen(draft: draft, quotationMeta: createdMeta),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quote = ref.watch(quotationBuilderControllerProvider);
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
                  child: _CatalogPane(
                    productsScroll: _productsScroll,
                    searchCtrl: _searchCtrl,
                    onBarcode: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Escaner: pendiente integracion'),
                        ),
                      );
                    },
                    onFilters: _openFilters,
                    onAddProduct: _addProduct,
                    canSeeCost: canSeeCost,
                    onOpenCotizaciones: () =>
                        context.go(AppRoutes.cotizaciones),
                    onOpenCartas: () =>
                        context.go(AppRoutes.informeCotizaciones),
                    onOpenCrearCartas: () => context.go(AppRoutes.crearCartas),
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
                      child: _QuotePane(
                        quote: quote,
                        canSeeCost: canSeeCost,
                        onPickCustomer: _pickCustomer,
                        onAddManual: _addManualItem,
                        onEditItem: _editItem,
                        onDeleteItem: (id) => ref
                            .read(quotationBuilderControllerProvider.notifier)
                            .removeItem(id),
                        onToggleItbis: (v) => ref
                            .read(quotationBuilderControllerProvider.notifier)
                            .setItbisEnabled(v),
                        onChangeItbisRate: (v) => ref
                            .read(quotationBuilderControllerProvider.notifier)
                            .setItbisRate(v),
                        onPreview: _openPreview,
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
                child: _CatalogPane(
                  productsScroll: _productsScroll,
                  searchCtrl: _searchCtrl,
                  onBarcode: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Escaner: pendiente integracion'),
                      ),
                    );
                  },
                  onFilters: _openFilters,
                  onAddProduct: _addProduct,
                  canSeeCost: canSeeCost,
                  onOpenCotizaciones: () => context.go(AppRoutes.cotizaciones),
                  onOpenCartas: () => context.go(AppRoutes.informeCotizaciones),
                  onOpenCrearCartas: () => context.go(AppRoutes.crearCartas),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                flex: 7,
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  elevation: 3,
                  borderRadius: BorderRadius.circular(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _QuotePane(
                      quote: quote,
                      canSeeCost: canSeeCost,
                      onPickCustomer: _pickCustomer,
                      onAddManual: _addManualItem,
                      onEditItem: _editItem,
                      onDeleteItem: (id) => ref
                          .read(quotationBuilderControllerProvider.notifier)
                          .removeItem(id),
                      onToggleItbis: (v) => ref
                          .read(quotationBuilderControllerProvider.notifier)
                          .setItbisEnabled(v),
                      onChangeItbisRate: (v) => ref
                          .read(quotationBuilderControllerProvider.notifier)
                          .setItbisRate(v),
                      onPreview: _openPreview,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CatalogPane extends ConsumerWidget {
  final ScrollController productsScroll;
  final TextEditingController searchCtrl;
  final VoidCallback onBarcode;
  final VoidCallback onFilters;
  final Future<void> Function(Producto) onAddProduct;
  final bool canSeeCost;
  final VoidCallback onOpenCotizaciones;
  final VoidCallback onOpenCartas;
  final VoidCallback onOpenCrearCartas;

  const _CatalogPane({
    required this.productsScroll,
    required this.searchCtrl,
    required this.onBarcode,
    required this.onFilters,
    required this.onAddProduct,
    required this.canSeeCost,
    required this.onOpenCotizaciones,
    required this.onOpenCartas,
    required this.onOpenCrearCartas,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(presupuestoCatalogControllerProvider);
    final ctrl = ref.read(presupuestoCatalogControllerProvider.notifier);

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final money0 = NumberFormat('#,##0', 'en_US');

    final allSelected =
        st.selectedCategoriaId == null ||
        st.selectedCategoriaId!.trim().isEmpty;

    final width = MediaQuery.sizeOf(context).width;
    // Bigger cards: fewer columns per breakpoint.
    final crossAxisCount = width >= 1400
        ? 6
        : (width >= 1200
              ? 5
              : (width >= 980
                    ? 4
                    : (width >= 760 ? 3 : (width >= 520 ? 2 : 2))));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (st.isLoading) const LinearProgressIndicator(),
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
                  onChanged: ctrl.setQuery,
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
                  onSelected: (_) => ctrl.setCategoria(null),
                ),
              ),
              for (final c in st.categorias)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(c.nombre.toUpperCase()),
                    selected: st.selectedCategoriaId == c.id,
                    backgroundColor: cs.primaryContainer,
                    selectedColor: cs.primary,
                    side: BorderSide(
                      color:
                          (st.selectedCategoriaId == c.id
                                  ? cs.onPrimary
                                  : cs.onPrimaryContainer)
                              .withValues(alpha: 0.35),
                    ),
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      color: st.selectedCategoriaId == c.id
                          ? cs.onPrimary
                          : cs.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                    onSelected: (_) => ctrl.setCategoria(c.id),
                  ),
                ),
            ],
          ),
        ),
        if (st.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              st.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.builder(
            controller: productsScroll,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 0.78,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: st.productos.length + (st.isLoadingMore ? 1 : 0),
            itemBuilder: (context, i) {
              if (i >= st.productos.length) {
                return const Center(child: CircularProgressIndicator());
              }

              final p = st.productos[i];
              final priceText = money0.format(p.precioVenta.round());
              final costText = money0.format(p.precioCompra.round());

              return CatalogProductGridCard(
                nombre: p.nombre,
                priceText: priceText,
                costText: costText,
                canSeeCost: canSeeCost,
                imageRaw: p.imagenUrl,
                stockQty: p.stock.toDouble(),
                minStock: p.minStock.toDouble(),
                onTap: () => onAddProduct(p),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: onOpenCotizaciones,
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Cotizaciones'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: onOpenCartas,
                icon: const Icon(Icons.mail_outline),
                label: const Text('Cartas'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onOpenCrearCartas,
                icon: const Icon(Icons.auto_awesome_outlined),
                label: const Text('Crear cartas'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuotePane extends ConsumerWidget {
  final QuotationBuilderState quote;
  final bool canSeeCost;
  final VoidCallback onPickCustomer;
  final Future<void> Function() onAddManual;
  final Future<void> Function(String localId) onEditItem;
  final void Function(String localId) onDeleteItem;
  final void Function(bool) onToggleItbis;
  final void Function(double) onChangeItbisRate;
  final Future<void> Function() onPreview;

  const _QuotePane({
    required this.quote,
    required this.canSeeCost,
    required this.onPickCustomer,
    required this.onAddManual,
    required this.onEditItem,
    required this.onDeleteItem,
    required this.onToggleItbis,
    required this.onChangeItbisRate,
    required this.onPreview,
  });

  Future<void> _renameTicket(
    BuildContext context,
    WidgetRef ref,
    int index,
    String current,
  ) async {
    final ctrl = TextEditingController(text: current);
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
    ref
        .read(quotationBuilderControllerProvider.notifier)
        .renameTicket(index, next);
  }

  void _incQty(WidgetRef ref, QuotationItemDraft it) {
    final next = it.copyWith(cantidad: it.cantidad + 1);
    ref
        .read(quotationBuilderControllerProvider.notifier)
        .updateItem(it.localId, next);
  }

  void _decQty(WidgetRef ref, QuotationItemDraft it) {
    if (it.cantidad <= 1) {
      ref
          .read(quotationBuilderControllerProvider.notifier)
          .removeItem(it.localId);
      return;
    }
    final next = it.copyWith(cantidad: it.cantidad - 1);
    ref
        .read(quotationBuilderControllerProvider.notifier)
        .updateItem(it.localId, next);
  }

  Widget _itemCard({
    required BuildContext context,
    required WidgetRef ref,
    required QuotationItemDraft it,
    required bool canSeeCost,
    required String? imageUrl,
    required Future<void> Function() onEdit,
    required VoidCallback onDelete,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final hasDiscount = it.lineDiscount > 0;
    final discountLabel = it.discountMode == QuotationDiscountMode.amount
        ? '-${it.discountAmount.toStringAsFixed(2)}'
        : '-${it.discountPct.toStringAsFixed(0)}%';

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
                      ? adaptiveImage(
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
                            it.nombre,
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
                            'C: ${(it.unitCost ?? 0).toStringAsFixed(2)}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.error,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    it.lineNet.toStringAsFixed(2),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        onPressed: () => _decQty(ref, it),
                        icon: const Icon(Icons.remove_circle_outline, size: 18),
                        tooltip: 'Restar',
                      ),
                      SizedBox(
                        width: 24,
                        child: Text(
                          it.cantidad.toStringAsFixed(0),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        onPressed: () => _incQty(ref, it),
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        tooltip: 'Sumar',
                      ),
                      const SizedBox(width: 2),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        tooltip: 'Eliminar',
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline, size: 18),
                      ),
                    ],
                  ),
                ],
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
    final ticket = quote.activeTicket;

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

    Future<void> save() async {
      final created = await ref
          .read(quotationBuilderControllerProvider.notifier)
          .saveQuotation();
      if (created == null) return;
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cotización guardada')));
    }

    Future<void> sendWhatsApp() async {
      final chatId = (ticket.crmChatId ?? '').trim();
      Map<String, dynamic>? created;
      try {
        created = await ref
            .read(quotationBuilderControllerProvider.notifier)
            .saveQuotation();
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error guardando cotización: $e')),
        );
        return;
      }
      if (created == null) return;

      final company = await ref.read(companyProfileProvider.future);

      final numero = (created['numero'] ?? '').toString();
      final id = (created['id'] ?? '').toString();
      final createdAtRaw = (created['created_at'] ?? created['createdAt'])
          ?.toString();
      final createdAt = DateTime.tryParse(createdAtRaw ?? '') ?? DateTime.now();
      final status = (created['status'] ?? 'draft').toString();
      final notes = (created['notes'] ?? '').toString();

      String shortId({required String id, required String numero}) {
        final n = numero.trim();
        if (n.isNotEmpty) return n;
        final trimmed = id.trim();
        if (trimmed.isEmpty) return 'SIN_ID';
        return trimmed.length <= 8 ? trimmed : trimmed.substring(0, 8);
      }

      String fmtDateForFilename(DateTime dt) {
        String two(int n) => n.toString().padLeft(2, '0');
        return '${dt.year}${two(dt.month)}${two(dt.day)}';
      }

      final idShort = shortId(id: id, numero: numero);
      final filename =
          'Cotizacion_FULLTECH_${idShort}_${fmtDateForFilename(createdAt)}.pdf';

      final pdfBytes = await buildQuotationPdfBytesProSafe(
        draft: quote,
        quotationNumber: numero,
        idShort: idShort,
        createdAt: createdAt,
        status: status,
        notes: notes,
        company: company,
        format: PdfPageFormat.a4,
      );

      final caption =
          'Cotización ${numero.trim().isEmpty ? idShort : numero} · Total RD\$ ${quote.total.toStringAsFixed(2)}';

      // If the user didn't select a CRM chat, allow sending to the client's
      // phone via WhatsApp (open chat + share PDF).
      if (chatId.isEmpty) {
        final customer = ticket.customer;
        final phoneDigits = _normalizeWhatsAppPhone(customer?.telefono);
        final customerName = (customer?.nombre ?? '').trim();
        final quoteNo = numero.trim().isEmpty ? idShort : numero.trim();
        final msg =
            'Hola${customerName.isEmpty ? '' : ' $customerName'}, le comparto su cotización No. $quoteNo. '
            'Total: RD\$ ${quote.total.toStringAsFixed(2)}.';

        if (!context.mounted) return;
        await showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (ctx) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Enviar por WhatsApp',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: phoneDigits == null
                          ? null
                          : () async {
                              Navigator.of(ctx).pop();
                              final ok = await _openWhatsAppChat(
                                phoneDigits,
                                msg,
                              );
                              if (!ok && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No se pudo abrir WhatsApp'),
                                  ),
                                );
                              }
                            },
                      icon: const Icon(Icons.chat_outlined),
                      label: const Text('Abrir chat (mensaje)'),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.tonalIcon(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        try {
                          await Printing.sharePdf(
                            bytes: pdfBytes,
                            filename: filename,
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('No se pudo compartir: $e')),
                          );
                        }
                      },
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Compartir PDF (selecciona WhatsApp)'),
                    ),
                    if (phoneDigits == null) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'Nota: el cliente no tiene teléfono válido en la ficha.',
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
        return;
      }

      try {
        await ref
            .read(quotationApiProvider)
            .sendQuotationWhatsappPdf(
              id,
              chatId: chatId,
              pdfBytes: pdfBytes,
              filename: filename,
              caption: caption,
            );
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cotización enviada por WhatsApp')),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error enviando WhatsApp: $e')));
      }
    }

    final catalogItems = ticket.items
        .where((it) => it.productId != null)
        .toList();
    final manualItems = ticket.items
        .where((it) => it.productId == null)
        .toList();
    final catalog = ref.watch(presupuestoCatalogControllerProvider);

    String publicUrlFromMaybeRelative(String raw) {
      final v = raw.trim();
      if (v.isEmpty) return '';
      if (v.startsWith('http://') || v.startsWith('https://')) return v;
      final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/api$'), '');
      if (v.startsWith('/')) return '$base$v';
      return '$base/$v';
    }

    bool isLikelyLocalPath(String value) {
      // Treat backend-served paths like /uploads/... as remote (not local).
      if (value.startsWith('/uploads/')) return false;

      // Windows: C:\... or C:/...
      if (RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(value)) return true;
      // file://...
      if (value.startsWith('file://')) return true;
      return false;
    }

    String? imageUrlFor(QuotationItemDraft it) {
      final id = it.productId;
      if (id == null) return null;
      final p = catalog.productos.cast<Producto?>().firstWhere(
        (p) => p?.id == id,
        orElse: () => null,
      );
      final raw = p?.imagenUrl;
      if (raw == null || raw.trim().isEmpty) return null;
      final v = raw.trim();
      if (isLikelyLocalPath(v)) return v;
      return publicUrlFromMaybeRelative(v);
    }

    return LayoutBuilder(
      builder: (context, pane) {
        // When the right pane is short (window resized/split view),
        // keep the header compact to prevent any vertical overflows.
        final paneH = pane.maxHeight;
        final paneTightH = paneH.isFinite && paneH < 620;
        final paneUltraTightH = paneH.isFinite && paneH < 520;

        final content = Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Presupuesto',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Agregar ticket',
                        onPressed: () => ref
                            .read(quotationBuilderControllerProvider.notifier)
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
                      itemCount: quote.tickets.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final t = quote.tickets[i];
                        final selected = i == quote.activeTicketIndex;
                        return GestureDetector(
                          onLongPress: () =>
                              _renameTicket(context, ref, i, t.name),
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
                              color: (selected ? cs.primary : cs.outlineVariant)
                                  .withValues(alpha: 0.5),
                            ),
                            labelStyle: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: selected ? cs.onPrimary : cs.onSurface,
                            ),
                            onPressed: () => ref
                                .read(
                                  quotationBuilderControllerProvider.notifier,
                                )
                                .selectTicket(i),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: paneUltraTightH ? 6 : 10),
                  LayoutBuilder(
                    builder: (context, c) {
                      final isCompact = c.maxWidth < 420;

                      // LayoutBuilder here often receives unbounded height in a Column.
                      // Use pane-level constraints to detect tight vertical space.
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

                      final customerName = (ticket.customer?.nombre ?? '')
                          .trim();
                      final hasCustomer = customerName.isNotEmpty;

                      // Keep the header overflow-proof:
                      // - Text lives in Expanded
                      // - Actions live in a bounded ConstrainedBox
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
                                                color: cs.onPrimary.withValues(
                                                  alpha: 0.85,
                                                ),
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
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (showItemsText) ...[
                                          Flexible(
                                            child: Text(
                                              'Items: ${ticket.items.length}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.right,
                                              style: theme.textTheme.labelMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w800,
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
                                          visualDensity: VisualDensity.compact,
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
            const Divider(height: 1),
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
                    if (catalogItems.isNotEmpty) ...[
                      Text(
                        'Catálogo',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final it in catalogItems)
                        _itemCard(
                          context: context,
                          ref: ref,
                          it: it,
                          canSeeCost: canSeeCost,
                          imageUrl: imageUrlFor(it),
                          onEdit: () => onEditItem(it.localId),
                          onDelete: () => onDeleteItem(it.localId),
                        ),
                      const SizedBox(height: 10),
                    ],
                    if (manualItems.isNotEmpty) ...[
                      Text(
                        'Manual',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final it in manualItems)
                        _itemCard(
                          context: context,
                          ref: ref,
                          it: it,
                          canSeeCost: canSeeCost,
                          imageUrl: null,
                          onEdit: () => onEditItem(it.localId),
                          onDelete: () => onDeleteItem(it.localId),
                        ),
                    ],
                  ],
                  if (quote.error != null) ...[
                    const SizedBox(height: 8),
                    Text(quote.error!, style: TextStyle(color: cs.error)),
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
                      Expanded(
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: quote.itbisEnabled,
                          onChanged: onToggleItbis,
                          title: const Text('ITBIS'),
                          dense: true,
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: TextFormField(
                          initialValue: (quote.itbisRate * 100).toStringAsFixed(
                            0,
                          ),
                          enabled: quote.itbisEnabled,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            suffixText: '%',
                            isDense: true,
                          ),
                          onFieldSubmitted: (v) {
                            final pct = double.tryParse(v.trim());
                            if (pct == null) return;
                            onChangeItbisRate((pct / 100).clamp(0, 1));
                          },
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
                        quote.grossSubtotal.toStringAsFixed(2),
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
                        quote.discountTotal.toStringAsFixed(2),
                        style: totalsValueStyle,
                      ),
                    ],
                  ),
                  SizedBox(height: paneUltraTightH ? 4 : 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('ITBIS monto', style: totalsLabelStyle),
                      Text(
                        quote.itbisAmount.toStringAsFixed(2),
                        style: totalsValueStyle,
                      ),
                    ],
                  ),
                  SizedBox(height: paneUltraTightH ? 6 : 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: totalLabelStyle),
                      Text(
                        quote.total.toStringAsFixed(2),
                        style: totalValueStyle,
                      ),
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
                  SizedBox(height: paneUltraTightH ? 6 : 10),
                  const Divider(height: 1),
                  SizedBox(height: paneUltraTightH ? 6 : 10),
                  LayoutBuilder(
                    builder: (context, c) {
                      final disabled = ticket.items.isEmpty;
                      final buttonWidth = ((c.maxWidth - 24) / 4).clamp(
                        96.0,
                        220.0,
                      );

                      Widget btn(Widget child) => SizedBox(
                        width: buttonWidth,
                        height: paneUltraTightH ? 40 : 46,
                        child: child,
                      );

                      final saveBtn = btn(
                        FilledButton.icon(
                          onPressed: disabled || quote.isSaving ? null : save,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Guardar'),
                        ),
                      );
                      final waBtn = btn(
                        FilledButton.tonalIcon(
                          onPressed: disabled ? null : sendWhatsApp,
                          icon: const Icon(Icons.chat_outlined),
                          label: const Text(
                            'WhatsApp',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                      final pdfBtn = btn(
                        FilledButton.tonalIcon(
                          onPressed: disabled ? null : onPreview,
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                          label: const Text(
                            'Ver PDF',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            saveBtn,
                            const SizedBox(width: 8),
                            waBtn,
                            const SizedBox(width: 8),
                            pdfBtn,
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        );

        return Card(child: content);
      },
    );
  }
}
