import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/providers/services_provider.dart';
import '../../../state/crm_providers.dart';

class PorLevantamientoDialogResult {
  final String priority; // BAJA/MEDIA/ALTA
  final String? productId;
  final String? serviceId;
  final String? assignedTechnicianId;
  final String note;

  const PorLevantamientoDialogResult({
    required this.priority,
    required this.productId,
    required this.serviceId,
    required this.assignedTechnicianId,
    required this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'priority': priority,
      'productId': productId,
      'serviceId': serviceId,
      'assignedTechnicianId': assignedTechnicianId,
      'note': note,
    };
  }
}

class PorLevantamientoDialog extends ConsumerStatefulWidget {
  const PorLevantamientoDialog({super.key});

  @override
  ConsumerState<PorLevantamientoDialog> createState() =>
      _PorLevantamientoDialogState();
}

class _PorLevantamientoDialogState extends ConsumerState<PorLevantamientoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _noteCtrl = TextEditingController();

  String _priority = 'MEDIA';
  String? _productId;
  String? _serviceId;
  String? _technicianId;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      PorLevantamientoDialogResult(
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
    final productsAsync = ref.watch(crmProductsProvider);
    final servicesAsync = ref.watch(activeServicesProvider);
    final techniciansAsync = ref.watch(crmTechniciansProvider);

    return AlertDialog(
      title: const Text('Por levantamiento'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
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
                  error: (e, _) => Text('Error cargando productos: $e'),
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
                  error: (e, _) => Text('Error cargando servicios: $e'),
                ),
                const SizedBox(height: 16),
                techniciansAsync.when(
                  data: (techs) {
                    return DropdownButtonFormField<String?>(
                      value: _technicianId,
                      decoration: const InputDecoration(
                        labelText: 'Asignar técnico (opcional)',
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
                            child: Text(t.nombreCompleto),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _technicianId = v),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error cargando técnicos: $e'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noteCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Nota / requerimiento *',
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
        FilledButton(
          onPressed: _submit,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

