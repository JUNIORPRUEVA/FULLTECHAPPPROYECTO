import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/module_page.dart';
import '../data/models/payroll_models.dart';
import '../data/repositories/payroll_repository.dart';
import '../state/payroll_providers.dart';

class PayrollRunDetailScreen extends ConsumerStatefulWidget {
  final String runId;

  const PayrollRunDetailScreen({super.key, required this.runId});

  @override
  ConsumerState<PayrollRunDetailScreen> createState() =>
      _PayrollRunDetailScreenState();
}

class _PayrollRunDetailScreenState
    extends ConsumerState<PayrollRunDetailScreen> {
  PayrollRunDetailResponse? _detail;
  bool _loading = true;
  String? _error;

  String _halfLabel(PayrollHalf half) =>
      half == PayrollHalf.first ? '1–15' : '16–Fin';

  bool get _canImport =>
      _detail?.run.status == PayrollRunStatus.draft ||
      _detail?.run.status == PayrollRunStatus.review;
  bool get _canRecalc =>
      _detail?.run.status == PayrollRunStatus.draft ||
      _detail?.run.status == PayrollRunStatus.review;
  bool get _canApprove =>
      _detail?.run.status == PayrollRunStatus.draft ||
      _detail?.run.status == PayrollRunStatus.review;
  bool get _canMarkPaid => _detail?.run.status == PayrollRunStatus.approved;

  Future<void> _load({required bool showLoading}) async {
    if (showLoading) setState(() => _loading = true);

    final repo = ref.read(payrollRepositoryProvider);

    try {
      final cached = await repo.readCachedRunDetail(widget.runId);
      if (cached != null && mounted) {
        setState(() {
          _detail = cached;
          _loading = false;
        });
      }
    } catch (_) {
      // ignore
    }

    try {
      final fresh = await repo.fetchRunDetail(widget.runId);
      if (!mounted) return;
      setState(() {
        _detail = fresh;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _load(showLoading: true);
  }

  Future<void> _runAction(
    Future<void> Function(PayrollRepository repo) fn,
  ) async {
    final repo = ref.read(payrollRepositoryProvider);
    setState(() => _loading = true);
    try {
      await fn(repo);
      await _load(showLoading: false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _detail;

    final title = d == null
        ? 'Corrida'
        : 'Corrida ${d.run.period.year}-${d.run.period.month.toString().padLeft(2, '0')} (${_halfLabel(d.run.period.half)})';

    return ModulePage(
      title: title,
      actions: [
        IconButton(
          tooltip: 'Refrescar',
          onPressed: () => _load(showLoading: false),
          icon: const Icon(Icons.refresh),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: _canImport
              ? () => _runAction((r) => r.importMovements(widget.runId))
              : null,
          child: const Text('Importar'),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: _canRecalc
              ? () => _runAction((r) => r.recalculate(widget.runId))
              : null,
          child: const Text('Recalcular'),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: _canApprove
              ? () => _runAction((r) => r.approve(widget.runId))
              : null,
          child: const Text('Aprobar'),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: _canMarkPaid
              ? () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Marcar como pagada'),
                      content: const Text(
                        'Esto genera PDFs y notifica a empleados.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Confirmar'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await _runAction((r) => r.markPaid(widget.runId));
                  }
                }
              : null,
          child: const Text('Marcar pagada'),
        ),
      ],
      child: Card(
        child: Column(
          children: [
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            if (d == null && !_loading)
              const Expanded(
                child: Center(child: Text('No se pudo cargar la corrida')),
              )
            else if (d != null)
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _Chip(
                          label: 'Estado',
                          value: d.run.status.name.toUpperCase(),
                        ),
                        _Chip(
                          label: 'Empleados',
                          value: d.run.employeeSummaries.length.toString(),
                        ),
                        _Chip(
                          label: 'Neto total',
                          value: (d.totals['net'] ?? 0).toString(),
                        ),
                        _Chip(
                          label: 'Bruto total',
                          value: (d.totals['gross'] ?? 0).toString(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Empleados',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    for (final s in d.run.employeeSummaries)
                      Card(
                        child: ExpansionTile(
                          title: Text(s.employee.nombreCompleto),
                          subtitle: Text(
                            'Neto: ${s.netAmount.toStringAsFixed(2)} • ${s.status.name}',
                          ),
                          children: [
                            if (s.lineItems.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(12),
                                child: Text('Sin detalles'),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    for (final li in s.lineItems)
                                      Row(
                                        children: [
                                          Expanded(child: Text(li.conceptName)),
                                          Text(li.amount.toStringAsFixed(2)),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;

  const _Chip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label: $value'));
  }
}
