import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/crm_providers.dart';

class EvolutionConfigDialog extends ConsumerStatefulWidget {
  const EvolutionConfigDialog({super.key});

  @override
  ConsumerState<EvolutionConfigDialog> createState() =>
      _EvolutionConfigDialogState();
}

class _EvolutionConfigDialogState extends ConsumerState<EvolutionConfigDialog> {
  late TextEditingController _instanceNameCtrl;
  late TextEditingController _baseUrlCtrl;
  late TextEditingController _apiKeyCtrl;
  late TextEditingController _expectedPhoneCtrl;

  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _status;

  @override
  void initState() {
    super.initState();
    _instanceNameCtrl = TextEditingController();
    _baseUrlCtrl = TextEditingController();
    _apiKeyCtrl = TextEditingController();
    _expectedPhoneCtrl = TextEditingController();
    _loadConfig();
  }

  @override
  void dispose() {
    _instanceNameCtrl.dispose();
    _baseUrlCtrl.dispose();
    _apiKeyCtrl.dispose();
    _expectedPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(crmRepositoryProvider);
      final config = await repo.getEvolutionConfig();
      final status = await repo.getEvolutionStatus();

      if (mounted) {
        setState(() {
          _status = status;
          _instanceNameCtrl.text = config['instanceName'] ?? '';
          _baseUrlCtrl.text = config['evolutionBaseUrl'] ?? '';
          _expectedPhoneCtrl.text = config['expectedPhoneNumber'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error cargando config: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _testPing() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(crmRepositoryProvider);
      final result = await repo.testEvolutionPing();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ping: ${result['message'] ?? 'OK'} (${result['latency']}ms)',
            ),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ping falló: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _testStatus() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(crmRepositoryProvider);
      final status = await repo.getEvolutionStatus();
      if (mounted) {
        setState(() {
          _status = status;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Status: ${status['connected'] == true ? 'Conectado' : 'Desconectado'}',
            ),
            backgroundColor: status['connected'] == true
                ? Colors.green
                : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status falló: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveConfig() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(crmRepositoryProvider);
      await repo.saveEvolutionConfig({
        'instanceName': _instanceNameCtrl.text.trim(),
        'evolutionBaseUrl': _baseUrlCtrl.text.trim(),
        'expectedPhoneNumber': _expectedPhoneCtrl.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuración guardada'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadConfig();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    final isConnected = _status?['connected'] == true;
    final connectedPhone = _status?['phoneNumber'] as String?;
    final expectedPhone = _expectedPhoneCtrl.text.trim();
    final phoneMatches =
        connectedPhone != null &&
        expectedPhone.isNotEmpty &&
        connectedPhone.contains(expectedPhone.replaceAll(RegExp(r'\D'), ''));

    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isMobile ? size.width * 0.92 : 750,
          maxHeight: size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              color: theme.colorScheme.surfaceContainerHighest,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.settings, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Configuración Evolution/WhatsApp',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: Navigator.of(context).pop,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error, color: theme.colorScheme.error),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Sección A: Estado Actual
                    _SectionHeader(title: 'Estado Actual', theme: theme),
                    const SizedBox(height: 12),
                    _buildStatusSection(
                      context,
                      theme,
                      isConnected,
                      connectedPhone,
                      phoneMatches,
                    ),
                    const SizedBox(height: 20),

                    Divider(color: theme.colorScheme.outlineVariant),
                    const SizedBox(height: 20),

                    // Sección B: Acciones Rápidas
                    _SectionHeader(title: 'Acciones Rápidas', theme: theme),
                    const SizedBox(height: 12),
                    _buildActionsSection(context, theme),
                    const SizedBox(height: 20),

                    Divider(color: theme.colorScheme.outlineVariant),
                    const SizedBox(height: 20),

                    // Sección C: Configuración
                    _SectionHeader(title: 'Configuración', theme: theme),
                    const SizedBox(height: 12),
                    _buildConfigSection(context, theme),
                  ],
                ),
              ),
            ),

            // Footer Buttons
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : Navigator.of(context).pop,
                    child: const Text('Cerrar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _saveConfig,
                    icon: _isLoading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                theme.colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Guardar Cambios'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection(
    BuildContext context,
    ThemeData theme,
    bool isConnected,
    String? connectedPhone,
    bool phoneMatches,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chip de estado
        Chip(
          label: Text(
            isConnected ? '🟢 Conectado' : '🔴 Desconectado',
            style: TextStyle(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: isConnected ? Colors.green : Colors.red,
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(height: 12),

        // Validación de instancia
        if (phoneMatches)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              border: Border.all(color: Colors.green),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Instancia correcta - Número coincide',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (connectedPhone != null && _expectedPhoneCtrl.text.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              border: Border.all(color: Colors.amber),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Número conectado NO coincide con el esperado',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.amber,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 12),

        // Info rows
        _InfoRow(
          label: 'Instancia',
          value: _instanceNameCtrl.text.isNotEmpty
              ? _instanceNameCtrl.text
              : 'No configurada',
          theme: theme,
        ),
        const SizedBox(height: 8),
        _InfoRow(
          label: 'Número Conectado',
          value: connectedPhone ?? 'Sin detectar',
          theme: theme,
        ),
        const SizedBox(height: 8),
        _InfoRow(
          label: 'Número Esperado',
          value: _expectedPhoneCtrl.text.isNotEmpty
              ? _expectedPhoneCtrl.text
              : 'No configurado',
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildActionsSection(BuildContext context, ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: _isLoading ? null : _testPing,
          icon: const Icon(Icons.cloud_done, size: 18),
          label: const Text('Probar Ping'),
        ),
        FilledButton.icon(
          onPressed: _isLoading ? null : _testStatus,
          icon: const Icon(Icons.info, size: 18),
          label: const Text('Ver Estado'),
        ),
      ],
    );
  }

  Widget _buildConfigSection(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _instanceNameCtrl,
          decoration: const InputDecoration(
            labelText: 'Nombre de Instancia',
            hintText: 'ej: Fulltech-Main',
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _baseUrlCtrl,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Evolution Base URL',
            hintText: '(desde variables de entorno)',
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _expectedPhoneCtrl,
          decoration: const InputDecoration(
            labelText: 'Número Esperado',
            hintText: 'ej: +1829531942 o 1-829-531-9442',
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Nota: La URL de Evolution y la API Key se configuran vía variables de entorno.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final ThemeData theme;

  const _SectionHeader({required this.title, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: theme.colorScheme.primary,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
