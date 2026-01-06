import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/pos_models.dart';
import '../../state/pos_providers.dart';

class PosSupplierFormDialog extends ConsumerStatefulWidget {
  const PosSupplierFormDialog({super.key, this.initial});

  final PosSupplier? initial;

  @override
  ConsumerState<PosSupplierFormDialog> createState() => _PosSupplierFormDialogState();
}

class _PosSupplierFormDialogState extends ConsumerState<PosSupplierFormDialog> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _rnc = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    if (s != null) {
      _name.text = s.name;
      _phone.text = s.phone ?? '';
      _rnc.text = s.rnc ?? '';
      _email.text = s.email ?? '';
      _address.text = s.address ?? '';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _rnc.dispose();
    _email.dispose();
    _address.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      _toast('El nombre es requerido');
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(posRepositoryProvider);
      final phone = _phone.text.trim();
      final rnc = _rnc.text.trim();
      final email = _email.text.trim();
      final address = _address.text.trim();

      final result = widget.initial == null
          ? await repo.createSupplier(
              name: name,
              phone: phone.isEmpty ? null : phone,
              rnc: rnc.isEmpty ? null : rnc,
              email: email.isEmpty ? null : email,
              address: address.isEmpty ? null : address,
            )
          : await repo.updateSupplier(
              widget.initial!.id,
              name: name,
              phone: phone.isEmpty ? null : phone,
              rnc: rnc.isEmpty ? null : rnc,
              email: email.isEmpty ? null : email,
              address: address.isEmpty ? null : address,
            );

      if (!mounted) return;
      Navigator.pop(context, result);
    } catch (e) {
      _toast('Error guardando: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;

    return AlertDialog(
      title: Text(isEdit ? 'Editar proveedor' : 'Nuevo proveedor'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nombre *'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phone,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _rnc,
                decoration: const InputDecoration(labelText: 'RNC'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _address,
                decoration: const InputDecoration(labelText: 'Dirección'),
                minLines: 2,
                maxLines: 4,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Guardando…' : 'Guardar'),
        ),
      ],
    );
  }
}
