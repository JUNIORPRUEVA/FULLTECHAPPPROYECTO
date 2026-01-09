import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/providers/services_provider.dart';
import '../../../state/crm_providers.dart';

class ProblemStatusDialogResult {
  final String priority; // BAJA/MEDIA/ALTA
  final String? productId;
  final String? serviceId;
  final String? assignedTechnicianId;
  final String problemDescription;
  final String? note;

  const ProblemStatusDialogResult({
    required this.priority,
    required this.productId,
    required this.serviceId,
    required this.assignedTechnicianId,
    required this.problemDescription,
    required this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'priority': priority,
      'productId': productId,
      'serviceId': serviceId,
      'assignedTechnicianId': assignedTechnicianId,
      'problemDescription': problemDescription,
      'note': note,
    };
  }
}

class ProblemStatusDialog extends ConsumerStatefulWidget {
  final String title;

  const ProblemStatusDialog({
    super.key,
    required this.title,
  });

  @override
  ConsumerState<ProblemStatusDialog> createState() => _ProblemStatusDialogState();
}

class _ProblemStatusDialogState extends ConsumerState<ProblemStatusDialog> {
  final _formKey = GlobalKey<FormState>();
  final _problemCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String _priority = 'MEDIA';
  String? _productId;
  String? _serviceId;
  String? _technicianId;

  @override
  void dispose() {
    _problemCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      ProblemStatusDialogResult(
        priority: _priority,
        productId: _productId,
        serviceId: _serviceId,
        assignedTechnicianId: _technicianId,
        problemDescription: _problemCtrl.text.trim(),
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(crmProductsProvider);
    final servicesAsync = ref.watch(activeServicesProvider);
    final techniciansAsync = ref.watch(crmTechniciansProvider);

    return AlertDialog(
      title: Text(widget.title),
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
                  controller: _problemCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Descripción del problema *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Este campo es requerido';
                    }
                    if (value.trim().length < 10) {
                      return 'Mínimo 10 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noteCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notas (opcional)',
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
          onPressed: _submit,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

