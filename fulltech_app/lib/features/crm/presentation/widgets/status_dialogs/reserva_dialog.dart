import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReservaDialogResult {
  final DateTime fechaReserva;
  final TimeOfDay horaReserva;
  final String descripcionProducto;
  final String nota;
  final double? montoReserva;

  ReservaDialogResult({
    required this.fechaReserva,
    required this.horaReserva,
    required this.descripcionProducto,
    required this.nota,
    this.montoReserva,
  });

  Map<String, dynamic> toJson() {
    return {
      'fecha_reserva': fechaReserva.toIso8601String(),
      'hora_reserva':
          '${horaReserva.hour.toString().padLeft(2, '0')}:${horaReserva.minute.toString().padLeft(2, '0')}',
      'descripcion_producto': descripcionProducto,
      'nota': nota,
      'monto_reserva': montoReserva,
    };
  }
}

class ReservaDialog extends StatefulWidget {
  const ReservaDialog({super.key});

  @override
  State<ReservaDialog> createState() => _ReservaDialogState();
}

class _ReservaDialogState extends State<ReservaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _productoController = TextEditingController();
  final _montoController = TextEditingController();
  final _notasController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void dispose() {
    _productoController.dispose();
    _montoController.dispose();
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
      final result = ReservaDialogResult(
        fechaReserva: _selectedDate,
        horaReserva: _selectedTime,
        descripcionProducto: _productoController.text.trim(),
        nota: _notasController.text.trim(),
        montoReserva: _montoController.text.isNotEmpty
            ? double.tryParse(_montoController.text.replaceAll(',', ''))
            : null,
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
