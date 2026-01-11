import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

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

  String _digitsOnly(String raw) => raw.replaceAll(RegExp(r'[^0-9]'), '');

  String? _normalizeWhatsAppPhone(String? raw) {
    if (raw == null) return null;
    final digits = _digitsOnly(raw.trim());
    if (digits.isEmpty) return null;
    if (digits.length == 10) return '1$digits';
    if (digits.length >= 11) return digits;
    return null;
  }

  Future<bool> _openWhatsAppChat(String phoneDigits, String message) async {
    final uri = Uri.parse(
      'https://wa.me/$phoneDigits?text=${Uri.encodeComponent(message)}',
    );
    if (!await canLaunchUrl(uri)) return false;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    return true;
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

  Future<void> _whatsAppMenu() async {
    await _ensureSaved(force: true);
    final meta = _saved;
    if (!mounted || meta == null) return;

    final numero = (meta['numero'] ?? '').toString().trim();
    final id = (meta['id'] ?? '').toString().trim();
    final idShort = _shortId(id: id, numero: numero);
    final quoteNo = numero.isEmpty ? idShort : numero;

    final customer = widget.draft.customer;
    final phoneDigits = _normalizeWhatsAppPhone(customer?.telefono);
    final customerName = (customer?.nombre ?? '').trim();

    final msg =
        'Hola${customerName.isEmpty ? '' : ' $customerName'}, le comparto su cotización No. $quoteNo. '
        'Total: RD\$ ${widget.draft.total.toStringAsFixed(2)}.';

    final bytes = await _buildPdfBytes(format: PdfPageFormat.a4);
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Enviar por WhatsApp',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: phoneDigits == null
                      ? null
                      : () async {
                          Navigator.of(ctx).pop();
                          final ok = await _openWhatsAppChat(phoneDigits, msg);
                          if (!ok) _toast('No se pudo abrir WhatsApp');
                        },
                  icon: const Icon(Icons.chat_outlined),
                  label: const Text('Abrir chat (mensaje)'),
                ),
                const SizedBox(height: 10),
                FilledButton.tonalIcon(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    try {
                      final createdAtRaw =
                          (meta['created_at'] ?? meta['createdAt'])?.toString();
                      final createdAt =
                          DateTime.tryParse(createdAtRaw ?? '') ??
                          DateTime.now();
                      String two(int n) => n.toString().padLeft(2, '0');
                      final fname =
                          'Cotizacion_FULLTECH_${idShort}_${createdAt.year}${two(createdAt.month)}${two(createdAt.day)}.pdf';
                      await Printing.sharePdf(bytes: bytes, filename: fname);
                    } catch (e) {
                      _toast('No se pudo compartir: $e');
                    }
                  },
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Compartir PDF (selecciona WhatsApp)'),
                ),
                if (phoneDigits == null) ...[
                  const SizedBox(height: 10),
                  const Text('Nota: el cliente no tiene teléfono válido.'),
                ],
              ],
            ),
          ),
        );
      },
    );
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
                      '${it.lineDiscount > 0 ? '  •  Desc ${it.discountMode == QuotationDiscountMode.amount ? it.discountAmount.toStringAsFixed(2) : it.discountPct.toStringAsFixed(0) + '%'}' : ''}',
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
                  if (_saved != null) {
                    await _whatsAppMenu();
                  }
                },
          child: const Text('WhatsApp'),
        ),
        FilledButton.tonal(
          onPressed: state.isSaving
              ? null
              : () async {
                  await _ensureSaved();
                  if (_saved != null) {
                    _toast('Enviado por Email (pendiente integración)');
                  }
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
