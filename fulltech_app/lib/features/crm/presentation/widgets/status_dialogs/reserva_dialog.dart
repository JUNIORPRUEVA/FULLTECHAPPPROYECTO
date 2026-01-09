import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../catalogo/state/catalog_providers.dart';
import '../../../../presupuesto/state/quotation_builder_controller.dart';
import '../../../../usuarios/state/users_providers.dart';

class ReservaDialogResult {
  final DateTime fechaReserva;
  final TimeOfDay horaReserva;
  final String descripcionProducto;
  final String? productId;
  final String nota;
  final double? montoReserva;
  final String? tecnicoId;
  final String? tecnicoAsignado;
  final String? quotationId;
  final String? comentario;

  ReservaDialogResult({
    required this.fechaReserva,
    required this.horaReserva,
    required this.descripcionProducto,
    this.productId,
    required this.nota,
    this.montoReserva,
    this.tecnicoId,
    this.tecnicoAsignado,
    this.quotationId,
    this.comentario,
  });

  Map<String, dynamic> toJson() {
    return {
      'fecha_reserva': fechaReserva.toIso8601String(),
      'hora_reserva':
          '${horaReserva.hour.toString().padLeft(2, '0')}:${horaReserva.minute.toString().padLeft(2, '0')}',
      'descripcion_producto': descripcionProducto,
      'product_id': productId,
      'nota': nota,
      'monto_reserva': montoReserva,
      'tecnico_id': tecnicoId,
      'tecnico_asignado': tecnicoAsignado,
      'quotation_id': quotationId,
      'comentario': comentario,
    };
  }
}

class ReservaDialog extends ConsumerStatefulWidget {
  const ReservaDialog({super.key});

  @override
  ConsumerState<ReservaDialog> createState() => _ReservaDialogState();
}

class _ReservaDialogState extends ConsumerState<ReservaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _productoController = TextEditingController();
  final _montoController = TextEditingController();
  final _notasController = TextEditingController();
  final _comentarioController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  String? _selectedProductId;
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
    _productoController.dispose();
    _montoController.dispose();
    _notasController.dispose();
    _comentarioController.dispose();
    super.dispose();
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
        _productoController.text = created.nombre;
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

      final result = ReservaDialogResult(
        fechaReserva: _selectedDate,
        horaReserva: _selectedTime,
        descripcionProducto: _productoController.text.trim(),
        productId: _selectedProductId,
        nota: _notasController.text.trim(),
        montoReserva: _montoController.text.isNotEmpty
            ? double.tryParse(_montoController.text.replaceAll(',', ''))
            : null,
        tecnicoId: _selectedTecnicoId,
        tecnicoAsignado: tecnicoName,
        quotationId: _selectedQuotationId,
        comentario: _comentarioController.text.trim().isEmpty
            ? null
            : _comentarioController.text.trim(),
      );
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('dd/MM/yyyy');
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Registrar Reserva'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fecha de reserva
                Text(
                  'Fecha de reserva *',
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

                // Producto del catálogo (opcional)
                Consumer(
                  builder: (context, ref, child) {
                    final catalog = ref.watch(catalogControllerProvider);
                    final productos = catalog.productos;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Producto del catálogo (opcional)',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
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
                                _productoController.text = selected.nombre;
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

                // Hora de reserva
                Text(
                  'Hora de reserva *',
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

                // Descripción del producto/servicio
                TextFormField(
                  controller: _productoController,
                  decoration: const InputDecoration(
                    labelText: 'Producto/Servicio *',
                    border: OutlineInputBorder(),
                    hintText: 'Ej: Laptop HP 15", Mantenimiento preventivo',
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Este campo es requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Monto de reserva (opcional)
                TextFormField(
                  controller: _montoController,
                  decoration: const InputDecoration(
                    labelText: 'Monto de reserva (opcional)',
                    border: OutlineInputBorder(),
                    prefixText: '\$ ',
                    hintText: '0.00',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final parsed = double.tryParse(value.replaceAll(',', ''));
                      if (parsed == null) {
                        return 'Ingrese un monto válido';
                      }
                      if (parsed < 0) {
                        return 'El monto no puede ser negativo';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Técnico (opcional)
                Text(
                  'Técnico (opcional)',
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
                      onChanged: (v) => setState(() => _selectedTecnicoId = v),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Presupuesto (opcional)
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
                            child: Text(q.label, overflow: TextOverflow.ellipsis),
                          );
                        }),
                      ],
                      onChanged: (v) => setState(() => _selectedQuotationId = v),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Nota (obligatoria)
                TextFormField(
                  controller: _notasController,
                  decoration: const InputDecoration(
                    labelText: 'Nota *',
                    border: OutlineInputBorder(),
                    hintText: 'Información adicional sobre la reserva',
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'La nota es obligatoria';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),
                TextFormField(
                  controller: _comentarioController,
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
        ElevatedButton(
          onPressed: _handleSubmit,
          child: const Text('Guardar Reserva'),
        ),
      ],
    );
  }
}
