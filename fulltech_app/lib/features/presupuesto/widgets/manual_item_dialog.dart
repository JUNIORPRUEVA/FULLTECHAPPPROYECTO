import 'package:flutter/material.dart';

class ManualItemResult {
  final String nombre;
  final double unitPrice;
  final double? unitCost;

  const ManualItemResult({
    required this.nombre,
    required this.unitPrice,
    required this.unitCost,
  });
}

class ManualItemDialog extends StatefulWidget {
  final bool canEditCost;

  const ManualItemDialog({super.key, required this.canEditCost});

  @override
  State<ManualItemDialog> createState() => _ManualItemDialogState();
}

class _ManualItemDialogState extends State<ManualItemDialog> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  late final TextEditingController _costCtrl;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _costCtrl = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar item manual'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Precio unitario'),
            ),
            if (widget.canEditCost) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _costCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Costo unitario'),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            final price = double.tryParse(_priceCtrl.text.trim()) ?? 0;
            final cost = double.tryParse(_costCtrl.text.trim());
            if (name.isEmpty) return;
            Navigator.of(
              context,
            ).pop(
              ManualItemResult(
                nombre: name,
                unitPrice: price,
                unitCost: widget.canEditCost ? cost : null,
              ),
            );
          },
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}
