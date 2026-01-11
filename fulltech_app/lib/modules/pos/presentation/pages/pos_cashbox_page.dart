import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/module_page.dart';
import '../../state/pos_providers.dart';

class PosCashboxPage extends ConsumerStatefulWidget {
  const PosCashboxPage({super.key});

  @override
  ConsumerState<PosCashboxPage> createState() => _PosCashboxPageState();
}

class _PosCashboxPageState extends ConsumerState<PosCashboxPage> {
  bool _loading = false;
  Map<String, dynamic>? _data;
  String? _error;

  String money(num v) => NumberFormat('#,##0.00', 'en_US').format(v);

  double _asDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(posRepositoryProvider);
      final data = await repo.getCurrentCashbox();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _openCashbox() async {
    final res = await showDialog<_OpenCashboxResult>(
      context: context,
      builder: (_) => const _OpenCashboxDialog(),
    );
    if (res == null) return;

    setState(() => _loading = true);
    try {
      final repo = ref.read(posRepositoryProvider);
      await repo.openCashbox(openingAmount: res.openingAmount, note: res.note);
      await _refresh();
      _toast('Caja abierta');
    } catch (e) {
      _toast('Error abriendo caja: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _movement(String type) async {
    final res = await showDialog<_MovementResult>(
      context: context,
      builder: (_) => _MovementDialog(type: type),
    );
    if (res == null) return;

    setState(() => _loading = true);
    try {
      final repo = ref.read(posRepositoryProvider);
      await repo.cashboxMovement(type: type, amount: res.amount, reason: res.reason);
      await _refresh();
      _toast(type == 'IN' ? 'Entrada registrada' : 'Salida registrada');
    } catch (e) {
      _toast('Error guardando movimiento: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _closeCashbox() async {
    final res = await showDialog<_CloseCashboxResult>(
      context: context,
      builder: (_) => const _CloseCashboxDialog(),
    );
    if (res == null) return;

    setState(() => _loading = true);
    try {
      final repo = ref.read(posRepositoryProvider);
      await repo.closeCashbox(countedCash: res.countedCash, note: res.note);
      await _refresh();
      _toast('Caja cerrada');
    } catch (e) {
      _toast('Error cerrando caja: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _showHistory() async {
    try {
      final repo = ref.read(posRepositoryProvider);
      final items = await repo.listCashboxClosures();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => _CashboxHistoryDialog(items: items),
      );
    } catch (e) {
      _toast('Error cargando cierres: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cashbox = (_data?['cashbox'] as Map?)?.cast<String, dynamic>();
    final isOpen = (cashbox?['status'] ?? '').toString().toUpperCase() == 'OPEN';
    final totals = (_data?['totals'] as Map?)?.cast<String, dynamic>() ?? const {};
    final movements = (_data?['movements'] as List?)?.cast<Map>() ?? const [];

    return ModulePage(
      title: 'POS / Caja',
      actions: [
        IconButton(
          tooltip: 'Historial',
          onPressed: _showHistory,
          icon: const Icon(Icons.history),
        ),
        IconButton(
          tooltip: 'Refrescar',
          onPressed: _refresh,
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOpen ? 'Caja ABIERTA' : 'Caja CERRADA',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text('Apertura: ${money(_asDouble(cashbox?['opening_amount']))}'),
                        Text('Esperado: ${money(_asDouble(totals['expected_cash']))}'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (!isOpen)
                    FilledButton.icon(
                      onPressed: _loading ? null : _openCashbox,
                      icon: const Icon(Icons.lock_open_outlined),
                      label: const Text('Abrir caja'),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: _loading ? null : () => _movement('IN'),
                          child: const Text('Entrada'),
                        ),
                        OutlinedButton(
                          onPressed: _loading ? null : () => _movement('OUT'),
                          child: const Text('Salida'),
                        ),
                        FilledButton(
                          onPressed: _loading ? null : _closeCashbox,
                          child: const Text('Cerrar caja'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Movimientos',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: movements.isEmpty
                        ? const Center(child: Text('Sin movimientos'))
                        : ListView.separated(
                            itemCount: movements.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final m = movements[i].cast<String, dynamic>();
                              final type = (m['type'] ?? '').toString();
                              final amount = _asDouble(m['amount']);
                              final reason = (m['reason'] ?? '').toString();
                              final at = (m['created_at'] ?? '').toString();
                              return ListTile(
                                leading: Icon(
                                  type == 'IN' ? Icons.call_received : Icons.call_made,
                                  color: type == 'IN' ? Colors.green : Colors.red,
                                ),
                                title: Text('${type == 'IN' ? 'Entrada' : 'Salida'}: ${money(amount)}'),
                                subtitle: Text(reason.isEmpty ? at : '$reason\n$at'),
                                isThreeLine: reason.isNotEmpty,
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpenCashboxResult {
  final double openingAmount;
  final String? note;
  const _OpenCashboxResult({required this.openingAmount, required this.note});
}

class _OpenCashboxDialog extends StatefulWidget {
  const _OpenCashboxDialog();

  @override
  State<_OpenCashboxDialog> createState() => _OpenCashboxDialogState();
}

class _OpenCashboxDialogState extends State<_OpenCashboxDialog> {
  final _amount = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  double _parse(String s) => double.tryParse(s.replaceAll(',', '.')) ?? 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Abrir caja'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _amount,
              decoration: const InputDecoration(labelText: 'Monto inicial', isDense: true),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _note,
              decoration: const InputDecoration(labelText: 'Nota (opcional)', isDense: true),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(
              context,
              _OpenCashboxResult(
                openingAmount: _parse(_amount.text),
                note: _note.text.trim().isEmpty ? null : _note.text.trim(),
              ),
            );
          },
          child: const Text('Abrir'),
        ),
      ],
    );
  }
}

class _MovementResult {
  final double amount;
  final String? reason;
  const _MovementResult({required this.amount, required this.reason});
}

class _MovementDialog extends StatefulWidget {
  final String type;
  const _MovementDialog({required this.type});

  @override
  State<_MovementDialog> createState() => _MovementDialogState();
}

class _MovementDialogState extends State<_MovementDialog> {
  final _amount = TextEditingController();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  double _parse(String s) => double.tryParse(s.replaceAll(',', '.')) ?? 0;

  @override
  Widget build(BuildContext context) {
    final title = widget.type == 'IN' ? 'Entrada' : 'Salida';
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _amount,
              decoration: const InputDecoration(labelText: 'Monto', isDense: true),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _reason,
              decoration: const InputDecoration(labelText: 'Motivo/nota', isDense: true),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            final amt = _parse(_amount.text);
            if (amt <= 0) return;
            Navigator.pop(
              context,
              _MovementResult(
                amount: amt,
                reason: _reason.text.trim().isEmpty ? null : _reason.text.trim(),
              ),
            );
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _CloseCashboxResult {
  final double countedCash;
  final String? note;
  const _CloseCashboxResult({required this.countedCash, required this.note});
}

class _CloseCashboxDialog extends StatefulWidget {
  const _CloseCashboxDialog();

  @override
  State<_CloseCashboxDialog> createState() => _CloseCashboxDialogState();
}

class _CloseCashboxDialogState extends State<_CloseCashboxDialog> {
  final _counted = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    _counted.dispose();
    _note.dispose();
    super.dispose();
  }

  double _parse(String s) => double.tryParse(s.replaceAll(',', '.')) ?? 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cerrar caja'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _counted,
              decoration: const InputDecoration(labelText: 'Efectivo contado', isDense: true),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _note,
              decoration: const InputDecoration(labelText: 'Nota (opcional)', isDense: true),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(
              context,
              _CloseCashboxResult(
                countedCash: _parse(_counted.text),
                note: _note.text.trim().isEmpty ? null : _note.text.trim(),
              ),
            );
          },
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}

class _CashboxHistoryDialog extends StatelessWidget {
  const _CashboxHistoryDialog({required this.items});

  final List<Map<String, dynamic>> items;

  double _asDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  String money(num v) => NumberFormat('#,##0.00', 'en_US').format(v);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Historial de cierres'),
      content: SizedBox(
        width: 820,
        child: items.isEmpty
            ? const Text('Sin cierres')
            : ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final c = items[i];
                  final createdAt = (c['created_at'] ?? '').toString();
                  final summary = (c['summary_json'] as Map?)?.cast<String, dynamic>();
                  final closed = (summary?['closed'] as Map?)?.cast<String, dynamic>();
                  final expected = _asDouble(closed?['expected_cash']);
                  final counted = _asDouble(closed?['counted_cash']);
                  final diff = _asDouble(closed?['difference']);
                  return ListTile(
                    title: Text(createdAt),
                    subtitle: Text(
                      'Esperado: ${money(expected)}  Contado: ${money(counted)}  Diferencia: ${money(diff)}',
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
      ],
    );
  }
}

