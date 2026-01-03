import 'package:flutter/material.dart';

class PresupuestoDetailScreen extends StatefulWidget {
  final String? presupuestoId;

  const PresupuestoDetailScreen({
    super.key,
    this.presupuestoId,
  });

  @override
  State<PresupuestoDetailScreen> createState() => _PresupuestoDetailScreenState();
}

class _PresupuestoDetailScreenState extends State<PresupuestoDetailScreen> {
  final _formKey = GlobalKey<FormState>();

  final _numeroCtrl = TextEditingController();
  final _clienteCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  String _estado = 'pendiente';

  @override
  void dispose() {
    _numeroCtrl.dispose();
    _clienteCtrl.dispose();
    _montoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.presupuestoId != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Editar presupuesto' : 'Nuevo presupuesto')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _numeroCtrl,
                decoration: const InputDecoration(labelText: 'Número'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _clienteCtrl,
                decoration: const InputDecoration(labelText: 'Cliente'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _montoCtrl,
                decoration: const InputDecoration(labelText: 'Monto'),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _estado,
                decoration: const InputDecoration(labelText: 'Estado'),
                items: const [
                  DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                  DropdownMenuItem(value: 'enviado', child: Text('Enviado')),
                  DropdownMenuItem(value: 'aprobado', child: Text('Aprobado')),
                  DropdownMenuItem(value: 'rechazado', child: Text('Rechazado')),
                ],
                onChanged: (v) => setState(() => _estado = v ?? 'pendiente'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  // TODO: Guardar localmente y encolar en sync_queue.
                  Navigator.of(context).pop();
                },
                child: const Text('Guardar'),
              ),
              const SizedBox(height: 8),
              const Text('TODO: Conectar con backend (presupuestos) cuando exista el módulo.'),
            ],
          ),
        ),
      ),
    );
  }
}
