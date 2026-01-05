import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/app_config.dart';
import '../../catalogo/models/producto.dart';
import '../../catalogo/state/catalog_providers.dart';
import '../../customers/data/models/customer_response.dart';
import '../../customers/providers/customers_provider.dart';
import '../../presupuesto/widgets/manual_item_dialog.dart';
import '../data/sales_repository.dart';
import '../models/sales_models.dart';

class SalesRegisterDialogResult {
  final CustomerItem customer;
  final List<SalesLineItem> items;
  final DateTime soldAt;
  final String? notes;
  final List<EvidenceDraft> evidences;

  const SalesRegisterDialogResult({
    required this.customer,
    required this.items,
    required this.soldAt,
    required this.notes,
    required this.evidences,
  });
}

class SalesRegisterDialog extends ConsumerStatefulWidget {
  final String title;
  final SalesRecord? existing;

  const SalesRegisterDialog({
    super.key,
    required this.title,
    this.existing,
  });

  @override
  ConsumerState<SalesRegisterDialog> createState() => _SalesRegisterDialogState();
}

class _SalesRegisterDialogState extends ConsumerState<SalesRegisterDialog> {
  final _uuid = const Uuid();

  final _productSearchCtrl = TextEditingController();
  Timer? _productDebounce;

  bool _loadingProducts = true;
  String? _productsError;
  List<Producto> _products = const [];

  CustomerItem? _selectedCustomer;

  final List<SalesLineItem> _items = [];

  DateTime _soldAt = DateTime.now();
  final _notesCtrl = TextEditingController();

  bool _saving = false;
  String? _error;

  final List<EvidenceDraft> _evidences = [];

  @override
  void initState() {
    super.initState();

    _soldAt = widget.existing?.soldAt ?? DateTime.now();
    _notesCtrl.text = widget.existing?.notes ?? '';

    _productSearchCtrl.addListener(() {
      _productDebounce?.cancel();
      _productDebounce = Timer(const Duration(milliseconds: 350), () {
        _loadProducts();
      });
    });

    _loadProducts();
    _hydrateExisting();
  }

  void _hydrateExisting() {
    final ex = widget.existing;
    if (ex == null) return;

    if (ex.items.isNotEmpty) {
      _items
        ..clear()
        ..addAll(ex.items);
    } else if (ex.productOrService.trim().isNotEmpty && ex.amount > 0) {
      _items
        ..clear()
        ..add(
          SalesLineItem(
            id: _uuid.v4(),
            name: ex.productOrService.trim(),
            quantity: 1,
            unitPrice: ex.amount,
            productId: null,
          ),
        );
    }

    // Customer: best-effort. We only have name/phone in the record.
    if ((ex.customerName ?? '').trim().isNotEmpty) {
      _selectedCustomer = CustomerItem(
        id: 'unknown',
        fullName: ex.customerName!.trim(),
        phone: ex.customerPhone ?? '',
        whatsappId: null,
        avatarUrl: null,
        status: 'active',
        isActiveCustomer: true,
        totalPurchasesCount: 0,
        totalSpent: 0,
        lastPurchaseAt: null,
        lastChatAt: null,
        lastMessagePreview: null,
        assignedProduct: null,
        tags: const [],
        important: false,
        internalNote: null,
      );
    }
  }

