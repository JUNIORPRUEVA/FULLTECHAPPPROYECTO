import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/maintenance_models.dart';
import '../../providers/maintenance_provider.dart';

class EditMaintenanceDialog extends ConsumerStatefulWidget {
  final MaintenanceRecord record;

  const EditMaintenanceDialog({super.key, required this.record});

  @override
  ConsumerState<EditMaintenanceDialog> createState() =>
      _EditMaintenanceDialogState();
}

class _EditMaintenanceDialogState extends ConsumerState<EditMaintenanceDialog> {
  late final TextEditingController _description;
  late final TextEditingController _internalNotes;
  late final TextEditingController _cost;

  late MaintenanceType _maintenanceType;
  late ProductHealthStatus _statusAfter;
  IssueCategory? _issueCategory;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.record;
    _description = TextEditingController(text: r.description);
    _internalNotes = TextEditingController(text: r.internalNotes ?? '');
    _cost = TextEditingController(
      text: r.cost == null ? '' : r.cost!.toStringAsFixed(2),
    );

    _maintenanceType = r.maintenanceType;
    _statusAfter = r.statusAfter;
    _issueCategory = r.issueCategory;
  }

  @override
  void dispose() {
    _description.dispose();
    _internalNotes.dispose();
    _cost.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final desc = _description.text.trim();
    if (desc.isEmpty) return;

    double? cost;
    final rawCost = _cost.text.trim();
    if (rawCost.isNotEmpty) {
      final normalized = rawCost.replaceAll(',', '.');
      cost = double.tryParse(normalized);
    }

    final updates = <String, dynamic>{
      'maintenance_type': _maintenanceType.name.toUpperCase(),
      'status_after': _statusAfter.name.toUpperCase(),
      'description': desc,
      if (_issueCategory != null)
        'issue_category': _issueCategory!.name.toUpperCase(),
      if (_internalNotes.text.trim().isNotEmpty)
        'internal_notes': _internalNotes.text.trim(),
      if (cost != null) 'cost': cost,
    };

    setState(() => _saving = true);
    try {
      await ref
          .read(maintenanceControllerProvider.notifier)
          .updateMaintenance(widget.record.id, updates);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.record;

    return AlertDialog(
      title: const Text('Editar mantenimiento'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                r.producto?.nombre ?? 'Producto #${r.productoId}',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<MaintenanceType>(
                value: _maintenanceType,
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: MaintenanceType.values
                    .map(
                      (v) => DropdownMenuItem(
                        value: v,
                        child: Text(_maintenanceTypeLabel(v)),
                      ),
                    )
                    .toList(),
                onChanged: _saving
                    ? null
                    : (v) {
                        if (v == null) return;
                        setState(() => _maintenanceType = v);
                      },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ProductHealthStatus>(
                value: _statusAfter,
                decoration: const InputDecoration(
                  labelText: 'Estado después',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: ProductHealthStatus.values
                    .map(
                      (v) => DropdownMenuItem(
                        value: v,
                        child: Text(_healthStatusLabel(v)),
                      ),
                    )
                    .toList(),
                onChanged: _saving
                    ? null
                    : (v) {
                        if (v == null) return;
                        setState(() => _statusAfter = v);
                      },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<IssueCategory?>(
                value: _issueCategory,
                decoration: const InputDecoration(
                  labelText: 'Categoría (opcional)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<IssueCategory?>(
                    value: null,
                    child: Text('Sin categoría'),
                  ),
                  ...IssueCategory.values.map(
                    (v) => DropdownMenuItem<IssueCategory?>(
                      value: v,
                      child: Text(_issueCategoryLabel(v)),
                    ),
                  ),
                ],
                onChanged: _saving ? null : (v) => setState(() => _issueCategory = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _description,
                enabled: !_saving,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _internalNotes,
                enabled: !_saving,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notas internas (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _cost,
                enabled: !_saving,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Costo (opcional)',
                  border: OutlineInputBorder(),
                  prefixText: 'RD\$ ',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}

String _maintenanceTypeLabel(MaintenanceType t) {
  switch (t) {
    case MaintenanceType.verificacion:
      return 'Verificación';
    case MaintenanceType.limpieza:
      return 'Limpieza';
    case MaintenanceType.diagnostico:
      return 'Diagnóstico';
    case MaintenanceType.reparacion:
      return 'Reparación';
    case MaintenanceType.garantia:
      return 'Garantía';
    case MaintenanceType.ajusteInventario:
      return 'Ajuste inventario';
    case MaintenanceType.otro:
      return 'Otro';
  }
}

String _healthStatusLabel(ProductHealthStatus s) {
  switch (s) {
    case ProductHealthStatus.okVerificado:
      return 'OK verificado';
    case ProductHealthStatus.conProblema:
      return 'Con problema';
    case ProductHealthStatus.enGarantia:
      return 'En garantía';
    case ProductHealthStatus.perdido:
      return 'Perdido';
    case ProductHealthStatus.danadoSinGarantia:
      return 'Dañado sin garantía';
    case ProductHealthStatus.reparado:
      return 'Reparado';
    case ProductHealthStatus.enRevision:
      return 'En revisión';
  }
}

String _issueCategoryLabel(IssueCategory c) {
  switch (c) {
    case IssueCategory.electrico:
      return 'Eléctrico';
    case IssueCategory.pantalla:
      return 'Pantalla';
    case IssueCategory.bateria:
      return 'Batería';
    case IssueCategory.accesorios:
      return 'Accesorios';
    case IssueCategory.software:
      return 'Software';
    case IssueCategory.fisico:
      return 'Físico';
    case IssueCategory.otro:
      return 'Otro';
  }
}
