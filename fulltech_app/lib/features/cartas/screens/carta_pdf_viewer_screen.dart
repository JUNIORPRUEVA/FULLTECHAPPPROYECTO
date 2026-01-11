import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:printing/printing.dart';

import '../../../core/platform/file_saver.dart';
import '../../../core/widgets/module_page.dart';
import '../state/cartas_providers.dart';

class CartaPdfViewerScreen extends ConsumerStatefulWidget {
  final String cartaId;

  const CartaPdfViewerScreen({super.key, required this.cartaId});

  @override
  ConsumerState<CartaPdfViewerScreen> createState() =>
      _CartaPdfViewerScreenState();
}

class _CartaPdfViewerScreenState extends ConsumerState<CartaPdfViewerScreen> {
  Future<Uint8List>? _future;
  Uint8List? _bytes;
  String? _error;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<Uint8List> _load() async {
    try {
      final api = ref.read(cartasApiProvider);
      final bytes = await api.downloadPdfBytes(widget.cartaId);
      if (mounted) {
        setState(() {
          _bytes = bytes;
          _error = null;
        });
      }
      return bytes;
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
      rethrow;
    }
  }

  String get _filename => 'Carta_${widget.cartaId}.pdf';

  Future<void> _share() async {
    final bytes = _bytes;
    if (bytes == null) {
      _toast('Cargando PDF…');
      return;
    }

    try {
      await Printing.sharePdf(bytes: bytes, filename: _filename);
    } catch (e) {
      _toast('No se pudo compartir: $e');
    }
  }

  Future<void> _download() async {
    final bytes = _bytes;
    if (bytes == null) {
      _toast('Cargando PDF…');
      return;
    }

    String? path;
    try {
      path = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar PDF',
        fileName: _filename,
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
    } catch (e) {
      _toast('No se pudo abrir el diálogo para guardar: $e');
      return;
    }

    if (path == null || path.trim().isEmpty) return;

    try {
      await writeBytesToFile(path, bytes);
      _toast('✅ Guardado: $path');
    } catch (e) {
      _toast('No se pudo guardar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModulePage(
      title: 'PDF de Carta',
      actions: [
        IconButton(
          tooltip: 'Compartir',
          onPressed: _bytes == null ? null : _share,
          icon: const Icon(Icons.share_outlined),
        ),
        IconButton(
          tooltip: 'Descargar',
          onPressed: kIsWeb ? null : (_bytes == null ? null : _download),
          icon: const Icon(Icons.download_outlined),
        ),
      ],
      child: FutureBuilder<Uint8List>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text(_error ?? snap.error.toString()));
          }

          final bytes = snap.data;
          if (bytes == null || bytes.isEmpty) {
            return const Center(child: Text('PDF vacío o no disponible'));
          }

          return PdfViewer.data(bytes, sourceName: 'carta.pdf');
        },
      ),
    );
  }
}
