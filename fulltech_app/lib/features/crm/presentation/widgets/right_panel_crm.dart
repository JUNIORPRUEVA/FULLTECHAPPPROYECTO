import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/crm_thread.dart';
import '../../state/crm_providers.dart';
import '../../../catalogo/models/producto.dart';
import '../../../catalogo/models/categoria_producto.dart';
import '../../../catalogo/state/catalog_providers.dart';

class RightPanelCrm extends ConsumerStatefulWidget {
  final String threadId;

  const RightPanelCrm({super.key, required this.threadId});

  @override
  ConsumerState<RightPanelCrm> createState() => _RightPanelCrmState();
}

class _RightPanelCrmState extends ConsumerState<RightPanelCrm> {
  final _noteCtrl = TextEditingController();
  final _assignedCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    _assignedCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final threadsState = ref.watch(crmThreadsControllerProvider);
    final thread = threadsState.items
        .where((t) => t.id == widget.threadId)
        .cast<CrmThread?>()
        .firstOrNull;

    if (thread == null) {
      return const Card(child: Center(child: Text('Selecciona un chat')));
    }

    final nextNote = thread.internalNote ?? '';
    if (_noteCtrl.text != nextNote) _noteCtrl.text = nextNote;
    final nextAssigned = thread.assignedUserId ?? '';
    if (_assignedCtrl.text != nextAssigned) _assignedCtrl.text = nextAssigned;

    final productsAsync = ref.watch(crmProductsProvider);

    Producto? product;
    productsAsync.whenData((items) {
      product = items
          .where((p) => p.id == thread.productId)
          .cast<Producto?>()
          .firstOrNull;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1) Info (compacta) con icono flotante si es importante
        Stack(
          children: [
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _InfoSection(thread: thread, product: product),
              ),
            ),
            if (thread.important)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade400,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text('⭐', style: TextStyle(fontSize: 14)),
                ),
              ),
          ],
        ),
        // 2) Gestión (si hay scroll, que sea aquí)
        Expanded(
          child: Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                child: _ActionsSection(
                  thread: thread,
                  noteCtrl: _noteCtrl,
                  assignedCtrl: _assignedCtrl,
                  onSave: (patch) async {
                    try {
                      await ref
                          .read(crmRepositoryProvider)
                          .patchChat(thread.id, patch);
                      await ref
                          .read(crmThreadsControllerProvider.notifier)
                          .refresh();
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('No se pudo guardar: $e'),
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        ),

        // 3) Estadísticas
        const Card(
          margin: EdgeInsets.zero,
          child: Padding(padding: EdgeInsets.all(12), child: _SummarySection()),
        ),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  final CrmThread thread;
  final Producto? product;

  const _InfoSection({required this.thread, required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final name = (thread.displayName ?? '').trim().isNotEmpty
        ? thread.displayName!.trim()
        : 'Sin nombre';

    final phone = _formatPhone(thread.phone);
    final statusLabel = _statusLabel(thread.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.surface,
              radius: 22,
              child: Text(_initials(name)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            phone,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'WhatsApp ID: ${thread.waId}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _StatusChip(label: statusLabel),
            if (product != null)
              _ProductChip(product: product!)
            else
              _PlaceholderChip(label: 'Sin producto asignado'),
          ],
        ),
      ],
    );
  }

  static String _initials(String v) {
    final parts = v.trim().split(RegExp(r'\s+'));
    final a = parts.isNotEmpty ? parts.first : '';
    final b = parts.length > 1 ? parts[1] : '';
    final s = '${a.isNotEmpty ? a[0] : ''}${b.isNotEmpty ? b[0] : ''}'
        .toUpperCase();
    return s.isEmpty ? '?' : s;
  }

  static String _statusLabel(String raw) {
    final v = raw.trim().toLowerCase();
    switch (v) {
      case 'primer_contacto':
        return 'Primer contacto';
      case 'pendiente':
        return 'Pendiente';
      case 'interesado':
        return 'Interesado';
      case 'reserva':
        return 'Reserva';
      case 'compro':
        return 'Compró';
      case 'no_interesado':
        return 'No interesado';
      case 'activo':
        return 'Activo';
      default:
        final s = v.replaceAll('_', ' ');
        if (s.isEmpty) return '—';
        return '${s[0].toUpperCase()}${s.substring(1)}';
    }
  }

  static String _formatPhone(String? raw) {
    final v = (raw ?? '').trim();
    if (v.isEmpty) return 'Sin teléfono';

    // Extract only digits
    final digits = v.replaceAll(RegExp(r'\D+'), '');
    if (digits.isEmpty) return 'Sin teléfono';

    // Format: +1(829)531-9442 style (professional)
    if (digits.length == 10) {
      // US format without country code: (XXX)XXX-XXXX
      return '(${digits.substring(0, 3)})${digits.substring(3, 6)}-${digits.substring(6)}';
    } else if (digits.length == 11 && digits.startsWith('1')) {
      // +1 country code: +1(XXX)XXX-XXXX
      final area = digits.substring(1, 4);
      final mid = digits.substring(4, 7);
      final tail = digits.substring(7);
      return '+1($area)$mid-$tail';
    } else if (digits.length >= 12) {
      // International with longer country code: +[CC](area)mid-tail
      // Assume last 10 digits are area-mid-tail
      final ccEnd = digits.length - 10;
      final cc = digits.substring(0, ccEnd);
      final area = digits.substring(ccEnd, ccEnd + 3);
      final mid = digits.substring(ccEnd + 3, ccEnd + 6);
      final tail = digits.substring(ccEnd + 6);
      return '+$cc($area)$mid-$tail';
    } else if (digits.length == 11) {
      // Other 11-digit formats
      final cc = digits.substring(0, 1);
      final area = digits.substring(1, 4);
      final mid = digits.substring(4, 7);
      final tail = digits.substring(7);
      return '+$cc($area)$mid-$tail';
    }

    return v;
  }
}

class _StatusChip extends StatelessWidget {
  final String label;

  const _StatusChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Chip(
      label: Text(
        'Estado: $label',
        style: TextStyle(color: theme.colorScheme.onPrimary),
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: BorderSide(color: theme.colorScheme.primary),
      backgroundColor: theme.colorScheme.primary,
    );
  }
}

class _ProductChip extends StatelessWidget {
  final Producto product;

  const _ProductChip({required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Chip(
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: BorderSide(color: theme.colorScheme.primary),
      backgroundColor: theme.colorScheme.primary,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: theme.colorScheme.onPrimary,
            backgroundImage: product.imagenUrl.trim().isEmpty
                ? null
                : NetworkImage(product.imagenUrl),
            child: product.imagenUrl.trim().isEmpty
                ? Icon(
                    Icons.inventory_2,
                    size: 14,
                    color: theme.colorScheme.primary,
                  )
                : null,
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              '${product.nombre} · ${_money(product.precioVenta)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: theme.colorScheme.onPrimary),
            ),
          ),
        ],
      ),
    );
  }

  static String _money(double v) => '\$${v.toStringAsFixed(2)}';
}

