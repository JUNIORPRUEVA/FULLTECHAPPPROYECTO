import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../services/providers/services_provider.dart';
import '../../../state/crm_providers.dart';

class ServicioReservadoDialogResult {
  final DateTime scheduledAt;
  final String priority; // BAJA/MEDIA/ALTA
  final String? productId;
  final String? serviceId;
  final String? assignedTechnicianId;
  final String note;

  const ServicioReservadoDialogResult({
    required this.scheduledAt,
    required this.priority,
    required this.productId,
    required this.serviceId,
    required this.assignedTechnicianId,
    required this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'scheduledAt': scheduledAt.toIso8601String(),
      'priority': priority,
      'productId': productId,
      'serviceId': serviceId,
      'assignedTechnicianId': assignedTechnicianId,
      'note': note,
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
  final _noteCtrl = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _priority = 'MEDIA';
  String? _productId;
  String? _serviceId;
  String? _technicianId;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked == null) return;
    setState(() => _selectedTime = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_productId == null && _serviceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione un producto o un servicio')),
      );
      return;
    }

    final scheduledAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    Navigator.of(context).pop(
      ServicioReservadoDialogResult(
        scheduledAt: scheduledAt,
        priority: _priority,
        productId: _productId,
        serviceId: _serviceId,
        assignedTechnicianId: _technicianId,
        note: _noteCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormatter = DateFormat('dd/MM/yyyy');

    final productsAsync = ref.watch(crmProductsProvider);
    final servicesAsync = ref.watch(activeServicesProvider);
    final techniciansAsync = ref.watch(crmTechniciansProvider);

    Widget inlineError({
      required String message,
      required VoidCallback onRetry,
    }) {
      final cs = theme.colorScheme;
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

    return AlertDialog(
      title: const Text('Servicio reservado'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Fecha y hora *',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
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
                DropdownButtonFormField<String>(
                  value: _priority,
                  decoration: const InputDecoration(
                    labelText: 'Prioridad *',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'BAJA', child: Text('Baja')),
                    DropdownMenuItem(value: 'MEDIA', child: Text('Media')),
                    DropdownMenuItem(value: 'ALTA', child: Text('Alta')),
                  ],
                  onChanged: (v) => setState(() => _priority = v ?? 'MEDIA'),
                ),
                const SizedBox(height: 16),
                productsAsync.when(
                  data: (items) {
                    final active = items.where((p) => p.isActive).toList();
                    return DropdownButtonFormField<String?>(
                      value: _productId,
                      decoration: const InputDecoration(
                        labelText: 'Producto (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('-- Sin producto --'),
                        ),
                        ...active.map(
                          (p) => DropdownMenuItem<String?>(
                            value: p.id,
                            child: Text(p.nombre),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _productId = v),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, st) {
                    debugPrint('[CRM] products load failed: $e');
                    debugPrintStack(stackTrace: st);
                    return inlineError(
                      message: 'No se pudieron cargar productos',
                      onRetry: () => ref.invalidate(crmProductsProvider),
                    );
                  },
                ),
                const SizedBox(height: 16),
                servicesAsync.when(
                  data: (services) {
                    return DropdownButtonFormField<String?>(
                      value: _serviceId,
                      decoration: const InputDecoration(
                        labelText: 'Servicio (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('-- Sin servicio --'),
                        ),
                        ...services.map(
                          (s) => DropdownMenuItem<String?>(
                            value: s.id,
                            child: Text(s.name),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _serviceId = v),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, st) {
                    debugPrint('[CRM] services load failed: $e');
                    debugPrintStack(stackTrace: st);
                    return inlineError(
                      message: 'No se pudieron cargar servicios',
                      onRetry: () => ref.invalidate(activeServicesProvider),
                    );
                  },
                ),
                const SizedBox(height: 16),
                techniciansAsync.when(
                  data: (techs) {
                    return DropdownButtonFormField<String?>(
                      value: _technicianId,
                      decoration: const InputDecoration(
                        labelText: 'Técnico (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('-- Sin asignar --'),
                        ),
                        ...techs.map(
                          (t) => DropdownMenuItem<String?>(
                            value: t.id,
                            child: Text(
                              t.telefono.trim().isEmpty
                                  ? t.nombreCompleto
                                  : '${t.nombreCompleto} • ${t.telefono.trim()}',
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _technicianId = v),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, st) {
                    debugPrint('[CRM] technicians load failed: $e');
                    debugPrintStack(stackTrace: st);
                    return inlineError(
                      message: 'No se pudieron cargar técnicos',
                      onRetry: () => ref.invalidate(crmTechniciansProvider),
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noteCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Nota / indicaciones *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Este campo es requerido';
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
        FilledButton(onPressed: _submit, child: const Text('Guardar')),
      ],
    );
  }
}
