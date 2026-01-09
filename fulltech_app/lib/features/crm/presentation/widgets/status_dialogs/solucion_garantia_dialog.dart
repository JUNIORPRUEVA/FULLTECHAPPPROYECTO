import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../catalogo/state/catalog_providers.dart';
import '../../../../presupuesto/state/quotation_builder_controller.dart';
import '../../../../usuarios/state/users_providers.dart';

class SolucionGarantiaDialogResult {
  final DateTime? fechaSolucion;
  final TimeOfDay? horaSolucion;
  final String productoServicio;
  final String? productId;
  final String? quotationId;
  final String detalles;
  final String? tecnicoId;
  final String? tecnicoResponsable;
  final bool clienteSatisfecho;
  final String? comentario;

  SolucionGarantiaDialogResult({
    this.fechaSolucion,
    this.horaSolucion,
    required this.productoServicio,
    this.productId,
    this.quotationId,
    required this.detalles,
    this.tecnicoId,
    this.tecnicoResponsable,
    required this.clienteSatisfecho,
    this.comentario,
  });

  Map<String, dynamic> toJson() {
    return {
      'fecha_solucion': fechaSolucion?.toIso8601String(),
      'hora_solucion': horaSolucion != null
          ? '${horaSolucion!.hour.toString().padLeft(2, '0')}:${horaSolucion!.minute.toString().padLeft(2, '0')}'
          : null,
      'producto_servicio': productoServicio,
      'product_id': productId,
      'quotation_id': quotationId,
      'detalles': detalles,
      'tecnico_id': tecnicoId,
      'tecnico_responsable': tecnicoResponsable,
      'cliente_satisfecho': clienteSatisfecho,
      'comentario': comentario,
    };
  }
}

class SolucionGarantiaDialog extends ConsumerStatefulWidget {
  const SolucionGarantiaDialog({super.key});

  @override
  ConsumerState<SolucionGarantiaDialog> createState() =>
      _SolucionGarantiaDialogState();
}

class _SolucionGarantiaDialogState
    extends ConsumerState<SolucionGarantiaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _productoController = TextEditingController();
  final _detallesController = TextEditingController();
  final _comentarioController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedTecnicoId;
  String? _selectedProductId;
  String? _selectedQuotationId;
  Map<String, String> _techniciansById = const {};
  bool _clienteSatisfecho = true;

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
    _detallesController.dispose();
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
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
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

      final result = SolucionGarantiaDialogResult(
        fechaSolucion: _selectedDate,
        horaSolucion: _selectedTime,
        productoServicio: _productoController.text.trim(),
        productId: _selectedProductId,
        quotationId: _selectedQuotationId,
        detalles: _detallesController.text.trim(),
        tecnicoId: _selectedTecnicoId,
        tecnicoResponsable: tecnicoName,
        clienteSatisfecho: _clienteSatisfecho,
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
      title: const Text('Registrar Solución de Garantía'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fecha de solución (opcional)
                Text(
                  'Fecha de solución (opcional)',
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
                    child: Text(
                      _selectedDate != null
                          ? dateFormatter.format(_selectedDate!)
                          : 'Seleccionar fecha',
                      style: TextStyle(
                        color: _selectedDate == null
                            ? theme.textTheme.bodyMedium?.color?.withOpacity(
                                0.6,
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Hora de solución (opcional)
                Text(
                  'Hora de solución (opcional)',
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
                    child: Text(
                      _selectedTime != null
                          ? _selectedTime!.format(context)
                          : 'Seleccionar hora',
                      style: TextStyle(
                        color: _selectedTime == null
                            ? theme.textTheme.bodyMedium?.color?.withOpacity(
                                0.6,
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Producto/Servicio
                Text(
                  'Producto del catálogo (opcional)',
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
                const SizedBox(height: 12),
                TextFormField(
                  controller: _productoController,
                  decoration: const InputDecoration(
                    labelText: 'Producto/Servicio *',
                    border: OutlineInputBorder(),
                    hintText: 'Producto o servicio de garantía',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Este campo es requerido';
                    }
                    return null;
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

                // Detalles
                TextFormField(
                  controller: _detallesController,
                  decoration: const InputDecoration(
                    labelText: 'Detalles *',
                    border: OutlineInputBorder(),
                    hintText: 'Describa la solución aplicada',
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Este campo es requerido';
                    }
                    if (value.trim().length < 10) {
                      return 'Los detalles deben tener al menos 10 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Técnico responsable
                Text(
                  'Técnico responsable (opcional)',
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

                // Comentario
                TextFormField(
                  controller: _comentarioController,
                  decoration: const InputDecoration(
                    labelText: 'Comentario (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),

                // Cliente satisfecho
                CheckboxListTile(
                  title: const Text('Cliente satisfecho con la solución'),
                  value: _clienteSatisfecho,
                  onChanged: (value) {
                    setState(() {
                      _clienteSatisfecho = value ?? true;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
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
          child: const Text('Registrar Solución'),
        ),
      ],
    );
  }
}
