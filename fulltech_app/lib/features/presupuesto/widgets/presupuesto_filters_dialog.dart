import 'package:flutter/material.dart';

class PresupuestoFiltersResult {
  final double? minPrice;
  final double? maxPrice;
  final String order;
  final String? productType;

  const PresupuestoFiltersResult({
    required this.minPrice,
    required this.maxPrice,
    required this.order,
    required this.productType,
  });
}

class PresupuestoFiltersDialog extends StatefulWidget {
  final double? initialMinPrice;
  final double? initialMaxPrice;
  final String initialOrder;
  final String? initialProductType;

  const PresupuestoFiltersDialog({
    super.key,
    required this.initialMinPrice,
    required this.initialMaxPrice,
    required this.initialOrder,
    required this.initialProductType,
  });

  @override
  State<PresupuestoFiltersDialog> createState() =>
      _PresupuestoFiltersDialogState();
}

class _PresupuestoFiltersDialogState extends State<PresupuestoFiltersDialog> {
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;
  late String _order;
  String? _productType;

  @override
  void initState() {
    super.initState();
    _minCtrl = TextEditingController(
      text: widget.initialMinPrice?.toStringAsFixed(0) ?? '',
    );
    _maxCtrl = TextEditingController(
      text: widget.initialMaxPrice?.toStringAsFixed(0) ?? '',
    );
    _order = widget.initialOrder;
    _productType = widget.initialProductType;
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  double? _parse(TextEditingController ctrl) {
    final t = ctrl.text.trim();
    if (t.isEmpty) return null;
    final v = double.tryParse(t);
    return v;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filtros'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Precio mínimo',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Precio máximo',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _order,
              decoration: const InputDecoration(labelText: 'Ordenar'),
              items: const [
                DropdownMenuItem(value: 'most_used', child: Text('Más usados')),
                DropdownMenuItem(value: 'recent', child: Text('Recientes')),
                DropdownMenuItem(
                  value: 'price_asc',
                  child: Text('Precio: menor a mayor'),
                ),
                DropdownMenuItem(
                  value: 'price_desc',
                  child: Text('Precio: mayor a menor'),
                ),
              ],
              onChanged: (v) => setState(() => _order = v ?? 'most_used'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              value: _productType,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: const [
                DropdownMenuItem(value: null, child: Text('Todos')),
                DropdownMenuItem(value: 'simple', child: Text('Simple')),
                DropdownMenuItem(value: 'servicio', child: Text('Servicio')),
              ],
              onChanged: (v) => setState(() => _productType = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(
              const PresupuestoFiltersResult(
                minPrice: null,
                maxPrice: null,
                order: 'most_used',
                productType: null,
              ),
            );
          },
          child: const Text('Limpiar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(
              PresupuestoFiltersResult(
                minPrice: _parse(_minCtrl),
                maxPrice: _parse(_maxCtrl),
                order: _order,
                productType: _productType,
              ),
            );
          },
          child: const Text('Aplicar'),
        ),
      ],
    );
  }
}
