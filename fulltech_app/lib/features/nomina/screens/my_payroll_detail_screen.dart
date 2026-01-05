import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/module_page.dart';
import '../../../core/widgets/pdf_viewer_page.dart';
import '../state/payroll_providers.dart';

class MyPayrollDetailScreen extends ConsumerStatefulWidget {
  final String runId;

  const MyPayrollDetailScreen({super.key, required this.runId});

  @override
  ConsumerState<MyPayrollDetailScreen> createState() =>
      _MyPayrollDetailScreenState();
}

class _MyPayrollDetailScreenState extends ConsumerState<MyPayrollDetailScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _snapshot;
  String? _pdfUrl;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final detail = await ref
          .read(myPayrollControllerProvider.notifier)
          .getDetail(widget.runId);
      if (!mounted) return;
      final snap = detail?.payslip.snapshot;
      setState(() {
        _snapshot = snap;
        _pdfUrl = detail?.payslip.pdfUrl;
        _loading = false;
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
  Widget build(BuildContext context) {
    final snap = _snapshot;
    final company = snap?['company'];
    final period = snap?['period'];
    final summary = snap?['summary'];
    final lineItems = (snap?['line_items'] as List?) ?? const [];

    String title = 'Detalle nómina';
    if (period is Map) {
      title =
          'Nómina ${period['year']}-${period['month'].toString().padLeft(2, '0')}';
    }

    return ModulePage(
      title: title,
      actions: [
        IconButton(
          tooltip: 'Refrescar',
          onPressed: _load,
          icon: const Icon(Icons.refresh),
        ),
        if (_pdfUrl != null && _pdfUrl!.trim().isNotEmpty)
          const SizedBox(width: 8),
        if (_pdfUrl != null && _pdfUrl!.trim().isNotEmpty)
          FilledButton.icon(
            onPressed: () {
              final url = _pdfUrl!.trim();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PdfViewerPage(
                    title: 'Recibo de nómina',
                    loadFilePath: () => ref
                        .read(payrollRepositoryProvider)
                        .downloadPayslipPdfToTempFile(
                          url: url,
                          fileName: 'payslip_${widget.runId}.pdf',
                        ),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Ver PDF'),
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
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  if (company is Map)
                    Text(
                      company['nombre_empresa']?.toString() ?? 'Empresa',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  const SizedBox(height: 8),
                  if (summary is Map) ...[
                    _kv('Sueldo base', summary['base_salary_amount']),
                    _kv('Comisiones', summary['commissions_amount']),
                    _kv('Otros ingresos', summary['other_earnings_amount']),
                    _kv('Bruto', summary['gross_amount']),
                    _kv(
                      'Deducciones legales',
                      summary['statutory_deductions_amount'],
                    ),
                    _kv(
                      'Otras deducciones',
                      summary['other_deductions_amount'],
                    ),
                    const Divider(),
                    _kv('Neto', summary['net_amount'], strong: true),
                    const SizedBox(height: 12),
                  ],
                  const Text(
                    'Detalle',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  if (lineItems.isEmpty)
                    const Text('Sin detalle')
                  else
                    for (final li in lineItems)
                      if (li is Map)
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                li['concept_name']?.toString() ?? '-',
                              ),
                            ),
                            Text((li['amount'] ?? 0).toString()),
                          ],
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, Object? v, {bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              k,
              style: TextStyle(
                fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            v?.toString() ?? '0',
            style: TextStyle(
              fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
