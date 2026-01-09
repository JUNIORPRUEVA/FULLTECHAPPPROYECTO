import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/app_config.dart';
import '../../../catalogo/models/categoria_producto.dart';
import '../../../catalogo/state/catalog_providers.dart';
import '../../data/models/maintenance_models.dart';
import '../../providers/maintenance_provider.dart';

String _publicUrlFromMaybeRelative(String raw) {
  final v = raw.trim();
  if (v.isEmpty) return '';
  if (v.startsWith('http://') || v.startsWith('https://')) return v;

  final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/api$'), '');
  if (v.startsWith('/')) return '$base$v';
  return '$base/$v';
}

String _maintenanceTypeLabel(MaintenanceType type) {
  switch (type) {
    case MaintenanceType.verificacion:
      return 'Verificación';
    case MaintenanceType.limpieza:
      return 'Limpieza';
    case MaintenanceType.diagnostico:
      return 'Diagnóstico';
    case MaintenanceType.reparacion:
      return 'Reparación';
    case MaintenanceType.garantia:
      return 'Garantía';
    case MaintenanceType.ajusteInventario:
      return 'Ajuste inventario';
    case MaintenanceType.otro:
      return 'Otro';
  }
}

String _healthStatusLabel(ProductHealthStatus status) {
  switch (status) {
    case ProductHealthStatus.okVerificado:
      return 'OK verificado';
    case ProductHealthStatus.conProblema:
      return 'Con problema';
    case ProductHealthStatus.enGarantia:
      return 'En garantía';
    case ProductHealthStatus.perdido:
      return 'Perdido';
    case ProductHealthStatus.danadoSinGarantia:
      return 'Dañado (sin garantía)';
    case ProductHealthStatus.reparado:
      return 'Reparado';
    case ProductHealthStatus.enRevision:
      return 'En revisión';
  }
}

String _stripDiacritics(String s) {
  return s
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ñ', 'n');
}

IssueCategory _mapCatalogCategoryNameToIssueCategory(String rawName) {
  final name = _stripDiacritics(rawName.toLowerCase().trim());
  if (name.contains('electr')) return IssueCategory.electrico;
  if (name.contains('pantalla')) return IssueCategory.pantalla;
  if (name.contains('bateri')) return IssueCategory.bateria;
  if (name.contains('accesor')) return IssueCategory.accesorios;
  if (name.contains('softw')) return IssueCategory.software;
  if (name.contains('fisic')) return IssueCategory.fisico;
  if (name.contains('otro')) return IssueCategory.otro;
  return IssueCategory.otro;
}

class CreateMaintenanceDialog extends ConsumerStatefulWidget {
  const CreateMaintenanceDialog({super.key});

  @override
  ConsumerState<CreateMaintenanceDialog> createState() =>
      _CreateMaintenanceDialogState();
}

class _CreateMaintenanceDialogState
    extends ConsumerState<CreateMaintenanceDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _productoId;
  MaintenanceType _maintenanceType = MaintenanceType.verificacion;
  ProductHealthStatus _statusAfter = ProductHealthStatus.okVerificado;
  String? _categoriaId;
  IssueCategory? _issueCategory;

  late final Future<List<CategoriaProducto>> _categoriesFuture;

  final _descriptionCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _costCtrl = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = ref
        .read(catalogApiProvider)
        .listCategorias(includeInactive: true);
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    _notesCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  double? _parseCost() {
    final raw = _costCtrl.text.trim();
    if (raw.isEmpty) return null;
    final normalized = raw.replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;
    if (_productoId == null || _productoId!.trim().isEmpty) return;

    final dto = CreateMaintenanceDto(
      productoId: _productoId!,
      maintenanceType: _maintenanceType,
      statusAfter: _statusAfter,
      issueCategory: _issueCategory,
      description: _descriptionCtrl.text.trim(),
      internalNotes: _notesCtrl.text.trim().isEmpty
          ? null
          : _notesCtrl.text.trim(),
      cost: _parseCost(),
    );

    setState(() => _saving = true);
    try {
      await ref
          .read(maintenanceControllerProvider.notifier)
          .createMaintenance(dto);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo crear el mantenimiento.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(maintenanceProductsProvider);

    return AlertDialog(
      title: const Text('Nuevo mantenimiento'),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                productsAsync.when(
                  data: (items) {
                    return DropdownButtonFormField<String>(
                      initialValue: _productoId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Producto',
                        border: OutlineInputBorder(),
                      ),
                      items: items
                          .map(
                            (p) => DropdownMenuItem<String>(
                              value: p.id,
                              child: Row(
                                children: [
                                  if (p.imagenUrl.trim().isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.network(
                                        _publicUrlFromMaybeRelative(
                                          p.imagenUrl,
                                        ),
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
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _productoId = v),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Selecciona un producto'
                          : null,
                    );
                  },
                  error: (_, __) =>
                      const Text('No se pudieron cargar productos.'),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: LinearProgressIndicator(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<MaintenanceType>(
                        initialValue: _maintenanceType,
                        decoration: const InputDecoration(
                          labelText: 'Tipo',
                          border: OutlineInputBorder(),
                        ),
                        items: MaintenanceType.values
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(_maintenanceTypeLabel(t)),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(
                          () => _maintenanceType = v ?? _maintenanceType,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<ProductHealthStatus>(
                        initialValue: _statusAfter,
                        decoration: const InputDecoration(
                          labelText: 'Estado después',
                          border: OutlineInputBorder(),
                        ),
                        items: ProductHealthStatus.values
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(_healthStatusLabel(s)),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _statusAfter = v ?? _statusAfter),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<CategoriaProducto>>(
                  future: _categoriesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return DropdownButtonFormField<String?>(
                        initialValue: _categoriaId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Categoría (opcional)',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Cargando categorías...'),
                          ),
                        ],
                        onChanged: null,
                      );
                    }

                    final cats = (snapshot.data ?? const <CategoriaProducto>[])
                        .toList()
                      ..sort((a, b) => a.nombre.compareTo(b.nombre));

                    if (snapshot.hasError || cats.isEmpty) {
                      return DropdownButtonFormField<String?>(
                        initialValue: _categoriaId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Categoría (opcional)',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Sin categoría'),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _categoriaId = null;
                            _issueCategory = null;
                          });
                        },
                      );
                    }

                    return DropdownButtonFormField<String?>(
                      initialValue: _categoriaId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Categoría (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Sin categoría'),
                        ),
                        ...cats.map(
                          (c) => DropdownMenuItem<String?>(
                            value: c.id,
                            child: Text(c.nombre),
                          ),
                        ),
                      ],
                      onChanged: (id) {
                        if (id == null) {
                          setState(() {
                            _categoriaId = null;
                            _issueCategory = null;
                          });
                          return;
                        }

                        CategoriaProducto? selected;
                        for (final c in cats) {
                          if (c.id == id) {
                            selected = c;
                            break;
                          }
                        }

                        setState(() {
                          _categoriaId = id;
                          _issueCategory = selected == null
                              ? IssueCategory.otro
                              : _mapCatalogCategoryNameToIssueCategory(
                                  selected.nombre,
                                );
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Describe el mantenimiento'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notas internas (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _costCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Costo (opcional)',
                    border: OutlineInputBorder(),
                    prefixText: 'RD\$ ',
                  ),
                  validator: (v) {
                    final raw = v?.trim() ?? '';
                    if (raw.isEmpty) return null;
                    return _parseCost() == null ? 'Costo inválido' : null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _submit,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: const Text('Crear'),
        ),
      ],
    );
  }
}
