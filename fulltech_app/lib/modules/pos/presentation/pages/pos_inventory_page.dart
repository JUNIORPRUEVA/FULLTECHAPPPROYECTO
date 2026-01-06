import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/module_page.dart';
import '../../models/pos_models.dart';
import '../../state/pos_providers.dart';

class PosInventoryPage extends ConsumerStatefulWidget {
  const PosInventoryPage({super.key});

  @override
  ConsumerState<PosInventoryPage> createState() => _PosInventoryPageState();
}

class _PosInventoryPageState extends ConsumerState<PosInventoryPage> {
  bool _lowStockOnly = true;
  String _search = '';

  Future<List<PosProduct>> _load() async {
    final repo = ref.read(posRepositoryProvider);
    return repo.listProducts(search: _search, lowStock: _lowStockOnly);
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return ModulePage(
      title: 'POS / Inventario',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'Buscar producto',
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: _lowStockOnly,
                    onChanged: (v) => setState(() => _lowStockOnly = v ?? true),
                  ),
                  const Text('Bajo stock'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<PosProduct>>(
              future: _load(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }

                final items = snap.data ?? const [];
                if (items.isEmpty) {
                  return const Center(child: Text('Sin resultados'));
                }

                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final p = items[i];
                    final lowStock = p.stockQty <= p.minStock;

                    return ListTile(
                      title: Text(p.nombre),
                      subtitle: Text(
                        'Stock: ${p.stockQty.toStringAsFixed(2)}  Min: ${p.minStock.toStringAsFixed(2)}  Max: ${p.maxStock.toStringAsFixed(2)}',
                      ),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          if (lowStock)
                            Text(
                              'Sugerido: ${p.suggestedReorderQty.toStringAsFixed(2)}',
                              style: TextStyle(color: Theme.of(context).colorScheme.error),
                            ),
                          OutlinedButton(
                            onPressed: () async {
                              final res = await showDialog<_AdjustResult>(
                                context: context,
                                builder: (_) => _AdjustDialog(product: p),
                              );
                              if (res == null) return;

                              try {
                                final repo = ref.read(posRepositoryProvider);
                                await repo.adjustStock(
                                  productId: p.id,
                                  qtyChange: res.qtyChange,
                                  note: res.note,
                                );
                                if (!mounted) return;
                                setState(() {});
                              } catch (e) {
                                _toast('Error ajustando: $e');
                              }
                            },
                            child: const Text('Ajustar'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AdjustResult {
  final double qtyChange;
  final String? note;

  const _AdjustResult({required this.qtyChange, required this.note});
}

class _AdjustDialog extends StatefulWidget {
  final PosProduct product;

  const _AdjustDialog({required this.product});

  @override
  State<_AdjustDialog> createState() => _AdjustDialogState();
}

class _AdjustDialogState extends State<_AdjustDialog> {
  final _qty = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    _qty.dispose();
    _note.dispose();
    super.dispose();
  }

  double _parse(String s) => double.tryParse(s.replaceAll(',', '.')) ?? 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Ajustar: ${widget.product.nombre}'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _qty,
              decoration: const InputDecoration(
                labelText: 'Cambio de cantidad (puede ser negativo)',
                isDense: true,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _note,
              decoration: const InputDecoration(labelText: 'Nota', isDense: true),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            final qty = _parse(_qty.text);
            if (qty == 0) return;
            Navigator.pop(
              context,
              _AdjustResult(qtyChange: qty, note: _note.text.trim().isEmpty ? null : _note.text.trim()),
            );
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
