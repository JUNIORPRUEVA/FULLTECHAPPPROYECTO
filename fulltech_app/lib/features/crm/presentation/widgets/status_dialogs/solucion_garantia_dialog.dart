import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class SolucionGarantiaDialogResult {
  final DateTime? fechaSolucion;
  final TimeOfDay? horaSolucion;
  final String productoServicio;
  final String detalles;
  final String? tecnicoId;
  final String? tecnicoResponsable;
  final bool clienteSatisfecho;

  SolucionGarantiaDialogResult({
    this.fechaSolucion,
    this.horaSolucion,
    required this.productoServicio,
    required this.detalles,
    this.tecnicoId,
    this.tecnicoResponsable,
    required this.clienteSatisfecho,
  });

  Map<String, dynamic> toJson() {
    return {
      'fecha_solucion': fechaSolucion?.toIso8601String(),
      'hora_solucion': horaSolucion != null
          ? '${horaSolucion!.hour.toString().padLeft(2, '0')}:${horaSolucion!.minute.toString().padLeft(2, '0')}'
          : null,
      'producto_servicio': productoServicio,
      'detalles': detalles,
      'tecnico_id': tecnicoId,
      'tecnico_responsable': tecnicoResponsable,
      'cliente_satisfecho': clienteSatisfecho,
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

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedTecnicoId;
  bool _clienteSatisfecho = true;

  @override
  void dispose() {
    _productoController.dispose();
    _detallesController.dispose();
    super.dispose();
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
      // Get selected technician name if tecnico ID is set
      String? tecnicoName;
      if (_selectedTecnicoId != null) {
        // TODO: Implement techniciansListProvider
        // final techniciansAsync = ref.read(techniciansListProvider);
        // techniciansAsync.whenData((technicians) {
        //   final tech = technicians.firstWhere(
        //     (t) => t.id == _selectedTecnicoId,
        //   );
        //   tecnicoName = tech.fullName;
        // });
        tecnicoName = 'Técnico';
      }

      final result = SolucionGarantiaDialogResult(
        fechaSolucion: _selectedDate,
        horaSolucion: _selectedTime,
        productoServicio: _productoController.text.trim(),
        detalles: _detallesController.text.trim(),
        tecnicoId: _selectedTecnicoId,
        tecnicoResponsable: tecnicoName,
        clienteSatisfecho: _clienteSatisfecho,
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
                Consumer(
                  builder: (context, ref, child) {
                    // TODO: Implement techniciansListProvider
                    return DropdownButtonFormField<String>(
                      initialValue: null,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Técnicos no disponibles',
                      ),
                      items: const [],
                      onChanged: null,
                    );
                  },
                ),
                const SizedBox(height: 16),

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
