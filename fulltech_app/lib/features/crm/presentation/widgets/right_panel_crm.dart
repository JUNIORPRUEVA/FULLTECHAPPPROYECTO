import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/crm_thread.dart';
import '../../state/crm_providers.dart';
import '../../../catalogo/models/producto.dart';
import '../../../catalogo/models/categoria_producto.dart';
import '../../../catalogo/state/catalog_providers.dart';
import '../../../../core/services/app_config.dart';

String? _resolvePublicUrl(String? url) {
  if (url == null) return null;
  final trimmed = url.trim();
  if (trimmed.isEmpty) return null;
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://'))
    return trimmed;
  final base = AppConfig.apiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '');
  if (trimmed.startsWith('/')) return '$base$trimmed';
  return '$base/$trimmed';
}

class RightPanelCrm extends ConsumerStatefulWidget {
  final String threadId;

  const RightPanelCrm({super.key, required this.threadId});

  @override
  ConsumerState<RightPanelCrm> createState() => _RightPanelCrmState();
}

class _RightPanelCrmState extends ConsumerState<RightPanelCrm> {
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Encabezado
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Center(
            child: Text(
              'Gestión y Estadísticas',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        // 1) Estadísticas (arriba, más visible)
        const Card(
          margin: EdgeInsets.only(bottom: 8),
          child: Padding(padding: EdgeInsets.all(12), child: _SummarySection()),
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
      ],
    );
  }
}

class _ProductChip extends StatelessWidget {
  final Producto product;

