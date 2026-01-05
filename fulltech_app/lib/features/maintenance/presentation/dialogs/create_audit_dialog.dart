import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/maintenance_models.dart';
import '../../providers/maintenance_provider.dart';

class CreateAuditDialog extends ConsumerStatefulWidget {
  const CreateAuditDialog({super.key});

  @override
  ConsumerState<CreateAuditDialog> createState() => _CreateAuditDialogState();
}

class _CreateAuditDialogState extends ConsumerState<CreateAuditDialog> {
  final _formKey = GlobalKey<FormState>();

  DateTime? _from;
  DateTime? _to;
  final _weekLabelCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _weekLabelCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFrom() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      initialDate: _from ?? now,
    );
    if (picked == null) return;
    setState(() => _from = DateTime(picked.year, picked.month, picked.day));
    _maybeAutoWeekLabel();
  }

  Future<void> _pickTo() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      initialDate: _to ?? _from ?? now,
    );
    if (picked == null) return;
    setState(() => _to = DateTime(picked.year, picked.month, picked.day));
    _maybeAutoWeekLabel();
  }

  void _maybeAutoWeekLabel() {
    if (_weekLabelCtrl.text.trim().isNotEmpty) return;
    if (_from == null) return;
    _weekLabelCtrl.text = DateFormat("yyyy-'W'ww").format(_from!);
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '';
    return DateFormat('dd/MM/yyyy').format(d);
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    setState(() => _saving = true);
    try {
      final dto = CreateAuditDto(
        auditFromDate: _from!,
        auditToDate: _to!,
        weekLabel: _weekLabelCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      await ref.read(auditsControllerProvider.notifier).createAudit(dto);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo crear la auditoría.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva auditoría'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saving ? null : _pickFrom,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          _from == null ? 'Desde' : 'Desde: ${_fmtDate(_from)}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saving ? null : _pickTo,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          _to == null ? 'Hasta' : 'Hasta: ${_fmtDate(_to)}',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _weekLabelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Etiqueta semana (ej: 2026-W02)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requerido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notas (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Tip: luego podrás agregar items por producto en el detalle.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _submit,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: const Text('Crear'),
        ),
      ],
    );
  }
}
