import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../../../services/providers/services_provider.dart';
import '../../../state/crm_providers.dart';

class RequiredScheduleFormResult {
  final DateTime scheduledAt;
  final String address;
  final String? note;
  final String assignedTechnicianId;
  final String serviceId;

  const RequiredScheduleFormResult({
    required this.scheduledAt,
    required this.address,
    required this.note,
    required this.assignedTechnicianId,
    required this.serviceId,
  });

  Map<String, dynamic> toJson() {
    return {
      'scheduledAt': scheduledAt.toIso8601String(),
      'address': address,
      // Backward compatible with older CRM API payloads.
      'locationText': address,
      'note': note,
      'assignedTechnicianId': assignedTechnicianId,
      'serviceId': serviceId,
    };
  }
}

class _InlineLoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _InlineLoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(message, style: TextStyle(color: cs.error)),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
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
  final _technicianFieldKey = GlobalKey<FormFieldState<String>>();
  final _serviceFieldKey = GlobalKey<FormFieldState<String>>();

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  final _addressCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String? _technicianId;
  String? _serviceId;

  bool _canSubmit = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDateTime ?? DateTime.now();
    _selectedDate = DateTime(initial.year, initial.month, initial.day);
    _selectedTime = TimeOfDay(hour: initial.hour, minute: initial.minute);

    _addressCtrl.addListener(_recomputeCanSubmit);
    _noteCtrl.addListener(_recomputeCanSubmit);
  }

  @override
  void dispose() {
    _addressCtrl
      ..removeListener(_recomputeCanSubmit)
      ..dispose();
    _noteCtrl
      ..removeListener(_recomputeCanSubmit)
      ..dispose();
    super.dispose();
  }

  String? _requiredTextValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Este campo es requerido';
    return null;
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

  Future<void> _pickService() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (_) => _ServicePickerDialog(initialSelectedId: _serviceId),
    );
    if (selected == null) return;
    if (!mounted) return;
    setState(() => _serviceId = selected);
    _serviceFieldKey.currentState?.didChange(selected);
    _recomputeCanSubmit();
  }

  void _clearServiceSelection() {
    if (_serviceId == null) return;
    setState(() => _serviceId = null);
    _serviceFieldKey.currentState?.didChange(null);
    _recomputeCanSubmit();
  }

  static String _serviceErrorMessage(Object e) {
    if (e is DioException) {
      final status = e.response?.statusCode;
      if (status == 409) return 'Ya existe un servicio con ese nombre';
      if (status == 400 || status == 422) return 'Nombre de servicio inválido';
      if (status == 401 || status == 403) {
        return 'No tienes permisos para crear servicios';
      }
      return 'No se pudo crear el servicio';
    }
    return 'No se pudo crear el servicio';
  }

  Future<void> _createServiceInline() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _CreateServiceDialog(),
    );
    if (name == null || name.trim().isEmpty) return;

    try {
      final repo = ref.read(servicesRepositoryProvider);
      final created = await repo.createService(name: name.trim());
      ref.invalidate(activeServicesProvider);
      if (!mounted) return;
      setState(() => _serviceId = created.id);
      _serviceFieldKey.currentState?.didChange(created.id);
      _recomputeCanSubmit();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_serviceErrorMessage(e))),
      );
    }
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

    Navigator.of(context).pop(
      RequiredScheduleFormResult(
        scheduledAt: scheduledAt,
        address: _addressCtrl.text.trim(),
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        assignedTechnicianId: _technicianId!,
        serviceId: _serviceId!,
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
                  'Fecha y hora (Agenda) *',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
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
                  controller: _addressCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Dirección *',
                    hintText: 'Ej: Calle 123, Ciudad',
                    border: OutlineInputBorder(),
                  ),
                  validator: _requiredTextValidator,
                ),
                const SizedBox(height: 16),
                techniciansAsync.when(
                  data: (techs) {
                    return FormField<String>(
                      key: _technicianFieldKey,
                      initialValue: _technicianId,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Este campo es requerido'
                          : null,
                      builder: (field) {
                        return InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Técnico asignado *',
                            border: const OutlineInputBorder(),
                            errorText: field.errorText,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _technicianId,
                              hint: const Text('Seleccione un técnico'),
                              items: techs
                                  .map(
                                    (t) => DropdownMenuItem<String>(
                                      value: t.id,
                                      child: Text(
                                          t.telefono.trim().isEmpty
                                              ? t.nombreCompleto
                                              : '${t.nombreCompleto} — ${t.telefono.trim()}',
                                        ),
                                      ),
                                    )
                                  .toList(growable: false),
                              onChanged: (v) {
                                setState(() => _technicianId = v);
                                field.didChange(v);
                                _recomputeCanSubmit();
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, st) {
                    debugPrint('[CRM] technicians load failed: $e');
                    debugPrintStack(stackTrace: st);
                    return _InlineLoadError(
                      message: 'No se pudieron cargar técnicos',
                      onRetry: () => ref.invalidate(crmTechniciansProvider),
                    );
                  },
                ),
                const SizedBox(height: 16),
                FormField<String>(
                  key: _serviceFieldKey,
                  initialValue: _serviceId,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Seleccione un servicio'
                      : null,
                  builder: (field) {
                    return servicesAsync.when(
                      data: (services) {
                        final selectedName = _serviceId == null
                            ? null
                            : services
                                  .where((s) => s.id == _serviceId)
                                  .map((s) => s.name)
                                  .cast<String?>()
                                  .firstWhere((_) => true, orElse: () => null);

                        return InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Servicio *',
                            border: const OutlineInputBorder(),
                            errorText: field.errorText,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  selectedName ?? 'Ninguno seleccionado',
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: _pickService,
                                child: const Text('Elegir'),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: _createServiceInline,
                                child: const Text('Crear'),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: 'Quitar servicio',
                                onPressed: _serviceId == null
                                    ? null
                                    : _clearServiceSelection,
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (e, st) {
                        debugPrint('[CRM] services load failed: $e');
                        debugPrintStack(stackTrace: st);
                        return _InlineLoadError(
                          message: 'No se pudieron cargar servicios',
                          onRetry: () => ref.invalidate(activeServicesProvider),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noteCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Nota (opcional)',
                    hintText: 'Ej: referencia, acceso, indicaciones…',
                    border: OutlineInputBorder(),
                  ),
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

class _ServicePickerDialog extends ConsumerStatefulWidget {
  final String? initialSelectedId;

  const _ServicePickerDialog({this.initialSelectedId});

  @override
  ConsumerState<_ServicePickerDialog> createState() =>
      _ServicePickerDialogState();
}

class _ServicePickerDialogState extends ConsumerState<_ServicePickerDialog> {
  String? _selectedId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.initialSelectedId;
  }

  Future<void> _createService() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _CreateServiceDialog(),
    );
    if (name == null || name.trim().isEmpty) return;

    setState(() => _busy = true);
    try {
      final repo = ref.read(servicesRepositoryProvider);
      final created = await repo.createService(name: name.trim());
      ref.invalidate(activeServicesProvider);
      if (!mounted) return;
      setState(() => _selectedId = created.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_RequiredScheduleFormDialogState._serviceErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteService(String id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Eliminar servicio'),
          content: Text('¿Eliminar "$name"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    setState(() => _busy = true);
    try {
      final repo = ref.read(servicesRepositoryProvider);
      await repo.deleteService(id);
      ref.invalidate(activeServicesProvider);
      if (!mounted) return;
      if (_selectedId == id) setState(() => _selectedId = null);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar el servicio: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(activeServicesProvider);
    return AlertDialog(
      title: const Text('Servicios'),
      content: SizedBox(
        width: 520,
        child: servicesAsync.when(
          data: (services) {
            if (services.isEmpty) {
              return const Text('No hay servicios activos.');
            }

            return ListView.separated(
              shrinkWrap: true,
              itemCount: services.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final s = services[index];
                return ListTile(
                  dense: true,
                  leading: Radio<String>(
                    value: s.id,
                    groupValue: _selectedId,
                    onChanged: _busy
                        ? null
                        : (v) => setState(() => _selectedId = v),
                  ),
                  title: Text(s.name),
                  onTap: _busy
                      ? null
                      : () => setState(() => _selectedId = s.id),
                  trailing: IconButton(
                    tooltip: 'Eliminar servicio',
                    onPressed: _busy
                        ? null
                        : () => _deleteService(s.id, s.name),
                    icon: const Icon(Icons.delete_outline),
                  ),
                );
              },
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (e, st) {
            debugPrint('[CRM] services load failed (picker): $e');
            debugPrintStack(stackTrace: st);
            return _InlineLoadError(
              message: 'No se pudieron cargar servicios',
              onRetry: () => ref.invalidate(activeServicesProvider),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        OutlinedButton(
          onPressed: _busy ? null : _createService,
          child: const Text('Crear'),
        ),
        FilledButton(
          onPressed: (_busy || _selectedId == null)
              ? null
              : () => Navigator.of(context).pop(_selectedId),
          child: const Text('Seleccionar'),
        ),
      ],
    );
  }
}

class _CreateServiceDialog extends StatefulWidget {
  const _CreateServiceDialog();

  @override
  State<_CreateServiceDialog> createState() => _CreateServiceDialogState();
}

class _CreateServiceDialogState extends State<_CreateServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crear servicio'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: TextFormField(
            controller: _nameCtrl,
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
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop(_nameCtrl.text.trim());
          },
          child: const Text('Crear'),
        ),
      ],
    );
  }
}
