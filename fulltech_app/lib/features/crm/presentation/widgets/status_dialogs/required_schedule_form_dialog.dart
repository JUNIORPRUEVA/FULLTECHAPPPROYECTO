import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../services/providers/services_provider.dart';
import '../../../state/crm_providers.dart';

class RequiredScheduleFormResult {
  final DateTime scheduledAt;
  final String locationText;
  final double latitude;
  final double longitude;
  final String assignedTechnicianId;
  final String serviceId;
  final String assignedType;

  const RequiredScheduleFormResult({
    required this.scheduledAt,
    required this.locationText,
    required this.latitude,
    required this.longitude,
    required this.assignedTechnicianId,
    required this.serviceId,
    required this.assignedType,
  });

  Map<String, dynamic> toJson() {
    return {
      'scheduledAt': scheduledAt.toIso8601String(),
      'locationText': locationText,
      'latitude': latitude,
      'longitude': longitude,
      'assignedTechnicianId': assignedTechnicianId,
      'serviceId': serviceId,
      'assignedType': assignedType,
    };
  }
}

class RequiredScheduleFormDialog extends ConsumerStatefulWidget {
  final String title;
  final DateTime? initialDateTime;

  const RequiredScheduleFormDialog({
    super.key,
    required this.title,
    this.initialDateTime,
  });

  @override
  ConsumerState<RequiredScheduleFormDialog> createState() =>
      _RequiredScheduleFormDialogState();
}

class _RequiredScheduleFormDialogState
    extends ConsumerState<RequiredScheduleFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  final _locationCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _assignedTypeCtrl = TextEditingController();

  String? _technicianId;
  String? _serviceId;

  bool _canSubmit = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDateTime ?? DateTime.now();
    _selectedDate = DateTime(initial.year, initial.month, initial.day);
    _selectedTime = TimeOfDay(hour: initial.hour, minute: initial.minute);

    _locationCtrl.addListener(_recomputeCanSubmit);
    _latCtrl.addListener(_recomputeCanSubmit);
    _lngCtrl.addListener(_recomputeCanSubmit);
    _assignedTypeCtrl.addListener(_recomputeCanSubmit);
  }

  @override
  void dispose() {
    _locationCtrl
      ..removeListener(_recomputeCanSubmit)
      ..dispose();
    _latCtrl
      ..removeListener(_recomputeCanSubmit)
      ..dispose();
    _lngCtrl
      ..removeListener(_recomputeCanSubmit)
      ..dispose();
    _assignedTypeCtrl
      ..removeListener(_recomputeCanSubmit)
      ..dispose();
    super.dispose();
  }

  void _recomputeCanSubmit() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (valid == _canSubmit) return;
    setState(() => _canSubmit = valid);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _selectedDate = picked;
    });
    _recomputeCanSubmit();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked == null) return;
    setState(() {
      _selectedTime = picked;
    });
    _recomputeCanSubmit();
  }

  double? _parseDouble(String raw) {
    final v = raw.trim().replaceAll(',', '.');
    return double.tryParse(v);
  }

  String? _requiredTextValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Este campo es requerido';
    return null;
  }

  String? _latitudeValidator(String? v) {
    final parsed = _parseDouble(v ?? '');
    if (parsed == null) return 'Latitud inválida';
    if (parsed < -90 || parsed > 90) return 'Latitud fuera de rango (-90 a 90)';
    return null;
  }

  String? _longitudeValidator(String? v) {
    final parsed = _parseDouble(v ?? '');
    if (parsed == null) return 'Longitud inválida';
    if (parsed < -180 || parsed > 180) {
      return 'Longitud fuera de rango (-180 a 180)';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_technicianId == null || _technicianId!.trim().isEmpty) return;
    if (_serviceId == null || _serviceId!.trim().isEmpty) return;

    final scheduledAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final latitude = _parseDouble(_latCtrl.text) ?? 0;
    final longitude = _parseDouble(_lngCtrl.text) ?? 0;

    Navigator.of(context).pop(
      RequiredScheduleFormResult(
        scheduledAt: scheduledAt,
        locationText: _locationCtrl.text.trim(),
        latitude: latitude,
        longitude: longitude,
        assignedTechnicianId: _technicianId!,
        serviceId: _serviceId!,
        assignedType: _assignedTypeCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormatter = DateFormat('dd/MM/yyyy');

    final techniciansAsync = ref.watch(crmTechniciansProvider);
    final servicesAsync = ref.watch(activeServicesProvider);

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: _recomputeCanSubmit,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Fecha y hora *',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(dateFormatter.format(_selectedDate)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: _pickTime,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.access_time),
                          ),
                          child: Text(_selectedTime.format(context)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Ubicación *',
                    border: OutlineInputBorder(),
                  ),
                  validator: _requiredTextValidator,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          signed: true,
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Latitud *',
                          border: OutlineInputBorder(),
                        ),
                        validator: _latitudeValidator,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lngCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          signed: true,
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Longitud *',
                          border: OutlineInputBorder(),
                        ),
                        validator: _longitudeValidator,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                techniciansAsync.when(
                  data: (techs) {
                    return DropdownButtonFormField<String>(
                      value: _technicianId,
                      decoration: const InputDecoration(
                        labelText: 'Técnico asignado *',
                        border: OutlineInputBorder(),
                      ),
                      items: techs
                          .map(
                            (t) => DropdownMenuItem<String>(
                              value: t.id,
                              child: Text(t.nombreCompleto),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (v) {
                        setState(() => _technicianId = v);
                        _recomputeCanSubmit();
                      },
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Este campo es requerido'
                          : null,
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error cargando técnicos: $e'),
                ),
                const SizedBox(height: 16),
                servicesAsync.when(
                  data: (services) {
                    return DropdownButtonFormField<String>(
                      value: _serviceId,
                      decoration: const InputDecoration(
                        labelText: 'Servicio *',
                        border: OutlineInputBorder(),
                      ),
                      items: services
                          .map(
                            (s) => DropdownMenuItem<String>(
                              value: s.id,
                              child: Text(s.name),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (v) {
                        setState(() => _serviceId = v);
                        _recomputeCanSubmit();
                      },
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Este campo es requerido'
                          : null,
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error cargando servicios: $e'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _assignedTypeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tipo asignado (producto/servicio) *',
                    border: OutlineInputBorder(),
                  ),
                  validator: _requiredTextValidator,
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
        FilledButton(
          onPressed: _canSubmit ? _submit : null,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
