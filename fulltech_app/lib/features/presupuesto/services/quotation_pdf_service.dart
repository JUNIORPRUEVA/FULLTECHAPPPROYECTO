import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../configuracion/models/company_profile.dart';
import '../models/quotation_models.dart';
import '../state/quotation_builder_state.dart';

PdfColor _rgb(int r, int g, int b) => PdfColor(r / 255, g / 255, b / 255);

final PdfColor _pageBorder = _rgb(203, 213, 225); // slate-300-ish
final PdfColor _cardBorder = _rgb(226, 232, 240); // slate-200-ish
final PdfColor _cardBg = _rgb(248, 250, 252); // #F8FAFC
final PdfColor _textMuted = _rgb(71, 85, 105); // slate-600-ish
final PdfColor _textStrong = _rgb(15, 23, 42); // slate-900-ish

PdfColor _accentColor(CompanyProfile company) {
  // CompanyProfile currently has no theme color field; keep conservative corporate red.
  return _rgb(185, 28, 28); // red-700-ish
}

String _fmtDate(DateTime dt) {
  try {
    return DateFormat('dd/MM/yyyy', 'es_DO').format(dt);
  } catch (_) {
    return DateFormat('dd/MM/yyyy').format(dt);
  }
}

String _fmtMoneyRd(num v) {
  try {
    final f = NumberFormat.currency(
      locale: 'es_DO',
      symbol: 'RD\$ ',
      decimalDigits: 2,
    );
    return f.format(v);
  } catch (_) {
    return 'RD\$ ${v.toStringAsFixed(2)}';
  }
}

Future<pw.ImageProvider?> _maybeLoadLogo(String? logoUrl) async {
  if (logoUrl == null || logoUrl.trim().isEmpty) return null;
  try {
    return await networkImage(logoUrl.trim());
  } catch (_) {
    return null;
  }
}

pw.Widget _kv(String k, String v) {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.SizedBox(
        width: 90,
        child: pw.Text(
          k,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: _textMuted,
          ),
        ),
      ),
      pw.Expanded(child: pw.Text(v, style: const pw.TextStyle(fontSize: 9))),
    ],
  );
}

String _statusLabel(String raw) {
  final s = raw.trim().toLowerCase();
  if (s == 'approved' || s == 'aprobada' || s == 'aprobado') return 'APROBADA';
  if (s == 'sent' || s == 'enviada' || s == 'enviado') return 'ENVIADA';
  return 'DRAFT';
}

pw.Widget _card({required pw.Widget child, pw.EdgeInsets? padding}) {
  return pw.Container(
    padding: padding ?? const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      color: _cardBg,
      border: pw.Border.all(color: _cardBorder, width: 1),
      borderRadius: pw.BorderRadius.circular(10),
    ),
    child: child,
  );
}

pw.Widget _totalsFooterBlock({
  required QuotationBuilderState draft,
  required PdfColor accent,
}) {
  pw.Widget row(String label, String value, {bool strong = false}) {
    final style = pw.TextStyle(
      fontSize: strong ? 11 : 10,
      fontWeight: strong ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: strong ? _textStrong : _textMuted,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(value, style: style),
        ],
      ),
    );
  }

  final itbisLabel =
      'ITBIS (${(draft.itbisRate * 100).toStringAsFixed(0)}%)';

  return pw.Container(
    width: 250,
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      color: _cardBg,
      border: pw.Border.all(color: _cardBorder, width: 1),
      borderRadius: pw.BorderRadius.circular(10),
    ),
    child: pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        row('Subtotal', _fmtMoneyRd(draft.grossSubtotal)),
        if (draft.discountTotal > 0)
          row('Descuento', '- ${_fmtMoneyRd(draft.discountTotal)}'),
        if (draft.itbisEnabled && draft.itbisAmount > 0)
          row(itbisLabel, _fmtMoneyRd(draft.itbisAmount)),
        pw.SizedBox(height: 6),
        pw.Container(height: 1, color: _cardBorder),
        pw.Container(
          margin: const pw.EdgeInsets.only(top: 8),
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: accent, width: 1.5)),
          ),
          child: row(
            'TOTAL',
            _fmtMoneyRd(draft.total),
            strong: true,
          ),
        ),
      ],
    ),
  );
}

