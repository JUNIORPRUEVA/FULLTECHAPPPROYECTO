import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/pos_models.dart';

Future<Uint8List> buildPosInvoicePdf(PosSale sale) async {
  final doc = pw.Document();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (ctx) {
        return [
          pw.Text(
            'FACTURA',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text('No: ${sale.invoiceNo}${sale.ncf != null ? '  NCF: ${sale.ncf}' : ''}'),
          pw.Text('Tipo: ${sale.invoiceType}   Estado: ${sale.status}'),
          pw.SizedBox(height: 8),
          if ((sale.customerName ?? '').trim().isNotEmpty)
            pw.Text('Cliente: ${sale.customerName}'),
          if ((sale.customerRnc ?? '').trim().isNotEmpty)
            pw.Text('RNC/ID: ${sale.customerRnc}'),
          pw.Divider(),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(4),
              1: const pw.FlexColumnWidth(1.2),
              2: const pw.FlexColumnWidth(1.6),
              3: const pw.FlexColumnWidth(1.6),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('Producto', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('Cant', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('Precio', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
              ...sale.items.map(
                (it) => pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(it.productName),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(it.qty.toStringAsFixed(2)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(it.unitPrice.toStringAsFixed(2)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(it.lineTotal.toStringAsFixed(2)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Subtotal: ${sale.subtotal.toStringAsFixed(2)}'),
                pw.Text('Descuento: ${sale.discountTotal.toStringAsFixed(2)}'),
                pw.Text('ITBIS: ${sale.itbisTotal.toStringAsFixed(2)}'),
                pw.SizedBox(height: 6),
                pw.Text(
                  'TOTAL: ${sale.total.toStringAsFixed(2)}',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                pw.Text('Pagado: ${sale.paidAmount.toStringAsFixed(2)}'),
                pw.Text('Cambio: ${sale.changeAmount.toStringAsFixed(2)}'),
              ],
            ),
          ),
        ];
      },
    ),
  );

  return doc.save();
}
