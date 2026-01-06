import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../models/pos_models.dart';
import '../../../../features/configuracion/state/company_profile_providers.dart';
import '../utils/pos_purchase_pdf.dart';

class PosPurchasePdfPreviewPage extends ConsumerWidget {
  final PosPurchaseOrder order;

  const PosPurchasePdfPreviewPage({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyAsync = ref.watch(companyProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orden de compra (PDF)'),
      ),
      body: companyAsync.when(
        data: (company) {
          return PdfPreview(
            build: (format) => buildPurchaseOrderPdf(order: order, company: company),
            allowSharing: true,
            allowPrinting: true,
            canChangeOrientation: false,
            canChangePageFormat: false,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) {
          // Best-effort: still allow PDF, even if header data fails to load.
          return PdfPreview(
            build: (format) => buildPurchaseOrderPdf(order: order),
            allowSharing: true,
            allowPrinting: true,
            canChangeOrientation: false,
            canChangePageFormat: false,
          );
        },
      ),
    );
  }
}
