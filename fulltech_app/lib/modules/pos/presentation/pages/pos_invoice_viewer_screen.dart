import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:printing/printing.dart';

import '../../../../core/platform/file_saver.dart';
import '../../../../core/widgets/module_page.dart';
import '../../models/pos_models.dart';
import '../widgets/pos_invoice_pdf.dart';

class PosInvoiceViewerScreen extends ConsumerStatefulWidget {
  final PosSale sale;

  const PosInvoiceViewerScreen({super.key, required this.sale});

  @override
  ConsumerState<PosInvoiceViewerScreen> createState() =>
      _PosInvoiceViewerScreenState();
}

class _PosInvoiceViewerScreenState extends ConsumerState<PosInvoiceViewerScreen> {
  Future<Uint8List>? _future;
  Uint8List? _bytes;
  PdfViewerController? _viewer;

  @override
  void initState() {
    super.initState();
    _future = _generate();
  }

  bool get _isDesktopPlatform {
    if (kIsWeb) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return true;
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        return false;
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _filename() {
    final invoice = widget.sale.invoiceNo.trim().isEmpty
        ? widget.sale.id
        : widget.sale.invoiceNo.trim();
    return 'Factura_$invoice.pdf';
  }

  Future<Uint8List> _generate() async {
    final bytes = await buildPosInvoicePdf(widget.sale);
    if (mounted) setState(() => _bytes = bytes);
    return bytes;
  }

  Future<void> _download() async {
    final bytes = _bytes;
    if (bytes == null || bytes.isEmpty) {
      _toast('Generando PDF…');
      return;
    }

    final filename = _filename();

    String? path;
    try {
      path = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar PDF',
        fileName: filename,
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
    } catch (e) {
      _toast('No se pudo abrir el diálogo para guardar: $e');
      return;
    }

    if (path == null || path.trim().isEmpty) {
      if (kIsWeb || _isDesktopPlatform) return;
      try {
        final dir = await getApplicationDocumentsDirectory();
        final fallbackPath = p.join(dir.path, filename);
        await writeBytesToFile(fallbackPath, bytes);
        _toast('PDF guardado');
      } catch (e) {
        _toast('No se pudo guardar: $e');
      }
      return;
    }

    try {
      await writeBytesToFile(path, bytes);
      _toast('PDF guardado');
    } catch (e) {
      _toast('No se pudo guardar: $e');
    }
  }

  Future<void> _share() async {
    final bytes = _bytes;
    if (bytes == null || bytes.isEmpty) {
      _toast('Generando PDF…');
      return;
    }

    try {
      await Printing.sharePdf(bytes: bytes, filename: _filename());
    } catch (e) {
      _toast('No se pudo compartir: $e');
    }
  }

  Future<void> _print() async {
    final bytes = _bytes;
    if (bytes == null || bytes.isEmpty) {
      _toast('Generando PDF…');
      return;
    }

    try {
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      _toast('No se pudo imprimir: $e');
    }
  }

  Future<void> _zoomIn() async {
    final v = _viewer;
    if (v == null || !v.isReady) return;
    await v.zoomUp(zoomCenter: v.visibleRect.center);
  }

  Future<void> _zoomOut() async {
    final v = _viewer;
    if (v == null || !v.isReady) return;
    await v.zoomDown(zoomCenter: v.visibleRect.center);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const ModulePage(
            title: 'Factura',
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return ModulePage(
            title: 'Factura',
            child: Center(child: Text('Error: ${snap.error}')),
          );
        }

        final bytes = snap.data;
        if (bytes == null || bytes.isEmpty) {
          return const ModulePage(
            title: 'Factura',
            child: Center(child: Text('No se pudo generar el PDF')),
          );
        }

        return ModulePage(
          title: 'Factura',
          actions: [
            if (_isDesktopPlatform) ...[
              IconButton(
                tooltip: 'Zoom -',
                onPressed: _zoomOut,
                icon: const Icon(Icons.zoom_out),
              ),
              IconButton(
                tooltip: 'Zoom +',
                onPressed: _zoomIn,
                icon: const Icon(Icons.zoom_in),
              ),
            ],
            IconButton(
              tooltip: 'Descargar',
              onPressed: _download,
              icon: const Icon(Icons.download),
            ),
            IconButton(
              tooltip: 'Compartir',
              onPressed: _share,
              icon: const Icon(Icons.share),
            ),
            IconButton(
              tooltip: 'Imprimir',
              onPressed: _print,
              icon: const Icon(Icons.print),
            ),
          ],
          child: Listener(
            onPointerSignal: (event) {
              _viewer?.handlePointerSignalEvent(event);
            },
            child: PdfViewer.data(
              bytes,
              sourceName: _filename(),
              params: PdfViewerParams(
                onViewerReady: (document, controller) {
                  _viewer = controller;
                },
                maxScale: 8,
                minScale: 0.8,
                useAlternativeFitScaleAsMinScale: true,
                enableKeyboardNavigation: true,
              ),
            ),
          ),
        );
      },
    );
  }
}
