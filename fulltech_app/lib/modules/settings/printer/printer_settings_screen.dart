import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/state/auth_providers.dart';
import '../../../core/widgets/module_page.dart';
import 'printer_settings_repository.dart';

final _printerRepoProvider = Provider<PrinterSettingsRepository>((ref) {
  return PrinterSettingsRepository(ref.read(apiClientProvider).dio);
});

class PrinterSettingsScreen extends ConsumerStatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  ConsumerState<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends ConsumerState<PrinterSettingsScreen> {
  bool _loading = true;
  String? _error;

  String _strategy = 'PDF_FALLBACK';
  final _printerNameCtrl = TextEditingController();
  final _paperWidthCtrl = TextEditingController(text: '80');
  final _copiesCtrl = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _printerNameCtrl.dispose();
    _paperWidthCtrl.dispose();
    _copiesCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = ref.read(_printerRepoProvider);
      final s = await repo.getSettings();
      _strategy = s.strategy;
      _printerNameCtrl.text = s.printerName ?? '';
      _paperWidthCtrl.text = s.paperWidthMm.toString();
      _copiesCtrl.text = s.copies.toString();
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

  Future<void> _save() async {
    final repo = ref.read(_printerRepoProvider);

    final paperWidth = int.tryParse(_paperWidthCtrl.text.trim()) ?? 80;
    final copies = int.tryParse(_copiesCtrl.text.trim()) ?? 1;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await repo.saveSettings(
        PrinterSettings(
          strategy: _strategy,
          printerName: _printerNameCtrl.text.trim().isEmpty
              ? null
              : _printerNameCtrl.text.trim(),
          paperWidthMm: paperWidth,
          copies: copies,
        ),
      );

      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuración guardada.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _test() async {
    try {
      final repo = ref.read(_printerRepoProvider);
      await repo.testConnection();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Servicio de impresión OK.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModulePage(
      title: 'Impresora',
      child: ListView(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Preferencias de impresión',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 10),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  DropdownButtonFormField<String>(
                    value: _strategy,
                    decoration: const InputDecoration(
                      labelText: 'Estrategia',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'PDF_FALLBACK',
                        child: Text('PDF (fallback / cliente imprime)'),
                      ),
                      DropdownMenuItem(
                        value: 'WINDOWS_PRINTER',
                        child: Text('Windows (impresión por defecto)'),
                      ),
                      DropdownMenuItem(
                        value: 'RAW_ESCPOS',
                        child: Text('RAW ESC/POS (share/port)'),
                      ),
                    ],
                    onChanged: _loading ? null : (v) => setState(() => _strategy = v ?? 'PDF_FALLBACK'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _printerNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre/Share/Port',
                      hintText: r'Ej: \\localhost\EPSON  o  LPT1',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _paperWidthCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Ancho (mm)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _copiesCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Copias',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _loading ? null : _test,
                        icon: const Icon(Icons.print),
                        label: const Text('Probar'),
                      ),
                      FilledButton.icon(
                        onPressed: _loading ? null : _save,
                        icon: _loading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save),
                        label: const Text('Guardar'),
                      ),
                    ],
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
