import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../services/providers/services_provider.dart';

class ServicioReservadoDialogResult {
  final DateTime fechaServicio;
  final TimeOfDay horaServicio;
  final String? serviceId;
  final String tipoServicio;
  final String? ubicacion;
  final String? tecnicoId;
  final String? tecnicoAsignado;
  final String? notasAdicionales;

  ServicioReservadoDialogResult({
    required this.fechaServicio,
    required this.horaServicio,
    this.serviceId,
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
      'tipo_servicio': tipoServicio,
      'ubicacion': ubicacion,
      'tecnico_id': tecnicoId,
      'tecnico_asignado': tecnicoAsignado,
      'notas_adicionales': notasAdicionales,
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
  String? _selectedTecnicoId;

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

      final result = ServicioReservadoDialogResult(
        fechaServicio: _selectedDate,
        horaServicio: _selectedTime,
        serviceId: _selectedServiceId,
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
                        return DropdownButtonFormField<String>(
                          value: _selectedServiceId,
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
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (err, stack) =>
                          Text('Error cargando servicios: $err'),
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
                    hintText: 'Ej: Instalación, Mantenimiento, Reparación',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Este campo es requerido';
                    }
                    return null;
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

                // Técnico asignado
                Text(
                  'Técnico asignado (opcional)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Consumer(
                  builder: (context, ref, child) {
                    // TODO: Implement techniciansListProvider
                    return DropdownButtonFormField<String>(
                      value: null,
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
