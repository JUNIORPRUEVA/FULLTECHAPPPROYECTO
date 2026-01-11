import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/module_page.dart';
import '../../models/pos_models.dart';
import '../../state/pos_providers.dart';
import 'pos_invoice_viewer_screen.dart';

class PosSalesHistoryPage extends ConsumerStatefulWidget {
  const PosSalesHistoryPage({super.key});

  @override
  ConsumerState<PosSalesHistoryPage> createState() => _PosSalesHistoryPageState();
}

class _PosSalesHistoryPageState extends ConsumerState<PosSalesHistoryPage> {
  bool _loading = false;
  String? _error;
  String _status = '';

  String money(num v) => NumberFormat('#,##0.00', 'en_US').format(v);

  Future<List<PosSale>> _load() async {
    final repo = ref.read(posRepositoryProvider);
    return repo.listSales(status: _status.isEmpty ? null : _status);
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _openSale(PosSale sale) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(posRepositoryProvider);
      final full = await repo.getSale(sale.id);
      if (!mounted) return;
      setState(() => _loading = false);
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PosInvoiceViewerScreen(sale: full)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _cancelSale(PosSale sale) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar venta'),
        content: Text('Cancelar ${sale.invoiceNo} por ${money(sale.total)}?\n\nRevierte stock y (si aplica) caja.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sí, cancelar')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(posRepositoryProvider);
      await repo.cancelSale(saleId: sale.id);
      if (!mounted) return;
      setState(() => _loading = false);
      _toast('Venta cancelada');
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
      _toast('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModulePage(
      title: 'POS / Ventas',
      actions: [
        IconButton(
          tooltip: 'Refrescar',
          onPressed: () => setState(() {}),
          icon: const Icon(Icons.refresh),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_loading) const LinearProgressIndicator(minHeight: 3),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _status.isEmpty ? null : _status,
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Todas')),
                    DropdownMenuItem(value: 'PAID', child: Text('Pagadas')),
                    DropdownMenuItem(value: 'CREDIT', child: Text('Crédito')),
                    DropdownMenuItem(value: 'CANCELLED', child: Text('Canceladas')),
                    DropdownMenuItem(value: 'DRAFT', child: Text('Borrador')),
                  ],
                  onChanged: (v) => setState(() => _status = v ?? ''),
                  decoration: const InputDecoration(labelText: 'Estado', isDense: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<PosSale>>(
              future: _load(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                final rows = snap.data ?? const [];
                if (rows.isEmpty) {
                  return const Center(child: Text('Sin ventas'));
                }

                return ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final s = rows[i];
                    final status = s.status.toUpperCase();
                    final canCancel = status == 'PAID' || status == 'CREDIT' || status == 'DRAFT';
                    return ListTile(
                      title: Text('${s.invoiceNo}  (${s.invoiceType})'),
                      subtitle: Text(
                        '${s.customerName ?? ''}  •  ${s.createdAt.toIso8601String().substring(0, 19).replaceAll('T', ' ')}  •  ${status}',
                      ),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: _loading ? null : () => _openSale(s),
                            child: const Text('Ver/Imprimir'),
                          ),
                          if (canCancel)
                            OutlinedButton(
                              onPressed: _loading ? null : () => _cancelSale(s),
                              child: const Text('Cancelar'),
                            ),
                        ],
                      ),
                      onTap: _loading ? null : () => _openSale(s),
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

