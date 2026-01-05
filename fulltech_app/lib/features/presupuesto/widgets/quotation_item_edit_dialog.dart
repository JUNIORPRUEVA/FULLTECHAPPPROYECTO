import 'package:flutter/material.dart';

import '../models/quotation_models.dart';

class QuotationItemEditResult {
  final QuotationItemDraft item;
  final bool dontAutoShowAgain;

  const QuotationItemEditResult({
    required this.item,
    required this.dontAutoShowAgain,
  });
}

class QuotationItemEditDialog extends StatefulWidget {
  final QuotationItemDraft item;
  final bool canEditCost;
  final bool initialDontAutoShowAgain;

  const QuotationItemEditDialog({
    super.key,
    required this.item,
    required this.canEditCost,
    required this.initialDontAutoShowAgain,
  });

  @override
  State<QuotationItemEditDialog> createState() =>
      _QuotationItemEditDialogState();
}

class _QuotationItemEditDialogState extends State<QuotationItemEditDialog> {
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _discountCtrl;
  late final TextEditingController _costCtrl;
  late bool _dontAutoShow;
  late QuotationDiscountMode _discountMode;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(
      text: widget.item.cantidad.toStringAsFixed(0),
    );
    _priceCtrl = TextEditingController(
      text: widget.item.unitPrice.toStringAsFixed(2),
    );
    _discountMode = widget.item.discountMode;
    _discountCtrl = TextEditingController(
      text: widget.item.discountMode == QuotationDiscountMode.amount
          ? widget.item.discountAmount.toStringAsFixed(2)
          : widget.item.discountPct.toStringAsFixed(0),
    );
    _costCtrl = TextEditingController(
      text: (widget.item.unitCost ?? 0).toStringAsFixed(2),
    );
    _dontAutoShow = widget.initialDontAutoShowAgain;
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _discountCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  double _d(TextEditingController c, double fallback) {
    final v = double.tryParse(c.text.trim());
    return v ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item.nombre),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Cantidad'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Precio unitario',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<QuotationDiscountMode>(
                    value: _discountMode,
                    items: const [
                      DropdownMenuItem(
                        value: QuotationDiscountMode.percent,
                        child: Text('Descuento (%)'),
                      ),
                      DropdownMenuItem(
                        value: QuotationDiscountMode.amount,
                        child: Text('Descuento (monto)'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _discountMode = v;
                        // Keep current numeric value, but format appropriately.
                        final current = _d(_discountCtrl, 0);
                        _discountCtrl.text = v == QuotationDiscountMode.amount
                            ? current.toStringAsFixed(2)
                            : current.toStringAsFixed(0);
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Tipo descuento',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _costCtrl,
                    enabled: widget.canEditCost,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Costo unitario',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _discountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _discountMode == QuotationDiscountMode.amount
                    ? 'Monto descuento'
                    : 'Porcentaje descuento',
                suffixText: _discountMode == QuotationDiscountMode.amount
                    ? null
                    : '%',
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _dontAutoShow,
              onChanged: (v) => setState(() => _dontAutoShow = v),
              title: const Text('No volver a mostrar automáticamente'),
            ),
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
            final qty = _d(_qtyCtrl, widget.item.cantidad);
            final price = _d(_priceCtrl, widget.item.unitPrice);
            final discountRaw = _d(_discountCtrl, 0);
            final cost = _d(_costCtrl, widget.item.unitCost ?? 0);

            final gross = (qty <= 0 ? 1 : qty) * (price < 0 ? 0 : price);
            final pct = _discountMode == QuotationDiscountMode.percent
                ? discountRaw.clamp(0, 100).toDouble()
                : 0.0;
            final amt = _discountMode == QuotationDiscountMode.amount
                ? discountRaw.clamp(0, gross).toDouble()
                : 0.0;

            final next = widget.item.copyWith(
              cantidad: qty <= 0 ? 1 : qty,
              unitPrice: price < 0 ? 0 : price,
              discountMode: _discountMode,
              discountPct: pct,
              discountAmount: amt,
              unitCost: widget.canEditCost ? cost : widget.item.unitCost,
            );

            Navigator.of(context).pop(
              QuotationItemEditResult(
                item: next,
                dontAutoShowAgain: _dontAutoShow,
              ),
            );
          },
          child: const Text('Aplicar'),
        ),
      ],
    );
  }
}