Future<Uint8List> buildQuotationPdfBytesPro({
  required QuotationBuilderState draft,
  required String quotationNumber,
  required String idShort,
  required DateTime createdAt,
  required String status,
  required String notes,
  required CompanyProfile company,
  required PdfPageFormat format,
}) async {
  final logo = await _maybeLoadLogo(company.logoUrl);

  final accent = _accentColor(company);

  final baseFont = await PdfGoogleFonts.interRegular();
  final boldFont = await PdfGoogleFonts.interSemiBold();
  final theme = pw.ThemeData.withFont(
    base: baseFont,
    bold: boldFont,
  );

  final pageTheme = pw.PageTheme(
    pageFormat: format,
    margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 28),
    theme: theme,
    buildBackground: (ctx) {
      return pw.FullPage(
        ignoreMargins: true,
        child: pw.Padding(
          padding: const pw.EdgeInsets.all(16),
          child: pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _pageBorder, width: 1.6),
              borderRadius: pw.BorderRadius.circular(14),
            ),
          ),
        ),
      );
    },
  );

  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageTheme: pageTheme,
      pageFormat: format,
      header: (ctx) {
        final companyName = company.nombreEmpresa.trim().isEmpty
            ? 'FULLTECH'
            : company.nombreEmpresa.trim();

        pw.Widget topRightBox() {
          if (logo != null) {
            return pw.Container(
              width: 44,
              height: 44,
              padding: const pw.EdgeInsets.all(4),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _cardBorder, width: 1),
                borderRadius: pw.BorderRadius.circular(10),
                color: PdfColors.white,
              ),
              child: pw.FittedBox(
                fit: pw.BoxFit.contain,
                child: pw.Image(logo),
              ),
            );
          }

          // Small professional badge (optional)
          final phone = company.telefono.trim();
          if (phone.isNotEmpty) {
            return pw.Container(
              width: 44,
              height: 44,
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _cardBorder, width: 1),
                borderRadius: pw.BorderRadius.circular(10),
                color: PdfColors.white,
              ),
              child: pw.Center(
                child: pw.Text(
                  'WhatsApp',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 7.5,
                    fontWeight: pw.FontWeight.bold,
                    color: accent,
                  ),
                ),
              ),
            );
          }

          return pw.Container(
            width: 44,
            height: 44,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _cardBorder, width: 1),
              borderRadius: pw.BorderRadius.circular(10),
              color: PdfColors.white,
            ),
          );
        }

        pw.Widget companyLeft() {
          return pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (logo != null) ...[
                pw.Container(
                  width: 22,
                  height: 22,
                  padding: const pw.EdgeInsets.all(2),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: _cardBorder, width: 1),
                    borderRadius: pw.BorderRadius.circular(6),
                    color: PdfColors.white,
                  ),
                  child: pw.FittedBox(
                    fit: pw.BoxFit.contain,
                    child: pw.Image(logo),
                  ),
                ),
                pw.SizedBox(width: 8),
              ],
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    companyName,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: _textStrong,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Wrap(
                    spacing: 10,
                    runSpacing: 2,
                    children: [
                      if (company.telefono.trim().isNotEmpty)
                        pw.Text(
                          'Tel/WhatsApp: ${company.telefono.trim()}',
                          style: pw.TextStyle(fontSize: 9, color: _textMuted),
                        ),
                      if (company.rnc != null && company.rnc!.trim().isNotEmpty)
                        pw.Text(
                          'RNC: ${company.rnc!.trim()}',
                          style: pw.TextStyle(fontSize: 9, color: _textMuted),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          );
        }

        final quoteNo = quotationNumber.trim().isEmpty ? idShort : quotationNumber;
        final validityDays = company.validityDays > 0 ? company.validityDays : 0;
        final validUntil = validityDays > 0
            ? createdAt.add(Duration(days: validityDays))
            : null;

        final metaCard = _card(
          padding: const pw.EdgeInsets.all(10),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _kv('Cotización No.', quoteNo),
              _kv('Fecha', _fmtDate(createdAt)),
              _kv('Estado', _statusLabel(status)),
              if (validUntil != null) _kv('Válida hasta', _fmtDate(validUntil)),
            ],
          ),
        );

        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(child: companyLeft()),
                pw.SizedBox(width: 12),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 2),
                          child: pw.Text(
                            'COTIZACIÓN',
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: accent,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 10),
                        topRightBox(),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.SizedBox(width: 250, child: metaCard),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 14),
          ],
        );
      },
      footer: (ctx) {
        pw.Widget contactLine(String text) {
          return pw.Text(
            text,
            style: pw.TextStyle(fontSize: 8.5, color: _textMuted),
          );
        }

        final contactParts = <String>[];
        if (company.telefono.trim().isNotEmpty) {
          contactParts.add('Tel/WhatsApp: ${company.telefono.trim()}');
        }
        if (company.direccion.trim().isNotEmpty) {
          contactParts.add('Dirección: ${company.direccion.trim()}');
        }
        if (company.rnc != null && company.rnc!.trim().isNotEmpty) {
          contactParts.add('RNC: ${company.rnc!.trim()}');
        }
        // Default requested handle; keep optional.
        contactParts.add('Instagram: @fulltechrd');

        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            if (ctx.pageNumber == ctx.pagesCount) ...[
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: _totalsFooterBlock(draft: draft, accent: accent),
              ),
              pw.SizedBox(height: 10),
            ],
            pw.Container(height: 1, color: _cardBorder),
            pw.SizedBox(height: 8),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      for (final part in contactParts)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 2),
                          child: contactLine(part),
                        ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Text(
                  'Página ${ctx.pageNumber} de ${ctx.pagesCount}',
                  style: pw.TextStyle(fontSize: 8.5, color: _textMuted),
                ),
              ],
            ),
          ],
        );
      },
      build: (ctx) {
        final customer = draft.customer;
        final items = draft.items;

        return [
          _card(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Cliente',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _textStrong,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  (customer?.nombre ?? '—').trim().isEmpty
                      ? '—'
                      : (customer?.nombre ?? '—'),
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: _textStrong,
                  ),
                ),
                pw.SizedBox(height: 2),
                if (customer?.telefono != null &&
                    customer!.telefono!.trim().isNotEmpty)
                  pw.Text(
                    'Tel: ${customer.telefono!.trim()}',
                    style: pw.TextStyle(fontSize: 9.5, color: _textMuted),
                  ),
                if (customer?.email != null && customer!.email!.trim().isNotEmpty)
                  pw.Text(
                    'Email: ${customer.email!.trim()}',
                    style: pw.TextStyle(fontSize: 9.5, color: _textMuted),
                  ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Table.fromTextArray(
            headers: const ['CANT.', 'DESCRIPCIÓN', 'PRECIO UNIT.', 'IMPORTE'],
            data: [
              for (final it in items)
                [
                  it.cantidad.toStringAsFixed(it.cantidad % 1 == 0 ? 0 : 2),
                  it.nombre,
                  _fmtMoneyRd(it.unitPrice),
                  _fmtMoneyRd(it.lineNet),
                ],
            ],
            border: pw.TableBorder(
              top: pw.BorderSide(color: _cardBorder, width: 1),
              bottom: pw.BorderSide(color: _cardBorder, width: 1),
              horizontalInside: pw.BorderSide(color: _cardBorder, width: 0.6),
            ),
            headerDecoration: pw.BoxDecoration(
              color: accent,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            headerHeight: 24,
            cellHeight: 24,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            headerStyle: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            cellStyle: pw.TextStyle(fontSize: 9.5, color: _textStrong),
            cellAlignment: pw.Alignment.centerLeft,
            columnWidths: {
              0: const pw.FixedColumnWidth(52),
              1: const pw.FlexColumnWidth(3.8),
              2: const pw.FixedColumnWidth(90),
              3: const pw.FixedColumnWidth(90),
            },
            cellAlignments: {
              0: pw.Alignment.centerRight,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
            },
          ),
          if (notes.trim().isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _card(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Notas',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: _textStrong,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    notes.trim(),
                    style: pw.TextStyle(fontSize: 9.5, color: _textMuted),
                  ),
                ],
              ),
            ),
          ],
          pw.SizedBox(height: 8),
        ];
      },
    ),
  );

  return doc.save();
}

Future<Uint8List> buildQuotationPdfBytesProSafe({
  required QuotationBuilderState draft,
  required String quotationNumber,
  required String idShort,
  required DateTime createdAt,
  required String status,
  required String notes,
  required CompanyProfile company,
  required PdfPageFormat format,
}) async {
  try {
    return await buildQuotationPdfBytesPro(
      draft: draft,
      quotationNumber: quotationNumber,
      idShort: idShort,
      createdAt: createdAt,
      status: status,
      notes: notes,
      company: company,
      format: format,
    );
  } catch (e) {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: format,
        build: (_) => pw.Padding(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Text('Error generando PDF: $e'),
        ),
      ),
    );
    return doc.save();
  }
}
