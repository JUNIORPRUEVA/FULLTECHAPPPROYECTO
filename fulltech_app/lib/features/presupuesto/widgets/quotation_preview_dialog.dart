import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../configuracion/state/company_profile_providers.dart';
import '../models/quotation_models.dart';
import '../screens/quotation_pdf_viewer_screen.dart';
import '../services/quotation_pdf_service.dart';
import '../state/quotation_builder_controller.dart';
import '../state/quotation_builder_state.dart';

class QuotationPreviewDialog extends ConsumerStatefulWidget {
  final QuotationBuilderState draft;

  const QuotationPreviewDialog({super.key, required this.draft});

  @override
  ConsumerState<QuotationPreviewDialog> createState() =>
      _QuotationPreviewDialogState();
}

class _QuotationPreviewDialogState
    extends ConsumerState<QuotationPreviewDialog> {
  Map<String, dynamic>? _saved;
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _ensureSaved({bool force = false}) async {
    if (!force && _saved != null) return;
    try {
      final ctrl = ref.read(quotationBuilderControllerProvider.notifier);
      final created = await ctrl.saveQuotation(notes: _notesCtrl.text);
      if (created == null) return;
      if (!mounted) return;
      setState(() => _saved = created);
    } catch (e) {
      _toast('Error guardando cotización: $e');
    }
  }

  String _shortId({required String id, required String numero}) {
    final n = numero.trim();
    if (n.isNotEmpty) return n;
    final trimmed = id.trim();
    if (trimmed.isEmpty) return 'SIN_ID';
    return trimmed.length <= 8 ? trimmed : trimmed.substring(0, 8);
  }

  Future<Uint8List> _buildPdfBytes({required PdfPageFormat format}) async {
    await _ensureSaved(force: true);
    final meta = _saved ?? <String, dynamic>{};

    final company = await ref.read(companyProfileProvider.future);
    final numero = (meta['numero'] ?? '').toString();
    final id = (meta['id'] ?? '').toString();
    final idShort = _shortId(id: id, numero: numero);
    final createdAtRaw = (meta['created_at'] ?? meta['createdAt'])?.toString();
    final createdAt = DateTime.tryParse(createdAtRaw ?? '') ?? DateTime.now();
    final status = (meta['status'] ?? 'draft').toString();
    final notes = (meta['notes'] ?? _notesCtrl.text).toString();

    return buildQuotationPdfBytesProSafe(
      draft: widget.draft,
      quotationNumber: numero,
      idShort: idShort,
      createdAt: createdAt,
      status: status,
      notes: notes,
      company: company,
      format: format,
    );
  }

  Future<void> _openPdfViewer() async {
    await _ensureSaved(force: true);
    if (!mounted || _saved == null) return;

    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => QuotationPdfViewerScreen(
            draft: widget.draft,
            quotationMeta: _saved!,
          ),
        ),
      );
    } catch (e) {
      _toast('Error abriendo PDF: $e');
    }
  }

  Future<void> _printPdf() async {
    await _ensureSaved(force: true);
    if (!mounted || _saved == null) return;

    try {
      final bytes = await _buildPdfBytes(format: PdfPageFormat.a4);
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      _toast('Error imprimiendo PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quotationBuilderControllerProvider);

    final numero = (_saved?['numero'] ?? '—').toString();
    final customer = widget.draft.customer;

    return AlertDialog(
      title: const Text('Cotización'),
      content: SizedBox(
        width: 720,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'No. $numero',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text('Total: ${widget.draft.total.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 8),
            Text('Cliente: ${customer?.nombre ?? '—'}'),
            if (customer?.telefono != null) Text('Tel: ${customer!.telefono}'),
            if (customer?.email != null) Text('Email: ${customer!.email}'),
            const Divider(height: 24),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: widget.draft.items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final it = widget.draft.items[i];
                  final lineTotal = it.lineNet;

                  return ListTile(
                    dense: true,
                    title: Text(it.nombre),
                    subtitle: Text(
                      '${it.cantidad.toStringAsFixed(0)} × ${it.unitPrice.toStringAsFixed(2)}'
                      '${it.lineDiscount > 0 ? '  •  Desc ' + (it.discountMode == QuotationDiscountMode.amount ? it.discountAmount.toStringAsFixed(2) : it.discountPct.toStringAsFixed(0) + '%') : ''}',
                    ),
                    trailing: Text(lineTotal.toStringAsFixed(2)),
                  );
                },
              ),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal'),
                Text(widget.draft.grossSubtotal.toStringAsFixed(2)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Descuento'),
                Text(widget.draft.discountTotal.toStringAsFixed(2)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal neto'),
                Text(widget.draft.subtotal.toStringAsFixed(2)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ITBIS (${(widget.draft.itbisRate * 100).toStringAsFixed(0)}%)',
                ),
                Text(widget.draft.itbisAmount.toStringAsFixed(2)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: Theme.of(context).textTheme.titleMedium),
                Text(
                  widget.draft.total.toStringAsFixed(2),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'Nota (opcional)'),
              maxLines: 2,
            ),
            if (state.error != null) ...[
              const SizedBox(height: 8),
              Text(
                state.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (state.isSaving) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
        FilledButton.tonal(
          onPressed: state.isSaving ? null : _openPdfViewer,
          child: const Text('Ver PDF'),
        ),
        FilledButton.tonal(
          onPressed: state.isSaving
              ? null
              : () async {
                  await _ensureSaved(force: true);
                  if (_saved != null) _toast('Cotización guardada');
                },
          child: const Text('Guardar'),
        ),
        FilledButton.tonal(
          onPressed: state.isSaving
              ? null
              : () async {
                  await _ensureSaved();
                  if (_saved != null)
                    _toast('Enviado por WhatsApp (pendiente integración)');
                },
          child: const Text('WhatsApp'),
        ),
        FilledButton.tonal(
          onPressed: state.isSaving
              ? null
              : () async {
                  await _ensureSaved();
                  if (_saved != null)
                    _toast('Enviado por Email (pendiente integración)');
                },
          child: const Text('Email'),
        ),
        FilledButton(
          onPressed: state.isSaving
              ? null
              : () async {
                  try {
                    await _printPdf();
                  } catch (e) {
                    _toast(e.toString());
                  }
                },
          child: const Text('Imprimir'),
        ),
      ],
    );
  }
}
