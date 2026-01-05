import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../platform/open_file.dart';
import 'module_page.dart';

class PdfViewerPage extends StatefulWidget {
  final String title;
  final Future<String> Function() loadFilePath;

  const PdfViewerPage({
    super.key,
    required this.title,
    required this.loadFilePath,
  });

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  Future<String>? _future;
  String? _path;

  @override
  void initState() {
    super.initState();
    _future = widget.loadFilePath();
  }

  Future<void> _openFile(String filePath) async {
    try {
      await openFilePath(filePath);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return ModulePage(
            title: widget.title,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return ModulePage(
            title: widget.title,
            child: Center(child: Text(snap.error.toString())),
          );
        }

        _path = snap.data;
        final path = _path;
        if (path == null || path.isEmpty) {
          return ModulePage(
            title: widget.title,
            child: const Center(child: Text('No se pudo cargar el PDF')),
          );
        }

        return ModulePage(
          title: widget.title,
          actions: [
            IconButton(
              tooltip: 'Abrir/Descargar',
              onPressed: () => _openFile(path),
              icon: const Icon(Icons.open_in_new),
            ),
          ],
          child: PdfViewer.file(
            path,
            params: const PdfViewerParams(),
          ),
        );
      },
    );
  }
}