class _PlaceholderChip extends StatelessWidget {
  final String label;

  const _PlaceholderChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      label: Text(label, style: TextStyle(color: theme.colorScheme.onPrimary)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: BorderSide(color: theme.colorScheme.primary),
      backgroundColor: theme.colorScheme.primary,
    );
  }
}

class _ActionsSection extends ConsumerWidget {
  final CrmThread thread;
  final TextEditingController noteCtrl;
  final TextEditingController assignedCtrl;
  final Future<void> Function(Map<String, dynamic> patch) onSave;

  const _ActionsSection({
    required this.thread,
    required this.noteCtrl,
    required this.assignedCtrl,
    required this.onSave,
  });

  static const String _addProductSentinel = '__add_product__';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final productsAsync = ref.watch(crmProductsProvider);

    Producto? product;
    productsAsync.whenData((items) {
      product = items
          .where((p) => p.id == thread.productId)
          .cast<Producto?>()
          .firstOrNull;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header: Gestión + Estado actual badge
        Row(
          children: [
            Text(
              'Gestión',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Chip(
              label: Text(
                _statusLabel(thread.status),
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: theme.colorScheme.primary,
              side: BorderSide(color: theme.colorScheme.primary),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Producto interesado (si existe)
        if (product != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ProductChip(product: product!),
          ),

        // Cambiar Estado
        DropdownButtonFormField<String>(
          value: thread.status,
          items: const [
            DropdownMenuItem(
              value: 'primer_contacto',
              child: Text('Primer contacto'),
            ),
            DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
            DropdownMenuItem(value: 'interesado', child: Text('Interesado')),
            DropdownMenuItem(value: 'reserva', child: Text('Reserva')),
            DropdownMenuItem(value: 'compro', child: Text('Compró')),
            DropdownMenuItem(
              value: 'no_interesado',
              child: Text('No interesado'),
            ),
            DropdownMenuItem(value: 'activo', child: Text('Activo')),
          ],
          onChanged: (v) async {
            if (v == null) return;

            final nextStatus = v.trim();
            final needsConfirm = nextStatus == 'activo' || nextStatus == 'compro';

            if (needsConfirm) {
              final label = nextStatus == 'activo' ? 'Activo' : 'Compró';
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) {
                  return AlertDialog(
                    title: const Text('Confirmación'),
                    content: Text(
                      '¿Está seguro que quiere marcar la conversación como "$label"?\n\nEsto agregará el cliente a la tabla de clientes.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Sí, confirmar'),
                      ),
                    ],
                  );
                },
              );
              if (ok != true) return;
            }

            await onSave({'status': nextStatus});

            // Only for Activo/Compró, ensure the customer exists.
            if (needsConfirm) {
              try {
                await ref
                    .read(crmRepositoryProvider)
                    .convertChatToCustomer(thread.id);

                // Refresh CRM customers list so it shows up immediately.
                // ignore: unawaited_futures
                ref.read(customersControllerProvider.notifier).refresh();

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cliente agregado a la tabla de clientes')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('No se pudo crear el cliente: $e'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            }
          },
          decoration: const InputDecoration(
            labelText: 'Cambiar estado',
            isDense: true,
          ),
        ),
        const SizedBox(height: 10),

        // Asignar Producto
        productsAsync.when(
          data: (items) {
            final active = items.where((p) => p.isActive).toList();
            return DropdownButtonFormField<String?>(
              value: thread.productId,
              isExpanded: true,
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Sin producto'),
                ),
                DropdownMenuItem<String?>(
                  value: _addProductSentinel,
                  child: Row(
                    children: const [
                      Icon(Icons.add, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Agregar producto…',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                ...active.map(
                  (p) => DropdownMenuItem<String>(
                    value: p.id,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          backgroundImage: p.imagenUrl.trim().isEmpty
                              ? null
                              : NetworkImage(p.imagenUrl),
                          child: p.imagenUrl.trim().isEmpty
                              ? const Icon(Icons.inventory_2, size: 14)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            p.nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('\$${p.precioVenta.toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                ),
              ],
              onChanged: (v) async {
                if (v == _addProductSentinel) {
                  final created = await showDialog<Producto>(
                    context: context,
                    builder: (_) => const _CreateProductDialog(),
                  );

                  if (created == null) return;
                  ref.invalidate(crmProductsProvider);
                  await onSave({'product_id': created.id});
                  return;
                }

                await onSave({'product_id': v});
              },
              decoration: const InputDecoration(
                labelText: 'Asignar producto',
                isDense: true,
              ),
            );
          },
          loading: () =>
              const SizedBox(height: 20, child: LinearProgressIndicator()),
          error: (e, _) => Text(
            'Error productos',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Divider
        Divider(color: theme.colorScheme.outlineVariant),
        const SizedBox(height: 10),

        // Collaboration + Importante (misma línea)
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Asignar a', style: theme.textTheme.labelSmall),
                  const SizedBox(height: 4),
                  TextField(
                    controller: assignedCtrl,
                    decoration: InputDecoration(
                      hintText: 'UUID usuario',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      suffixIcon: IconButton(
                        tooltip: 'Guardar',
                        onPressed: () async {
                          final v = assignedCtrl.text.trim();
                          await onSave({
                            'assigned_user_id': v.isEmpty ? null : v,
                          });
                        },
                        icon: const Icon(Icons.check, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Importante', style: theme.textTheme.labelSmall),
                  const SizedBox(height: 4),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: thread.important,
                    onChanged: (newVal) async {
                      await onSave({'important': newVal});
                    },
                    title: Text(
                      thread.important ? '⭐ Sí' : 'No',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Nota interna (siempre visible, opcional)
        TextField(
          controller: noteCtrl,
          minLines: 2,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Nota interna',
            hintText: 'Escribe una nota…',
            isDense: true,
            contentPadding: const EdgeInsets.all(8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () async {
              await onSave({'internal_note': noteCtrl.text.trim()});
            },
            icon: const Icon(Icons.save, size: 16),
            label: const Text('Guardar nota'),
          ),
        ),
      ],
    );
  }

  static String _statusLabel(String raw) {
    final v = raw.trim().toLowerCase();
    switch (v) {
      case 'pendiente':
        return 'Pendiente';
      case 'interesado':
        return 'Interesado';
      case 'reserva':
        return 'Reserva';
      case 'compro':
        return 'Compró';
      case 'no_interesado':
        return 'No interesado';
      case 'activo':
        return 'Activo';
      default:
        final s = v.replaceAll('_', ' ');
        if (s.isEmpty) return '—';
        return '${s[0].toUpperCase()}${s.substring(1)}';
    }
  }
}

class _CreateProductDialog extends ConsumerStatefulWidget {
  const _CreateProductDialog();

  @override
  ConsumerState<_CreateProductDialog> createState() =>
      _CreateProductDialogState();
}

class _CreateProductDialogState extends ConsumerState<_CreateProductDialog> {
  final _nameCtrl = TextEditingController();
  final _salePriceCtrl = TextEditingController();

  late final Future<List<CategoriaProducto>> _categoriesFuture;
  String? _selectedCategoryId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = ref.read(catalogApiProvider).listCategorias();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _salePriceCtrl.dispose();
    super.dispose();
  }

  double _parsePrice(String v) {
    final cleaned = v.trim().replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 0;
  }

  Future<void> _submit(List<CategoriaProducto> categories) async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe el nombre del producto.')),
      );
      return;
    }

    final categoryId =
        _selectedCategoryId ??
        categories.where((c) => c.isActive).map((c) => c.id).firstOrNull ??
        categories.map((c) => c.id).firstOrNull;

    if (categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay categorías disponibles.')),
      );
      return;
    }

    final sale = _parsePrice(_salePriceCtrl.text);

    setState(() => _submitting = true);
    try {
      final created = await ref
          .read(catalogApiProvider)
          .createProducto(
            nombre: name,
            precioCompra: 0,
            precioVenta: sale,
            imagenUrl: '',
            categoriaId: categoryId,
          );

      if (!mounted) return;
      Navigator.of(context).pop(created);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo crear: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar producto'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: FutureBuilder<List<CategoriaProducto>>(
          future: _categoriesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 90,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Text(
                'No se pudieron cargar categorías: ${snapshot.error}',
              );
            }

            final categories = (snapshot.data ?? const <CategoriaProducto>[]);
            if (categories.isEmpty) {
              return const Text(
                'No hay categorías. Crea una categoría primero en Catálogo.',
              );
            }

            _selectedCategoryId ??=
                categories
                    .where((c) => c.isActive)
                    .map((c) => c.id)
                    .firstOrNull ??
                categories.first.id;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _salePriceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Precio venta',
                    hintText: '0.00',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  isExpanded: true,
                  items: categories
                      .where((c) => c.isActive)
                      .map(
                        (c) => DropdownMenuItem<String>(
                          value: c.id,
                          child: Text(
                            c.nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _submitting
                      ? null
                      : (v) => setState(() => _selectedCategoryId = v),
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    isDense: true,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FutureBuilder<List<CategoriaProducto>>(
          future: _categoriesFuture,
          builder: (context, snapshot) {
            final categories = snapshot.data;
            return FilledButton(
              onPressed: _submitting || categories == null
                  ? null
                  : () => _submit(categories),
              child: _submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Crear'),
            );
          },
        ),
      ],
    );
  }
}

class _SummarySection extends ConsumerWidget {
  const _SummarySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final statsState = ref.watch(crmChatStatsControllerProvider);
    final stats = statsState.stats;

    final by = stats?.byStatus ?? const <String, int>{};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Estadísticas',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        if (statsState.loading && stats == null)
          const LinearProgressIndicator(),
        if (statsState.error != null && stats == null)
          Row(
            children: [
              Expanded(
                child: Text(
                  'No disponible',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  // Log for debugging, but keep UI clean.
                  // ignore: avoid_print
                  debugPrint(
                    '[CRM][UI] stats fetch failed: ${statsState.error}',
                  );
                  ref.read(crmChatStatsControllerProvider.notifier).refresh();
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MiniStat(label: 'Total', value: stats?.total ?? 0),
            _MiniStat(label: 'No leídos', value: stats?.unreadTotal ?? 0),
            _MiniStat(label: 'Importantes', value: stats?.importantCount ?? 0),
            _MiniStat(label: 'Pendiente', value: by['pendiente'] ?? 0),
            _MiniStat(label: 'Interesado', value: by['interesado'] ?? 0),
            _MiniStat(label: 'Reserva', value: by['reserva'] ?? 0),
            _MiniStat(label: 'Compró', value: by['compro'] ?? 0),
            _MiniStat(label: 'No int.', value: by['no_interesado'] ?? 0),
          ],
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final int value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(width: 8),
          Text(
            '$value',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
