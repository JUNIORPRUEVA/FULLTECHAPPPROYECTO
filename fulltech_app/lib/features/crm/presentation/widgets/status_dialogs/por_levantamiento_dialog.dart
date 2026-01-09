import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/providers/services_provider.dart';
import '../../../../usuarios/state/users_providers.dart';
import '../../../../catalogo/state/catalog_providers.dart';
import '../../../../presupuesto/state/quotation_builder_controller.dart';

class PorLevantamientoDialogResult {
  final String customerName;
  final String customerPhone;
  final double gpsLat;
  final double gpsLng;
  final String addressText;
  final String notes;
  final String? serviceId;
  final String? productId;
  final String? tipoServicio;
  final String vendedorAsignadoUserId;
  final String? tecnicoId;
  final String? tecnicoAsignado;
  final String? quotationId;
  final String? comentario;

  PorLevantamientoDialogResult({
    required this.customerName,
    required this.customerPhone,
    required this.gpsLat,
    required this.gpsLng,
    required this.addressText,
    required this.notes,
    this.serviceId,
    this.productId,
    required this.vendedorAsignadoUserId,
    this.tipoServicio,
    this.tecnicoId,
    this.tecnicoAsignado,
    this.quotationId,
    this.comentario,
  });

  Map<String, dynamic> toJson() {
    return {
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'location_gps_lat': gpsLat,
      'location_gps_lng': gpsLng,
      'address_text': addressText,
      'notes': notes,
      if (serviceId != null && serviceId!.trim().isNotEmpty)
        'interested_service_id': serviceId,
      if (productId != null && productId!.trim().isNotEmpty)
        'interested_product_id': productId,
      if (tipoServicio != null && tipoServicio!.trim().isNotEmpty)
        'tipo_servicio': tipoServicio!.trim(),
      'vendedor_asignado_user_id': vendedorAsignadoUserId,
      if (tecnicoId != null && tecnicoId!.trim().isNotEmpty)
        'tecnico_id': tecnicoId,
      if (tecnicoAsignado != null && tecnicoAsignado!.trim().isNotEmpty)
        'tecnico_asignado': tecnicoAsignado,
      if (quotationId != null && quotationId!.trim().isNotEmpty)
        'quotation_id': quotationId,
      if (comentario != null && comentario!.trim().isNotEmpty)
        'comentario': comentario!.trim(),
    };
  }
}

class PorLevantamientoDialog extends ConsumerStatefulWidget {
  const PorLevantamientoDialog({super.key});

  @override
  ConsumerState<PorLevantamientoDialog> createState() =>
      _PorLevantamientoDialogState();
}