  const _ProductChip({required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedImage = _resolvePublicUrl(product.imagenUrl);

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
            backgroundImage: resolvedImage == null
                ? null
                : NetworkImage(resolvedImage),
            child: resolvedImage == null
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

class _ActionsSection extends ConsumerWidget {
  final CrmThread thread;
  final TextEditingController noteCtrl;
  final Future<void> Function(Map<String, dynamic> patch) onSave;

  const _ActionsSection({
    required this.thread,
    required this.noteCtrl,
    required this.onSave,
  });

  static const String _addProductSentinel = '__add_product__';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final productsAsync = ref.watch(crmProductsProvider);

    Future<String?> promptImportantNote({required String initialValue}) async {
      final ctrl = TextEditingController(text: initialValue);
      String? error;

      final res = await showDialog<String?>(
        context: context,
        builder: (dialogCtx) {
          final cs = Theme.of(dialogCtx).colorScheme;
          return StatefulBuilder(
            builder: (dialogCtx, setDialogState) {
              final v = ctrl.text.trim();
              final canSave = v.isNotEmpty;

              return AlertDialog(
                title: const Text('Marcar como importante'),
                content: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Agrega una nota obligatoria para marcar esta conversación como importante.',
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: ctrl,
                        autofocus: true,
                        minLines: 2,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Nota',
                          hintText: 'Ej: Cliente VIP, llamar hoy, urgencia…',
                          errorText: error,
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (_) {
                          if (error != null) {
                            setDialogState(() => error = null);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(null),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: canSave
                        ? () {
                            final note = ctrl.text.trim();
                            if (note.isEmpty) {
                              setDialogState(
                                () => error = 'La nota es obligatoria.',
                              );
                              return;
                            }
                            Navigator.of(dialogCtx).pop(note);
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                    ),
                    child: const Text('Guardar'),
                  ),
                ],
              );
            },
          );
        },
      );

      ctrl.dispose();
      return res;
    }

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
        // Header: Gestión
        Text(
          'Gestión',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),

        // Switches (arriba): Importante + Seguimiento
        Row(
          children: [
            Expanded(
              child: SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: thread.important,
                onChanged: (newVal) async {
                  if (newVal) {
                    final note = await promptImportantNote(
                      initialValue: noteCtrl.text,
                    );
                    if (note == null) return;
                    noteCtrl.text = note;
                    await onSave({'important': true, 'internal_note': note});
                    return;
                  }

                  await onSave({'important': false});
                },
                title: Text(
                  'Importante',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  thread.important ? '⭐ Marcado' : 'No',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: thread.followUp,
                onChanged: (newVal) async {
                  await onSave({'follow_up': newVal});
                },
                title: Text(
                  'Seguimiento',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  thread.followUp ? 'Activo' : 'No',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
          ],
        ),

        if (thread.important) ...[
          const SizedBox(height: 6),
          TextField(
            controller: noteCtrl,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Nota (Importante)',
              hintText: 'Nota obligatoria…',
              isDense: true,
              contentPadding: const EdgeInsets.all(8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onSubmitted: (_) async {
              final v = noteCtrl.text.trim();
              if (v.isEmpty) return;
              await onSave({'internal_note': v});
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () async {
                final v = noteCtrl.text.trim();
                if (v.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('La nota es obligatoria.')),
                  );
                  return;
                }
                await onSave({'internal_note': v});
              },
              icon: const Icon(Icons.save, size: 16),
              label: const Text('Guardar nota'),
            ),
          ),
          const SizedBox(height: 12),
        ],

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
            final needsConfirm =
                nextStatus == 'activo' || nextStatus == 'compro';

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
                  const SnackBar(
                    content: Text('Cliente agregado a la tabla de clientes'),
                  ),
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
                          child: () {
                            final url = _resolvePublicUrl(p.imagenUrl);
                            if (url == null) {
                              return const Icon(Icons.inventory_2, size: 14);
                            }

                            return ClipOval(
                              child: Image.network(
                                url,
                                width: 24,
                                height: 24,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.inventory_2,
                                    size: 14,
                                  );
                                },
                              ),
                            );
                          }(),
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

  int _countFor(Map<String, int> by, List<String> keys) {
    final wanted = keys.map(_normalizeKey).toSet();
    for (final e in by.entries) {
      if (wanted.contains(_normalizeKey(e.key))) return e.value;
    }
    return 0;
  }

  String _normalizeKey(String v) {
    final s = v.trim().toLowerCase();
    // normalize spaces/separators
    final t = s.replaceAll(RegExp(r'\s+'), '_').replaceAll('-', '_');
    // normalize common accents (no extra deps)
    return t
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final statsState = ref.watch(crmChatStatsControllerProvider);
    final stats = statsState.stats;

    final by = stats?.byStatus ?? const <String, int>{};

    final entries = <_StatusEntry>[
      _StatusEntry(
        'Pendiente',
        _countFor(by, const ['pendiente', 'pending']),
        theme.colorScheme.primary, // azul (según theme)
      ),
      _StatusEntry(
        'Interesado',
        _countFor(by, const ['interesado', 'interested']),
        theme.colorScheme.secondary, // verde (según theme)
      ),
      _StatusEntry(
        'Reserva',
        _countFor(by, const ['reserva', 'reserved']),
        theme.colorScheme.primaryContainer,
      ),
      _StatusEntry(
        'Compró',
        _countFor(by, const ['compro', 'compró', 'comprado', 'bought']),
        theme.colorScheme.onSurface.withOpacity(0.85), // “negro” visual
      ),
      _StatusEntry(
        'No interesado',
        _countFor(by, const [
          'no_interesado',
          'no interesado',
          'not_interested',
        ]),
        theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
      ),
    ];

    final sumBreakdown = entries.fold<int>(0, (acc, e) => acc + e.value);
    final total = stats?.total ?? sumBreakdown;
    final effectiveEntries = (sumBreakdown == 0 && total > 0)
        ? <_StatusEntry>[
            _StatusEntry('Total', total, theme.colorScheme.primary),
          ]
        : entries;

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
        _StatusStackedBar(
          entries: effectiveEntries,
          isLoading: statsState.loading && stats == null,
        ),
        const SizedBox(height: 8),
        _StatusLegend(entries: effectiveEntries),
        const SizedBox(height: 10),
        _StatusReadableList(entries: effectiveEntries, total: total),
        const SizedBox(height: 10),
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

class _StatusEntry {
  final String label;
  final int value;
  final Color color;

  const _StatusEntry(this.label, this.value, this.color);
}

class _StatusStackedBar extends StatelessWidget {
  final List<_StatusEntry> entries;
  final bool isLoading;

  const _StatusStackedBar({required this.entries, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nonZero = entries.where((e) => e.value > 0).toList();
    final total = nonZero.fold<int>(0, (acc, e) => acc + e.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Distribución por estado',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.75),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '$total',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.75),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 14,
            color: theme.colorScheme.surfaceContainerHighest,
            child: isLoading
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: 0.35,
                      child: Container(
                        color: theme.colorScheme.primary.withOpacity(0.25),
                      ),
                    ),
                  )
                : (total <= 0
                      ? const SizedBox.shrink()
                      : Row(
                          children: [
                            for (final e in nonZero)
                              Expanded(
                                flex: e.value,
                                child: Container(color: e.color),
                              ),
                          ],
                        )),
          ),
        ),
        if (!isLoading && total <= 0) ...[
          const SizedBox(height: 6),
          Text(
            'Sin datos para graficar',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _StatusReadableList extends StatelessWidget {
  final List<_StatusEntry> entries;
  final int total;

  const _StatusReadableList({required this.entries, required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nonZero = entries.where((e) => e.value > 0).toList();
    final shown = nonZero.isEmpty ? entries : nonZero;

    String pct(int v) {
      if (total <= 0) return '0%';
      final p = (v * 100 / total).round();
      return '$p%';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Detalle por estado',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.75),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        for (final e in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: e.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    e.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${e.value}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  pct(e.value),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.65),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StatusLegend extends StatelessWidget {
  final List<_StatusEntry> entries;

  const _StatusLegend({required this.entries});

  @override
  Widget build(BuildContext context) {
    final nonZero = entries.where((e) => e.value > 0).toList();
    final total = nonZero.fold<int>(0, (acc, e) => acc + e.value);

    if (total <= 0) return const SizedBox.shrink();

    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        for (final e in nonZero)
          _LegendItem(color: e.color, label: e.label, value: e.value),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int value;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$value',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            fontWeight: FontWeight.w800,
          ),
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
