import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../models/pos_models.dart';
import '../../../../features/configuracion/models/company_profile.dart';

final _dateFmt = DateFormat('yyyy-MM-dd HH:mm');

Future<Uint8List> buildPurchaseOrderPdf({
  required PosPurchaseOrder order,
  CompanyProfile? company,
}) async {
  final doc = pw.Document();

  pw.ImageProvider? logo;
  final logoUrl = company?.logoUrl;
  if (logoUrl != null && logoUrl.trim().isNotEmpty) {
    try {
      logo = await networkImage(logoUrl.trim());
    } catch (_) {
      // Ignore logo load failures.
    }
  }

  final headers = <String>['Producto', 'Cant.', 'Costo', 'Total'];

  final data = order.items
      .map(
        (it) => <String>[
          it.productName,
          it.qty.toStringAsFixed(2),
          money(it.unitCost),
          money(it.lineTotal),
        ],
      )
      .toList();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) {
        return [
          if (company != null) _companyHeader(company: company, logo: logo),
          if (company != null) pw.SizedBox(height: 12),

          pw.Text(
            'ORDEN DE COMPRA',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Proveedor: ${order.supplierName}'),
                    pw.Text('Estado: ${order.status}'),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('ID: ${order.id}'),
                  pw.Text('Fecha: ${_dateFmt.format(order.createdAt)}'),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: data,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 6,
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(6),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
            },
          ),
          pw.SizedBox(height: 14),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 220,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  _totalRow('Subtotal', money(order.subtotal)),
                  _totalRow('Total', money(order.total), isBold: true),
                ],
              ),
            ),
          ),
        ];
      },
    ),
  );

  return doc.save();
}

pw.Widget _companyHeader({
  required CompanyProfile company,
  required pw.ImageProvider? logo,
}) {
  final lines = <String>[];
  if (company.direccion.trim().isNotEmpty) lines.add(company.direccion.trim());

  final contact = <String>[];
  if (company.telefono.trim().isNotEmpty) {
    contact.add('Tel: ${company.telefono.trim()}');
  }
  if (company.rnc != null && company.rnc!.trim().isNotEmpty) {
    contact.add('RNC: ${company.rnc!.trim()}');
  }
  if (contact.isNotEmpty) lines.add(contact.join('  |  '));

  if (company.email != null && company.email!.trim().isNotEmpty) {
    lines.add(company.email!.trim());
  }

  return pw.Container(
    padding: const pw.EdgeInsets.only(bottom: 8),
    decoration: const pw.BoxDecoration(
      border: pw.Border(
        bottom: pw.BorderSide(color: PdfColors.grey400, width: 1),
      ),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (logo != null)
          pw.Container(
            width: 56,
            height: 56,
            margin: const pw.EdgeInsets.only(right: 12),
            child: pw.Image(logo, fit: pw.BoxFit.cover),
          ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                company.nombreEmpresa,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 3),
              for (final l in lines)
                pw.Text(l, style: const pw.TextStyle(fontSize: 9)),
            ],
          ),
        ),
      ],
    ),
  );
}

pw.Widget _totalRow(String label, String value, {bool isBold = false}) {
  final style = pw.TextStyle(
    fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
  );
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: style),
        pw.Text(value, style: style),
      ],
    ),
  );
}
