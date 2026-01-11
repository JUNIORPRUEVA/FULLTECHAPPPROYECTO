import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../configuracion/models/company_profile.dart';
import '../state/quotation_builder_state.dart';
import '../models/quotation_models.dart';

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

  final itbisLabel = 'ITBIS (${(draft.itbisRate * 100).toStringAsFixed(0)}%)';

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
          child: row('TOTAL', _fmtMoneyRd(draft.total), strong: true),
        ),
      ],
    ),
  );
}

pw.Widget _termsBlock({
  required CompanyProfile company,
  required QuotationBuilderState draft,
}) {
  final validityDays = company.validityDays > 0 ? company.validityDays : 0;
  final lines = <String>[
    if (validityDays > 0) 'Validez de la cotización: $validityDays días.',
    r'Precios en pesos dominicanos (RD$).',
    if (draft.itbisEnabled)
      'Incluye ITBIS (${(draft.itbisRate * 100).toStringAsFixed(0)}%).'
    else
      'No incluye ITBIS.',
    'Forma de pago: a convenir.',
    'Entrega/instalación: a coordinar.',
  ];

  return _card(
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Términos y condiciones',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: _textStrong,
          ),
        ),
        pw.SizedBox(height: 6),
        for (final l in lines)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 2),
            child: pw.Text(
              '• $l',
              style: pw.TextStyle(fontSize: 9.2, color: _textMuted),
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

  // PdfGoogleFonts fetches fonts over the network; keep a robust fallback
  // so the PDF can be generated offline.
  late final pw.Font baseFont;
  late final pw.Font boldFont;
  try {
    baseFont = await PdfGoogleFonts.interRegular();
    boldFont = await PdfGoogleFonts.interSemiBold();
  } catch (_) {
    baseFont = pw.Font.helvetica();
    boldFont = pw.Font.helveticaBold();
  }
  final theme = pw.ThemeData.withFont(base: baseFont, bold: boldFont);

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
      header: (ctx) {
        final companyName = company.nombreEmpresa.trim().isEmpty
            ? 'FULLTECH'
            : company.nombreEmpresa.trim();

        pw.Widget companyLeft() {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logo != null) ...[
                    pw.Container(
                      width: 50,
                      height: 50,
                      padding: const pw.EdgeInsets.all(4),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: accent, width: 2),
                        borderRadius: pw.BorderRadius.circular(8),
                        color: PdfColors.white,
                      ),
                      child: pw.FittedBox(
                        fit: pw.BoxFit.contain,
                        child: pw.Image(logo),
                      ),
                    ),
                    pw.SizedBox(width: 12),
                  ],
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          companyName,
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: accent,
                            letterSpacing: 0.5,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Soluciones Tecnológicas y Servicios Profesionales',
                          style: pw.TextStyle(
                            fontSize: 8.5,
                            color: _textMuted,
                            fontStyle: pw.FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: pw.BoxDecoration(
                  color: _cardBg,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: _cardBorder, width: 1),
                ),
                child: pw.Wrap(
                  spacing: 12,
                  runSpacing: 3,
                  children: [
                    if (company.telefono.trim().isNotEmpty)
                      pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Container(
                            width: 4,
                            height: 4,
                            decoration: pw.BoxDecoration(
                              color: accent,
                              shape: pw.BoxShape.circle,
                            ),
                          ),
                          pw.SizedBox(width: 4),
                          pw.Text(
                            '${company.telefono.trim()}',
                            style: pw.TextStyle(
                              fontSize: 8.5,
                              color: _textStrong,
                            ),
                          ),
                        ],
                      ),
                    if (company.email != null &&
                        company.email!.trim().isNotEmpty)
                      pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Container(
                            width: 4,
                            height: 4,
                            decoration: pw.BoxDecoration(
                              color: accent,
                              shape: pw.BoxShape.circle,
                            ),
                          ),
                          pw.SizedBox(width: 4),
                          pw.Text(
                            '${company.email!.trim()}',
                            style: pw.TextStyle(
                              fontSize: 8.5,
                              color: _textStrong,
                            ),
                          ),
                        ],
                      ),
                    if (company.rnc != null && company.rnc!.trim().isNotEmpty)
                      pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Container(
                            width: 4,
                            height: 4,
                            decoration: pw.BoxDecoration(
                              color: accent,
                              shape: pw.BoxShape.circle,
                            ),
                          ),
                          pw.SizedBox(width: 4),
                          pw.Text(
                            'RNC: ${company.rnc!.trim()}',
                            style: pw.TextStyle(
                              fontSize: 8.5,
                              color: _textStrong,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          );
        }

        final quoteNo = quotationNumber.trim().isEmpty
            ? idShort
            : quotationNumber;
        final validityDays = company.validityDays > 0
            ? company.validityDays
            : 0;
        final validUntil = validityDays > 0
            ? createdAt.add(Duration(days: validityDays))
            : null;

        final metaCard = pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            border: pw.Border.all(color: accent, width: 2),
            borderRadius: pw.BorderRadius.circular(10),
            boxShadow: [
              pw.BoxShadow(
                color: _cardBorder,
                offset: const PdfPoint(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'COTIZACIÓN',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: accent,
                      letterSpacing: 1,
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: pw.BoxDecoration(
                      color: accent,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      _statusLabel(status),
                      style: const pw.TextStyle(
                        fontSize: 7.5,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                ],
              ),
              pw.Container(
                margin: const pw.EdgeInsets.symmetric(vertical: 8),
                height: 1,
                color: _cardBorder,
              ),
              _kv('No.', quoteNo),
              pw.SizedBox(height: 2),
              _kv('Fecha', _fmtDate(createdAt)),
              if (validUntil != null) ...[
                pw.SizedBox(height: 2),
                _kv('Válida hasta', _fmtDate(validUntil)),
              ],
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
                pw.SizedBox(width: 16),
                pw.SizedBox(width: 240, child: metaCard),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Container(
              height: 2,
              decoration: pw.BoxDecoration(
                gradient: pw.LinearGradient(
                  colors: [accent.flatten(), _cardBorder, accent.flatten()],
                ),
              ),
            ),
            pw.SizedBox(height: 16),
          ],
        );
      },
      footer: (ctx) {
        pw.Widget contactLine(String icon, String text) {
          return pw.Row(
            children: [
              pw.Container(
                width: 3,
                height: 3,
                decoration: pw.BoxDecoration(
                  color: accent,
                  shape: pw.BoxShape.circle,
                ),
              ),
              pw.SizedBox(width: 4),
              pw.Text(
                text,
                style: pw.TextStyle(fontSize: 8.5, color: _textMuted),
              ),
            ],
          );
        }

        final contactLines = <pw.Widget>[];

        // Línea 1: Teléfono y Email
        final line1Parts = <String>[];
        if (company.telefono.trim().isNotEmpty) {
          line1Parts.add('Tel/WhatsApp: ${company.telefono.trim()}');
        }
        if (company.email != null && company.email!.trim().isNotEmpty) {
          line1Parts.add('Email: ${company.email!.trim()}');
        }
        if (line1Parts.isNotEmpty) {
          contactLines.add(contactLine('', line1Parts.join('  •  ')));
        }

        // Línea 2: Dirección y RNC
        final line2Parts = <String>[];
        if (company.direccion.trim().isNotEmpty) {
          line2Parts.add('Dirección: ${company.direccion.trim()}');
        }
        if (company.rnc != null && company.rnc!.trim().isNotEmpty) {
          line2Parts.add('RNC: ${company.rnc!.trim()}');
        }
        if (line2Parts.isNotEmpty) {
          contactLines.add(contactLine('', line2Parts.join('  •  ')));
        }

        // Línea 3: Redes sociales y web (siempre mostrar)
        contactLines.add(
          contactLine('', 'Instagram: @fulltechrd  •  Web: www.fulltechrd.com'),
        );

        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Container(
              height: 1.5,
              decoration: pw.BoxDecoration(
                gradient: pw.LinearGradient(
                  colors: [accent.flatten(), _cardBorder],
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      for (final line in contactLines)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 3),
                          child: line,
                        ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: pw.BoxDecoration(
                    color: accent.flatten(),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    'Pág. ${ctx.pageNumber}/${ctx.pagesCount}',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                'Documento generado electrónicamente - FULLTECH',
                style: pw.TextStyle(
                  fontSize: 7,
                  color: _textMuted,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ),
          ],
        );
      },
      build: (ctx) {
        final customer = draft.customer;
        final items = draft.items;

        final hasDiscount = items.any((it) => it.lineDiscount > 0.0001);

        String fmtQty(double v) {
          final isInt = (v % 1) == 0;
          return v.toStringAsFixed(isInt ? 0 : 2);
        }

        String fmtDiscount(QuotationItemDraft it) {
          if (it.lineDiscount <= 0) return '—';
          if (it.discountMode == QuotationDiscountMode.percent) {
            final pct = it.discountPct;
            if (pct <= 0) return _fmtMoneyRd(it.lineDiscount);
            return '${pct.toStringAsFixed(pct % 1 == 0 ? 0 : 2)}%';
          }
          return _fmtMoneyRd(it.discountAmount);
        }

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
                if (customer?.email != null &&
                    customer!.email!.trim().isNotEmpty)
                  pw.Text(
                    'Email: ${customer.email!.trim()}',
                    style: pw.TextStyle(fontSize: 9.5, color: _textMuted),
                  ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Table.fromTextArray(
            headers: hasDiscount
                ? const ['CANT.', 'DESCRIPCIÓN', 'P. UNIT.', 'DESC.', 'IMPORTE']
                : const ['CANT.', 'DESCRIPCIÓN', 'P. UNIT.', 'IMPORTE'],
            data: [
              for (final it in items)
                if (hasDiscount)
                  [
                    fmtQty(it.cantidad),
                    it.nombre,
                    _fmtMoneyRd(it.unitPrice),
                    fmtDiscount(it),
                    _fmtMoneyRd(it.lineNet),
                  ]
                else
                  [
                    fmtQty(it.cantidad),
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
            headerDecoration: pw.BoxDecoration(color: accent),
            headerHeight: 22,
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
            headerStyle: pw.TextStyle(
              fontSize: 8.8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            cellStyle: pw.TextStyle(fontSize: 9.2, color: _textStrong),
            cellAlignment: pw.Alignment.topLeft,
            columnWidths: hasDiscount
                ? {
                    0: const pw.FixedColumnWidth(46),
                    1: const pw.FlexColumnWidth(3.6),
                    2: const pw.FixedColumnWidth(76),
                    3: const pw.FixedColumnWidth(60),
                    4: const pw.FixedColumnWidth(78),
                  }
                : {
                    0: const pw.FixedColumnWidth(46),
                    1: const pw.FlexColumnWidth(3.9),
                    2: const pw.FixedColumnWidth(86),
                    3: const pw.FixedColumnWidth(86),
                  },
            cellAlignments: hasDiscount
                ? {
                    0: pw.Alignment.topRight,
                    1: pw.Alignment.topLeft,
                    2: pw.Alignment.topRight,
                    3: pw.Alignment.topRight,
                    4: pw.Alignment.topRight,
                  }
                : {
                    0: pw.Alignment.topRight,
                    1: pw.Alignment.topLeft,
                    2: pw.Alignment.topRight,
                    3: pw.Alignment.topRight,
                  },
          ),
          pw.SizedBox(height: 12),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: _totalsFooterBlock(draft: draft, accent: accent),
          ),
          pw.SizedBox(height: 12),
          _termsBlock(company: company, draft: draft),
          if (notes.trim().isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _card(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Notas / Observaciones',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: _textStrong,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    notes.trim(),
                    style: pw.TextStyle(fontSize: 9.2, color: _textMuted),
                  ),
                ],
              ),
            ),
          ],
          pw.SizedBox(height: 6),
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