class _PorLevantamientoDialogState
    extends ConsumerState<PorLevantamientoDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _tipoServicioCtrl = TextEditingController();
  final _comentarioCtrl = TextEditingController();

  String? _selectedServiceId;
  String? _selectedProductId;
  String? _selectedVendedorId;
  String? _selectedTecnicoId;
  String? _selectedQuotationId;
  Map<String, String> _techniciansById = const {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(catalogControllerProvider.notifier).loadCategorias();
      ref.read(catalogControllerProvider.notifier).loadProductos();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    _tipoServicioCtrl.dispose();
    _comentarioCtrl.dispose();
    super.dispose();
  }

  String _digitsOnly(String v) => v.replaceAll(RegExp(r'\D+'), '');

  double? _parseDouble(String v) {
    final normalized = v.trim().replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  Future<List<({String id, String nombre})>> _loadTechnicians() async {
    final repo = ref.read(usersRepositoryProvider);

    final tecnicoPage = await repo.listUsers(
      page: 1,
      pageSize: 200,
      rol: 'tecnico',
      estado: 'activo',
    );

    final contratistaPage = await repo.listUsers(
      page: 1,
      pageSize: 200,
      rol: 'contratista',
      estado: 'activo',
    );

    final map = <String, String>{
      for (final u in tecnicoPage.items) u.id: u.nombre,
      for (final u in contratistaPage.items) u.id: u.nombre,
    };

    _techniciansById = Map.unmodifiable(map);

    final out = map.entries
        .map((e) => (id: e.key, nombre: e.value))
        .toList(growable: false);
    out.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    return out;
  }

  Future<List<({String id, String label})>> _loadQuotations() async {
    final api = ref.read(quotationApiProvider);
    final items = await api.listQuotations(limit: 50, offset: 0);

    String s(dynamic v) => (v ?? '').toString();

    final out = <({String id, String label})>[];
    for (final it in items) {
      final id = s(it['id']).trim();
      if (id.isEmpty) continue;
      final numero = s(it['numero'] ?? it['quotation_number']).trim();
      final customer = s(it['customer_name'] ?? it['customerName']).trim();
      final label = [
        if (numero.isNotEmpty) '#$numero',
        if (customer.isNotEmpty) customer,
      ].join(' • ');
      out.add((id: id, label: label.isEmpty ? id : label));
    }
    return out;
  }

  Future<void> _createServiceFromDialog() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    double? parsePrice(String v) {
      final t = v.trim();
      if (t.isEmpty) return null;
      final normalized = t.replaceAll(',', '.');
      return double.tryParse(normalized);
    }

    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) {
          final formKey = GlobalKey<FormState>();
          return AlertDialog(
            title: const Text('Agregar servicio'),
            content: SizedBox(
              width: 480,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Este campo es requerido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Descripción (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: priceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Precio por defecto (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        final parsed = parsePrice(v ?? '');
                        if ((v ?? '').trim().isNotEmpty && parsed == null) {
                          return 'Ingrese un precio válido';
                        }
                        if (parsed != null && parsed < 0) {
                          return 'El precio no puede ser negativo';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton.icon(
                onPressed: () {
                  if (formKey.currentState?.validate() != true) return;
                  Navigator.of(context).pop(true);
                },
                icon: const Icon(Icons.add),
                label: const Text('Agregar'),
              ),
            ],
          );
        },
      );
      if (ok != true) return;

      final repo = ref.read(servicesRepositoryProvider);
      final service = await repo.createService(
        name: nameCtrl.text.trim(),
        description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
        defaultPrice: parsePrice(priceCtrl.text),
      );

      ref.invalidate(activeServicesProvider);
      if (!mounted) return;

      setState(() {
        _selectedServiceId = service.id;
        if (_tipoServicioCtrl.text.trim().isEmpty) {
          _tipoServicioCtrl.text = service.name;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Servicio "${service.name}" agregado')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al agregar servicio: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      nameCtrl.dispose();
      descCtrl.dispose();
      priceCtrl.dispose();
    }
  }

  Future<void> _createProductFromDialog() async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    String? selectedCategoriaId;

    double parsePriceOrZero(String v) {
      final t = v.trim();
      if (t.isEmpty) return 0;
      final normalized = t.replaceAll(',', '.');
      return double.tryParse(normalized) ?? 0;
    }

    try {
      final controller = ref.read(catalogControllerProvider.notifier);
      if (ref.read(catalogControllerProvider).categorias.isEmpty) {
        await controller.loadCategorias();
      }
      final cats = ref.read(catalogControllerProvider).categorias;
      selectedCategoriaId = cats.isNotEmpty ? cats.first.id : null;

      final ok = await showDialog<bool>(
        context: context,
        builder: (context) {
          final formKey = GlobalKey<FormState>();
          return AlertDialog(
            title: const Text('Agregar producto'),
            content: SizedBox(
              width: 520,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Este campo es requerido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCategoriaId,
                      decoration: const InputDecoration(
                        labelText: 'Categoría *',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final c in cats)
                          DropdownMenuItem<String>(
                            value: c.id,
                            child: Text(c.nombre),
                          ),
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Seleccione una categoría';
                        }
                        return null;
                      },
                      onChanged: (v) => selectedCategoriaId = v,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: priceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Precio venta (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton.icon(
                onPressed: () {
                  if (formKey.currentState?.validate() != true) return;
                  Navigator.of(context).pop(true);
                },
                icon: const Icon(Icons.add),
                label: const Text('Agregar'),
              ),
            ],
          );
        },
      );
      if (ok != true) return;

      final categoriaId = (selectedCategoriaId ?? '').trim();
      if (categoriaId.isEmpty) {
        throw Exception('No hay categorías disponibles. Cree una categoría primero.');
      }

      final created = await controller.createProducto(
        nombre: nameCtrl.text.trim(),
        precioCompra: 0,
        precioVenta: parsePriceOrZero(priceCtrl.text),
        imagenUrl: '',
        categoriaId: categoriaId,
      );
      if (created == null) return;
      if (!mounted) return;

      setState(() {
        _selectedProductId = created.id;
        if (_tipoServicioCtrl.text.trim().isEmpty) {
          _tipoServicioCtrl.text = created.nombre;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Producto "${created.nombre}" agregado')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al agregar producto: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      nameCtrl.dispose();
      priceCtrl.dispose();
    }
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    if ((_selectedServiceId == null || _selectedServiceId!.trim().isEmpty) &&
        (_selectedProductId == null || _selectedProductId!.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccione un servicio o un producto'),
        ),
      );
      return;
    }

    final lat = _parseDouble(_latCtrl.text)!;
    final lng = _parseDouble(_lngCtrl.text)!;

    final tecnicoName = _selectedTecnicoId == null
        ? null
        : _techniciansById[_selectedTecnicoId!];

    final result = PorLevantamientoDialogResult(
      customerName: _nameCtrl.text.trim(),
      customerPhone: _digitsOnly(_phoneCtrl.text.trim()),
      gpsLat: lat,
      gpsLng: lng,
      addressText: _addressCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
      serviceId: _selectedServiceId,
      productId: _selectedProductId,
      vendedorAsignadoUserId: _selectedVendedorId!,
      tipoServicio: _tipoServicioCtrl.text.trim().isEmpty
          ? null
          : _tipoServicioCtrl.text.trim(),
      tecnicoId: _selectedTecnicoId,
      tecnicoAsignado: tecnicoName,
      quotationId: _selectedQuotationId,
      comentario: _comentarioCtrl.text.trim().isEmpty
          ? null
          : _comentarioCtrl.text.trim(),
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Por levantamiento'),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del cliente *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Este campo es requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono del cliente *',
                    border: OutlineInputBorder(),
                    hintText: 'Ej: 8095551234',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    final digits = _digitsOnly(v ?? '');
                    if (digits.isEmpty) return 'Este campo es requerido';
                    if (digits.length < 8) return 'Número inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Servicio
                Text(
                  'Servicio (opcional)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Consumer(
                  builder: (context, ref, _) {
                    final servicesAsync = ref.watch(activeServicesProvider);
                    return servicesAsync.when(
                      data: (services) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DropdownButtonFormField<String>(
                              initialValue: _selectedServiceId,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Seleccione un servicio',
                              ),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('-- Sin servicio --'),
                                ),
                                for (final s in services)
                                  DropdownMenuItem<String>(
                                    value: s.id,
                                    child: Text(s.name),
                                  ),
                              ],
                              onChanged: (v) {
                                setState(() {
                                  _selectedServiceId = v;
                                  if (v != null) {
                                    final selected = services.firstWhere(
                                      (e) => e.id == v,
                                      orElse: () => services.first,
                                    );
                                    if (_tipoServicioCtrl.text.trim().isEmpty) {
                                      _tipoServicioCtrl.text = selected.name;
                                    }
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: OutlinedButton.icon(
                                onPressed: _createServiceFromDialog,
                                icon: const Icon(Icons.add),
                                label: const Text('Agregar servicio'),
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (err, _) => Text('Error cargando servicios: $err'),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Producto (opcional)
                Text(
                  'Producto (opcional)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Consumer(
                  builder: (context, ref, _) {
                    final catalog = ref.watch(catalogControllerProvider);
                    final productos = catalog.productos;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _selectedProductId,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Seleccione un producto',
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('-- Sin producto --'),
                            ),
                            ...productos.map((p) {
                              return DropdownMenuItem<String>(
                                value: p.id,
                                child: Text(p.nombre),
                              );
                            }),
                          ],
                          onChanged: (v) {
                            setState(() {
                              _selectedProductId = v;
                              if (v != null) {
                                final selected = productos.firstWhere(
                                  (p) => p.id == v,
                                  orElse: () => productos.first,
                                );
                                if (_tipoServicioCtrl.text.trim().isEmpty) {
                                  _tipoServicioCtrl.text = selected.nombre;
                                }
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: _createProductFromDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar producto'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tipoServicioCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de servicio (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // Técnico asignado (opcional)
                Text(
                  'Técnico asignado (opcional)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                FutureBuilder<List<({String id, String nombre})>>(
                  future: _loadTechnicians(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const LinearProgressIndicator();
                    }
                    if (snapshot.hasError) {
                      return InputDecorator(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        child: Text('Error cargando técnicos: ${snapshot.error}'),
                      );
                    }
                    final techs = snapshot.data ??
                        const <({String id, String nombre})>[];
                    return DropdownButtonFormField<String>(
                      initialValue: _selectedTecnicoId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Seleccione un técnico',
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('-- Sin técnico --'),
                        ),
                        ...techs.map((t) {
                          return DropdownMenuItem<String>(
                            value: t.id,
                            child: Text(t.nombre),
                          );
                        }),
                      ],
                      onChanged: (v) => setState(() => _selectedTecnicoId = v),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Vendedor asignado
                Text(
                  'Vendedor asignado *',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Consumer(
                  builder: (context, ref, _) {
                    final repo = ref.watch(usersRepositoryProvider);
                    final vendorsAsync = ref.watch(
                      FutureProvider.autoDispose((ref) async {
                        final page = await repo.listUsers(
                          page: 1,
                          pageSize: 100,
                          rol: 'vendedor',
                          estado: 'activo',
                        );
                        return page.items;
                      }),
                    );

                    return vendorsAsync.when(
                      data: (vendors) {
                        return DropdownButtonFormField<String>(
                          initialValue: _selectedVendedorId,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Seleccione un vendedor',
                          ),
                          items: [
                            for (final u in vendors)
                              DropdownMenuItem<String>(
                                value: u.id,
                                child: Text(u.nombre),
                              ),
                          ],
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Seleccione un vendedor';
                            }
                            return null;
                          },
                          onChanged: (v) {
                            setState(() => _selectedVendedorId = v);
                          },
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (err, _) =>
                          Text('Error cargando vendedores: $err'),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Presupuesto (opcional)
                Text(
                  'Presupuesto (opcional)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                FutureBuilder<List<({String id, String label})>>(
                  future: _loadQuotations(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const LinearProgressIndicator();
                    }
                    if (snapshot.hasError) {
                      return InputDecorator(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        child: Text('No disponible: ${snapshot.error}'),
                      );
                    }
                    final items = snapshot.data ??
                        const <({String id, String label})>[];
                    return DropdownButtonFormField<String>(
                      initialValue: _selectedQuotationId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Seleccione un presupuesto',
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('-- Sin presupuesto --'),
                        ),
                        ...items.map((q) {
                          return DropdownMenuItem<String>(
                            value: q.id,
                            child: Text(q.label, overflow: TextOverflow.ellipsis),
                          );
                        }),
                      ],
                      onChanged: (v) => setState(() => _selectedQuotationId = v),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Ubicación
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latCtrl,
                        decoration: const InputDecoration(
                          labelText: 'GPS Lat *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        validator: (v) {
                          final parsed = _parseDouble(v ?? '');
                          if (parsed == null) return 'Lat inválida';
                          if (parsed < -90 || parsed > 90)
                            return 'Rango -90 a 90';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lngCtrl,
                        decoration: const InputDecoration(
                          labelText: 'GPS Lng *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        validator: (v) {
                          final parsed = _parseDouble(v ?? '');
                          if (parsed == null) return 'Lng inválida';
                          if (parsed < -180 || parsed > 180) {
                            return 'Rango -180 a 180';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Dirección *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Este campo es requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notas *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Este campo es requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _comentarioCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Comentario (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _handleSubmit,
          icon: const Icon(Icons.check),
          label: const Text('Guardar'),
        ),
      ],
    );
  }
}
