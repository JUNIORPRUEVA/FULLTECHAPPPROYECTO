import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../services/providers/services_provider.dart';
import '../../../../usuarios/state/users_providers.dart';
import '../../../../catalogo/state/catalog_providers.dart';
import '../../../../presupuesto/state/quotation_builder_controller.dart';

class ServicioReservadoDialogResult {
  final DateTime fechaServicio;
  final TimeOfDay horaServicio;
  final String? serviceId;
  final String? productId;
  final String? quotationId;
  final String tipoServicio;
  final String? ubicacion;
  final String? tecnicoId;
  final String? tecnicoAsignado;
  final String? notasAdicionales;

  ServicioReservadoDialogResult({
    required this.fechaServicio,
    required this.horaServicio,
    this.serviceId,
    this.productId,
    this.quotationId,
    required this.tipoServicio,
    this.ubicacion,
    this.tecnicoId,
    this.tecnicoAsignado,
    this.notasAdicionales,
  });

  Map<String, dynamic> toJson() {
    return {
      'fecha_servicio': fechaServicio.toIso8601String(),
      'hora_servicio':
          '${horaServicio.hour.toString().padLeft(2, '0')}:${horaServicio.minute.toString().padLeft(2, '0')}',
      'service_id': serviceId,
      'product_id': productId,
      'quotation_id': quotationId,
      'tipo_servicio': tipoServicio,
      'ubicacion': ubicacion,
      'tecnico_id': tecnicoId,
      'tecnico_asignado': tecnicoAsignado,
      'notas_adicionales': notasAdicionales,
      'comentario': notasAdicionales,
    };
  }
}

class ServicioReservadoDialog extends ConsumerStatefulWidget {
  const ServicioReservadoDialog({super.key});

  @override
  ConsumerState<ServicioReservadoDialog> createState() =>
      _ServicioReservadoDialogState();
}

class _ServicioReservadoDialogState
    extends ConsumerState<ServicioReservadoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tipoServicioController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _notasController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String? _selectedServiceId;
  String? _selectedProductId;
  String? _selectedQuotationId;
  String? _selectedTecnicoId;
  Map<String, String> _techniciansById = const {};

  @override
  void initState() {
    super.initState();
    // Ensure catálogo data is available for product selector.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(catalogControllerProvider.notifier).loadCategorias();
      ref.read(catalogControllerProvider.notifier).loadProductos();
    });
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
      final state = ref.read(catalogControllerProvider);

      if (state.categorias.isEmpty) {
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
        if (_tipoServicioController.text.trim().isEmpty) {
          _tipoServicioController.text = created.nombre;
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
      final created = await showDialog<bool>(
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

      if (created != true) return;

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
        _tipoServicioController.text = service.name;
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

  @override
  void dispose() {
    _tipoServicioController.dispose();
    _ubicacionController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      final tecnicoName = _selectedTecnicoId == null
          ? null
          : _techniciansById[_selectedTecnicoId!];

      final result = ServicioReservadoDialogResult(
        fechaServicio: _selectedDate,
        horaServicio: _selectedTime,
        serviceId: _selectedServiceId,
        productId: _selectedProductId,
        quotationId: _selectedQuotationId,
        tipoServicio: _tipoServicioController.text.trim(),
        ubicacion: _ubicacionController.text.isNotEmpty
            ? _ubicacionController.text.trim()
            : null,
        tecnicoId: _selectedTecnicoId,
        tecnicoAsignado: tecnicoName,
        notasAdicionales: _notasController.text.isNotEmpty
            ? _notasController.text.trim()
            : null,
      );
      Navigator.of(context).pop(result);
    }
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

    // Keep a cached lookup for submit.
    _techniciansById = Map.unmodifiable(map);

    final out = map.entries
        .map((e) => (id: e.key, nombre: e.value))
        .toList(growable: false);

    out.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('dd/MM/yyyy');
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Agendar Servicio'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fecha del servicio
                Text(
                  'Fecha del servicio *',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(dateFormatter.format(_selectedDate)),
                  ),
                ),
                const SizedBox(height: 16),

                // Hora del servicio
                Text(
                  'Hora del servicio *',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _selectTime,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.access_time),
                    ),
                    child: Text(_selectedTime.format(context)),
                  ),
                ),
                const SizedBox(height: 16),

                // Service selector (optional)
                Text(
                  'Servicio (opcional)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Consumer(
                  builder: (context, ref, child) {
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
                                ...services.map((service) {
                                  return DropdownMenuItem<String>(
                                    value: service.id,
                                    child: Text(service.name),
                                  );
                                }),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedServiceId = value;
                                  // Auto-fill tipo_servicio if service selected
                                  if (value != null) {
                                    final selectedService = services.firstWhere(
                                      (s) => s.id == value,
                                    );
                                    _tipoServicioController.text =
                                        selectedService.name;
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
                      error: (err, stack) =>
                          Text('Error cargando servicios: $err'),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Producto (opcional)
                Text(
                  'Producto (opcional)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Consumer(
                  builder: (context, ref, child) {
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
                          onChanged: (value) {
                            setState(() {
                              _selectedProductId = value;
                              if (value != null) {
                                final selected = productos.firstWhere(
                                  (p) => p.id == value,
                                  orElse: () => productos.first,
                                );
                                if (_tipoServicioController.text.trim().isEmpty) {
                                  _tipoServicioController.text = selected.nombre;
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
                const SizedBox(height: 16),

                // Tipo de servicio
                TextFormField(
                  controller: _tipoServicioController,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de servicio *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Este campo es requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Técnico asignado (opcional)
                Text(
                  'Técnico asignado (opcional)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
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
                      onChanged: (value) {
                        setState(() {
                          _selectedTecnicoId = value;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Ubicación
                TextFormField(
                  controller: _ubicacionController,
                  decoration: const InputDecoration(
                    labelText: 'Ubicación (opcional)',
                    border: OutlineInputBorder(),
                    hintText: 'Dirección donde se realizará el servicio',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Presupuesto/Cotización (opcional)
                Text(
                  'Presupuesto (opcional)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
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
                            child: Text(
                              q.label,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedQuotationId = value;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Notas adicionales
                TextFormField(
                  controller: _notasController,
                  decoration: const InputDecoration(
                    labelText: 'Notas adicionales (opcional)',
                    border: OutlineInputBorder(),
                    hintText: 'Información adicional sobre el servicio',
                  ),
                  maxLines: 3,
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
        ElevatedButton(
          onPressed: _handleSubmit,
          child: const Text('Agendar Servicio'),
        ),
      ],
    );
  }
}