  @override
  void dispose() {
    _productDebounce?.cancel();
    _productSearchCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loadingProducts = true;
      _productsError = null;
    });

    try {
      final api = ref.read(catalogApiProvider);
      final items = await api.listProductos(q: _productSearchCtrl.text.trim(), limit: 50, page: 1);
      setState(() {
        _products = items;
        _loadingProducts = false;
      });
    } catch (e) {
      setState(() {
        _productsError = e.toString();
        _loadingProducts = false;
      });
    }
  }

  double get _total => _items.fold<double>(0, (acc, it) => acc + it.total);

  String _formatMoney(num v) => NumberFormat.currency(symbol: r'$', decimalDigits: 2).format(v);

  String _publicUrlFromMaybeRelative(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return '';
    if (v.startsWith('http://') || v.startsWith('https://')) return v;

    // Most uploads are served from the same host, without the /api prefix.
    final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/api$'), '');
    if (v.startsWith('/')) return '$base$v';
    return '$base/$v';
  }

  Widget _tinyProductThumb(Producto p) {
    final cs = Theme.of(context).colorScheme;
    final raw = p.imagenUrl.trim();
    final url = raw.isEmpty ? '' : _publicUrlFromMaybeRelative(raw);

    return SizedBox(
      width: 28,
      height: 28,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: ColoredBox(
          color: cs.surfaceContainerHighest,
          child: url.isEmpty
              ? Icon(Icons.image_outlined, size: 16, color: cs.onSurfaceVariant)
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.broken_image_outlined,
                    size: 16,
                    color: cs.onSurfaceVariant,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _pickCustomer() async {
    final picked = await showDialog<CustomerItem>(
      context: context,
      builder: (context) => const _ActiveCustomerPickerDialog(),
    );

    if (!mounted || picked == null) return;

    if (!picked.isActiveCustomer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solo se permiten clientes activos.')),
      );
      return;
    }

    setState(() {
      _selectedCustomer = picked;
      _error = null;
    });
  }

  void _addCatalogProduct(Producto p) {
    final idx = _items.indexWhere((e) => e.productId == p.id);
    if (idx >= 0) {
      final existing = _items[idx];
      _items[idx] = SalesLineItem(
        id: existing.id,
        name: existing.name,
        quantity: existing.quantity + 1,
        unitPrice: existing.unitPrice,
        productId: existing.productId,
      );
    } else {
      _items.add(
        SalesLineItem(
          id: _uuid.v4(),
          name: p.nombre,
          quantity: 1,
          unitPrice: p.precioVenta,
          productId: p.id,
        ),
      );
    }
    setState(() {});
  }

  Future<void> _addManualProduct() async {
    final res = await showDialog<ManualItemResult>(
      context: context,
      builder: (_) => const ManualItemDialog(canEditCost: false),
    );

    if (!mounted || res == null) return;

    setState(() {
      _items.add(
        SalesLineItem(
          id: _uuid.v4(),
          name: res.nombre,
          quantity: 1,
          unitPrice: res.unitPrice,
          productId: null,
        ),
      );
    });
  }

  void _incQty(SalesLineItem it) {
    final idx = _items.indexWhere((e) => e.id == it.id);
    if (idx < 0) return;
    _items[idx] = SalesLineItem(
      id: it.id,
      name: it.name,
      quantity: it.quantity + 1,
      unitPrice: it.unitPrice,
      productId: it.productId,
    );
    setState(() {});
  }

  void _decQty(SalesLineItem it) {
    final idx = _items.indexWhere((e) => e.id == it.id);
    if (idx < 0) return;
    if (it.quantity <= 1) {
      _items.removeAt(idx);
    } else {
      _items[idx] = SalesLineItem(
        id: it.id,
        name: it.name,
        quantity: it.quantity - 1,
        unitPrice: it.unitPrice,
        productId: it.productId,
      );
    }
    setState(() {});
  }

  Future<void> _editItemDetails(SalesLineItem it) async {
    final qtyCtrl = TextEditingController(text: it.quantity.toString());
    final priceCtrl = TextEditingController(text: it.unitPrice.toStringAsFixed(2));

    int? parseQty(String s) {
      final v = int.tryParse(s.trim());
      if (v == null || v <= 0) return null;
      return v;
    }

    double? parsePrice(String s) {
      final raw = s.trim().replaceAll(',', '.');
      final v = double.tryParse(raw);
      if (v == null || v < 0) return null;
      return v;
    }

    final updated = await showDialog<SalesLineItem>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar detalle'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(it.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Cantidad vendida'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Precio vendido (unitario)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final q = parseQty(qtyCtrl.text);
                final p = parsePrice(priceCtrl.text);
                if (q == null || p == null) return;
                Navigator.of(context).pop(
                  SalesLineItem(
                    id: it.id,
                    name: it.name,
                    quantity: q,
                    unitPrice: p,
                    productId: it.productId,
                  ),
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    qtyCtrl.dispose();
    priceCtrl.dispose();

    if (!mounted || updated == null) return;

    final idx = _items.indexWhere((e) => e.id == it.id);
    if (idx < 0) return;
    setState(() {
      _items[idx] = updated;
    });
  }

  Future<void> _pickEvidenceFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'pdf'],
    );

    if (result == null || result.files.isEmpty) return;
    final f = result.files.single;
    final bytes = f.bytes;
    if (bytes == null || bytes.isEmpty) {
      setState(() => _error = 'No se pudo leer el archivo.');
      return;
    }

    final ext = (f.extension ?? '').toLowerCase();
    final type = ext == 'pdf' ? SalesEvidenceType.pdf : SalesEvidenceType.image;
    final filename = f.name;

    final String? mimeType = switch (ext) {
      'pdf' => 'application/pdf',
      'png' => 'image/png',
      'jpg' => 'image/jpeg',
      'jpeg' => 'image/jpeg',
      _ => null,
    };

    setState(() {
      _error = null;
      _evidences.add(EvidenceDraft.file(
        type: type,
        bytes: bytes,
        filename: filename,
        mimeType: mimeType,
      ));
    });
  }

  Future<void> _submit() async {
    if (_saving) return;

    if (_selectedCustomer == null) {
      setState(() => _error = 'Debe seleccionar un cliente activo.');
      return;
    }

    if (_items.isEmpty) {
      setState(() => _error = 'Debe agregar al menos un producto a la venta.');
      return;
    }

    if (_evidences.isEmpty) {
      setState(() => _error = 'Debe adjuntar al menos una evidencia.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      Navigator.of(context).pop(
        SalesRegisterDialogResult(
          customer: _selectedCustomer!,
          items: List.of(_items),
          soldAt: _soldAt,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          evidences: List.of(_evidences),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _catalogPane(bool isDesktop) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: isDesktop ? 3 : 0,
      borderRadius: BorderRadius.circular(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _productSearchCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Productos',
                        hintText: 'Buscar…',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _addManualProduct,
                    icon: const Icon(Icons.add),
                    label: const Text('Manual'),
                  ),
                ],
              ),
            ),
            if (_loadingProducts) const LinearProgressIndicator(minHeight: 2),
            if (_productsError != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _productsError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Expanded(
              child: ListView.separated(
                itemCount: _products.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final p = _products[i];
                  return ListTile(
                    leading: _tinyProductThumb(p),
                    title: Text(p.nombre, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(_formatMoney(p.precioVenta)),
                    trailing: const Icon(Icons.add_circle_outline),
                    onTap: () => _addCatalogProduct(p),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailsPane(bool isDesktop) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: isDesktop ? 3 : 0,
      borderRadius: BorderRadius.circular(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Cliente'),
                      child: Text(
                        _selectedCustomer == null ? 'Seleccionar cliente' : _selectedCustomer!.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _pickCustomer,
                    child: Text(_selectedCustomer == null ? 'Seleccionar' : 'Cambiar'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Fecha de venta'),
                child: Row(
                  children: [
                    Expanded(child: Text(DateFormat('yyyy-MM-dd').format(_soldAt))),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime(DateTime.now().year - 2),
                          lastDate: DateTime(DateTime.now().year + 1),
                          initialDate: _soldAt,
                        );
                        if (picked != null) setState(() => _soldAt = picked);
                      },
                      child: const Text('Cambiar'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Productos (${_items.length})',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            Text(
                              _formatMoney(_total),
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: _items.isEmpty
                            ? const Center(child: Text('Agrega productos desde la izquierda.'))
                            : ListView.separated(
                                itemCount: _items.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, i) {
                                  final it = _items[i];
                                  return ListTile(
                                    title: Text(it.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                                    subtitle: Text('${it.quantity} × ${_formatMoney(it.unitPrice)}'),
                                    onTap: () => _editItemDetails(it),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: 'Quitar',
                                          onPressed: () => _decQty(it),
                                          icon: const Icon(Icons.remove_circle_outline),
                                        ),
                                        Text(
                                          it.quantity.toString(),
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                        IconButton(
                                          tooltip: 'Agregar',
                                          onPressed: () => _incQty(it),
                                          icon: const Icon(Icons.add_circle_outline),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Notas (opcional)'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: _saving ? null : _pickEvidenceFile,
                    icon: const Icon(Icons.attach_file),
                    label: Text('Evidencia (${_evidences.length})'),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Total: ${_formatMoney(_total)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Guardar'),
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
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, c) {
          final isDesktop = c.maxWidth >= 980;
          final dialogWidth = isDesktop ? 1100.0 : c.maxWidth;
          final dialogHeight = isDesktop ? 760.0 : c.maxHeight;

          return SizedBox(
            width: dialogWidth,
            height: dialogHeight,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _catalogPane(true)),
                        const SizedBox(width: 12),
                        SizedBox(width: 520, child: _detailsPane(true)),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _catalogPane(false)),
                        const SizedBox(height: 12),
                        Expanded(child: _detailsPane(false)),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _ActiveCustomerPickerDialog extends ConsumerStatefulWidget {
  const _ActiveCustomerPickerDialog();

  @override
  ConsumerState<_ActiveCustomerPickerDialog> createState() => _ActiveCustomerPickerDialogState();
}

class _ActiveCustomerPickerDialogState extends ConsumerState<_ActiveCustomerPickerDialog> {
  final _qCtrl = TextEditingController();
  Timer? _debounce;

  bool _loading = false;
  String? _error;
  List<CustomerItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _load('');
    _qCtrl.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        _load(_qCtrl.text);
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _qCtrl.dispose();
    super.dispose();
  }

  Future<void> _load(String q) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = ref.read(customersRepositoryProvider);
      final res = await repo.getCustomers(q: q, limit: 30, offset: 0);
      final active = res.items.where((e) => e.isActiveCustomer == true).toList(growable: false);
      setState(() {
        _items = active;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seleccionar cliente (activo)'),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _qCtrl,
              decoration: const InputDecoration(
                labelText: 'Buscar',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null) ...[
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 8),
            ],
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final c = _items[i];
                  return ListTile(
                    title: Text(c.fullName),
                    subtitle: Text([c.phone, c.status].where((s) => s.trim().isNotEmpty).join(' • ')),
                    onTap: () => Navigator.of(context).pop(c),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
