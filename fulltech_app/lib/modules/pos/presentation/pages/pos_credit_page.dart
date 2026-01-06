import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/module_page.dart';
import '../../models/pos_models.dart';
import '../../state/pos_providers.dart';

class PosCreditPage extends ConsumerStatefulWidget {
  const PosCreditPage({super.key});

  @override
  ConsumerState<PosCreditPage> createState() => _PosCreditPageState();
}

class _PosCreditPageState extends ConsumerState<PosCreditPage> {
  String _search = '';

  Future<List<PosCreditAccountRow>> _load() async {
    final repo = ref.read(posRepositoryProvider);
    return repo.listCredit(search: _search);
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return ModulePage(
      title: 'POS / Crédito',
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Buscar (cliente / factura)',
              isDense: true,
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<PosCreditAccountRow>>(
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
                  return const Center(child: Text('No hay créditos'));
                }

                return ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final r = rows[i];
                    return ListTile(
                      title: Text('${r.invoiceNo} - ${r.customerName}'),
                      subtitle: Text('Balance: ${money(r.balance)}  Estado: ${r.status}'),
                      trailing: OutlinedButton(
                        onPressed: () async {
                          try {
                            final repo = ref.read(posRepositoryProvider);
                            final detail = await repo.getCreditDetail(r.id);
                            if (!context.mounted) return;
                            await showDialog<void>(
                              context: context,
                              builder: (_) => _CreditDetailDialog(
                                sale: detail.sale,
                                credit: detail.credit,
                              ),
                            );
                          } catch (e) {
                            _toast('Error: $e');
                          }
                        },
                        child: const Text('Ver'),
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

class _CreditDetailDialog extends StatelessWidget {
  final PosSale sale;
  final Map<String, dynamic> credit;

  const _CreditDetailDialog({required this.sale, required this.credit});

  @override
  Widget build(BuildContext context) {
    final due = credit['due_date']?.toString();
    final balance = (credit['balance'] as num?)?.toDouble() ?? 0;
    final paid = (credit['paid'] as num?)?.toDouble() ?? 0;

    return AlertDialog(
      title: const Text('Detalle crédito'),
      content: SizedBox(
        width: 620,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Factura: ${sale.invoiceNo}'),
            if (sale.customerName != null) Text('Cliente: ${sale.customerName}'),
            if (sale.customerRnc != null) Text('RNC/ID: ${sale.customerRnc}'),
            const Divider(height: 24),
            Text('Total: ${money(sale.total)}'),
            Text('Pagado: ${money(paid)}'),
            Text('Balance: ${money(balance)}'),
            if (due != null && due.trim().isNotEmpty)
              Text('Vence: ${due.length >= 10 ? due.substring(0, 10) : due}'),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
      ],
    );
  }
}
