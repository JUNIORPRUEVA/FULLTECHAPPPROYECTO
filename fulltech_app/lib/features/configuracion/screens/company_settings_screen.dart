import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/module_page.dart';
import '../../auth/state/auth_providers.dart';

class CompanySettingsScreen extends ConsumerStatefulWidget {
  const CompanySettingsScreen({super.key});

  @override
  ConsumerState<CompanySettingsScreen> createState() =>
      _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends ConsumerState<CompanySettingsScreen> {
  final _empresaCtrl = TextEditingController();
  final _rncCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  String? _logoUrl;
  PlatformFile? _newLogo;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _empresaCtrl.dispose();
    _rncCtrl.dispose();
    _direccionCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  String _publicUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;

    final base = ref.read(apiClientProvider).dio.options.baseUrl;
    final root = base.endsWith('/api')
        ? base.substring(0, base.length - 4)
        : base;
    return '$root$path';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final dio = ref.read(apiClientProvider).dio;
      final res = await dio.get('/company-settings');
      final data = res.data as Map<String, dynamic>;
      final item = data['item'] as Map<String, dynamic>?;

      _empresaCtrl.text = (item?['nombre_empresa'] ?? '') as String;
      _rncCtrl.text = (item?['rnc'] ?? '') as String;
      _direccionCtrl.text = (item?['direccion'] ?? '') as String;
      _telefonoCtrl.text = (item?['telefono'] ?? '') as String;

      final rawLogo = item?['logo_url'];
      _logoUrl = rawLogo is String && rawLogo.trim().isNotEmpty
          ? rawLogo.trim()
          : null;

      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _pickLogo() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (res == null || res.files.isEmpty) return;

    final f = res.files.first;
    if (f.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo leer el archivo (bytes nulos).'),
        ),
      );
      return;
    }

    setState(() => _newLogo = f);
  }

  MultipartFile _toMultipart(PlatformFile f) {
    final bytes = f.bytes ?? Uint8List(0);
    final filename = f.name;
    return MultipartFile.fromBytes(bytes, filename: filename);
  }

  Future<void> _uploadLogo() async {
    if (_newLogo == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final dio = ref.read(apiClientProvider).dio;
      final form = FormData.fromMap({'file': _toMultipart(_newLogo!)});
      final res = await dio.post('/company-settings/logo', data: form);
      final data = res.data as Map<String, dynamic>;
      final logoUrl = data['logo_url'];

      if (logoUrl is String && logoUrl.trim().isNotEmpty) {
        _logoUrl = logoUrl.trim();
      }
      _newLogo = null;

      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Logo actualizado.')));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _save() async {
    final nombre = _empresaCtrl.text.trim();
    final rnc = _rncCtrl.text.trim();
    final direccion = _direccionCtrl.text.trim();
    final telefono = _telefonoCtrl.text.trim();

    if (nombre.length < 2 ||
        rnc.length < 2 ||
        direccion.length < 3 ||
        telefono.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Complete los campos requeridos (empresa, RNC, dirección, teléfono).',
          ),
        ),
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final dio = ref.read(apiClientProvider).dio;
      await dio.put(
        '/company-settings',
        data: {
          'nombre_empresa': nombre,
          'rnc': rnc,
          'direccion': direccion,
          'telefono': telefono,
        },
      );
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Empresa guardada.')));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewBytes = _newLogo?.bytes;

    return ModulePage(
      title: 'Empresa',
      child: ListView(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Branding',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 72,
                          height: 72,
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          child: () {
                            if (previewBytes != null) {
                              return Image.memory(
                                previewBytes,
                                fit: BoxFit.cover,
                              );
                            }
                            if (_logoUrl != null) {
                              return Image.network(
                                _publicUrl(_logoUrl!),
                                fit: BoxFit.cover,
                              );
                            }
                            return const Icon(Icons.business);
                          }(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _loading ? null : _pickLogo,
                              icon: const Icon(Icons.upload),
                              label: const Text('Seleccionar logo'),
                            ),
                            const SizedBox(height: 8),
                            FilledButton.icon(
                              onPressed: (_loading || _newLogo == null)
                                  ? null
                                  : _uploadLogo,
                              icon: _loading
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.save),
                              label: const Text('Subir logo'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Datos de la empresa',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  TextField(
                    controller: _empresaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre legal',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _rncCtrl,
                    decoration: const InputDecoration(labelText: 'RNC'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _direccionCtrl,
                    decoration: const InputDecoration(labelText: 'Dirección'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _telefonoCtrl,
                    decoration: const InputDecoration(labelText: 'Teléfono'),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _loading ? null : _save,
                    child: _loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Guardar empresa'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
