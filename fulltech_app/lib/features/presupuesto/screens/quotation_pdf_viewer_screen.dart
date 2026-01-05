import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:printing/printing.dart';

import '../../../core/platform/file_saver.dart';
import '../../../core/widgets/module_page.dart';
import '../../configuracion/state/company_profile_providers.dart';
import '../services/quotation_pdf_service.dart';
import '../state/quotation_builder_state.dart';

class QuotationPdfViewerScreen extends ConsumerStatefulWidget {
  final QuotationBuilderState draft;
  final Map<String, dynamic> quotationMeta;

  const QuotationPdfViewerScreen({
    super.key,
    required this.draft,
    required this.quotationMeta,
  });

  @override
  ConsumerState<QuotationPdfViewerScreen> createState() =>
      _QuotationPdfViewerScreenState();
}

class _QuotationPdfViewerScreenState
    extends ConsumerState<QuotationPdfViewerScreen> {
  Future<Uint8List>? _future;
  Uint8List? _bytes;
  String? _filename;
  PdfViewerController? _viewer;

  @override
  void initState() {
    super.initState();
    _future = _generate();
  }

  String _shortId({required String id, required String numero}) {
    final n = numero.trim();
    if (n.isNotEmpty) return n;
    final trimmed = id.trim();
    if (trimmed.isEmpty) return 'SIN_ID';
    return trimmed.length <= 8 ? trimmed : trimmed.substring(0, 8);
  }

  String _fmtDateForFilename(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}${two(dt.month)}${two(dt.day)}';
  }

  Future<Uint8List> _generate() async {
    final company = await ref.read(companyProfileProvider.future);

    final numero = (widget.quotationMeta['numero'] ?? '').toString();
    final id = (widget.quotationMeta['id'] ?? '').toString();
    final idShort = _shortId(id: id, numero: numero);

    final createdAtRaw =
        (widget.quotationMeta['created_at'] ??
                widget.quotationMeta['createdAt'])
            ?.toString();
    final createdAt = DateTime.tryParse(createdAtRaw ?? '') ?? DateTime.now();

    final status = (widget.quotationMeta['status'] ?? 'draft').toString();
    final filename =
        'Cotizacion_FULLTECH_${idShort}_${_fmtDateForFilename(createdAt)}.pdf';

    final notes = (widget.quotationMeta['notes'] ?? '').toString();

    final bytes = await buildQuotationPdfBytesProSafe(
      draft: widget.draft,
      quotationNumber: numero,
      idShort: idShort,
      createdAt: createdAt,
      status: status,
      notes: notes,
      company: company,
      format: PdfPageFormat.a4,
    );

    if (mounted) {
      setState(() {
        _bytes = bytes;
        _filename = filename;
      });
    }

    return bytes;
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

  Future<void> _download() async {
    final bytes = _bytes;
    final filename = _filename;
    if (bytes == null || filename == null) {
      _toast('Generando PDF…');
      return;
    }

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
    final filename = _filename;
    if (bytes == null || filename == null) {
      _toast('Generando PDF…');
      return;
    }

    try {
      await Printing.sharePdf(bytes: bytes, filename: filename);
    } catch (e) {
      _toast('No se pudo compartir: $e');
    }
  }

  Future<void> _zoomIn() async {
    final v = _viewer;
    if (v == null || !v.isReady) return;
    final center = v.visibleRect.center;
    await v.zoomUp(zoomCenter: center);
  }

  Future<void> _zoomOut() async {
    final v = _viewer;
    if (v == null || !v.isReady) return;
    final center = v.visibleRect.center;
    await v.zoomDown(zoomCenter: center);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const ModulePage(
            title: 'Cotización',
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return ModulePage(
            title: 'Cotización',
            child: Center(child: Text('Error: ${snap.error}')),
          );
        }

        final bytes = snap.data;
        if (bytes == null || bytes.isEmpty) {
          return const ModulePage(
            title: 'Cotización',
            child: Center(child: Text('No se pudo generar el PDF')),
          );
        }

        return ModulePage(
          title: 'Cotización',
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
          ],
          child: Listener(
            onPointerSignal: (event) {
              // Keep wheel events usable even inside nested layouts.
              _viewer?.handlePointerSignalEvent(event);
            },
            child: PdfViewer.data(
              bytes,
              sourceName: _filename ?? 'Cotizacion.pdf',
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
