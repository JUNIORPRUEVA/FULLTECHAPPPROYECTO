// Pattern note (Step 0):
// - State management: Riverpod (ConsumerStatefulWidget + providers)
// - Routing: GoRouter (nested route under /crm)
// - Networking: ApiClient (Dio) via crmRepositoryProvider
// Files touched (CRM/Operations/shared networking only):
// - lib/features/crm/presentation/pages/crm_instance_settings_page.dart
// - lib/core/routing/app_routes.dart
// - lib/core/routing/app_router.dart
// - lib/features/crm/presentation/widgets/right_panel_crm.dart
// - lib/features/crm/data/{models,datasources,repositories}/*

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/module_page.dart';
import '../../data/models/crm_instance_settings.dart';
import '../../state/crm_providers.dart';

class CrmInstanceSettingsPage extends ConsumerStatefulWidget {
  const CrmInstanceSettingsPage({super.key});

  @override
  ConsumerState<CrmInstanceSettingsPage> createState() =>
      _CrmInstanceSettingsPageState();
}

class _CrmInstanceSettingsPageState extends ConsumerState<CrmInstanceSettingsPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _instanceNameCtrl;
  late final TextEditingController _apiKeyCtrl;
  late final TextEditingController _serverUrlCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _displayNameCtrl;

  bool _showApiKey = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _instanceNameCtrl = TextEditingController();
    _apiKeyCtrl = TextEditingController();
    _serverUrlCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _displayNameCtrl = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  @override
  void dispose() {
    _instanceNameCtrl.dispose();
    _apiKeyCtrl.dispose();
    _serverUrlCtrl.dispose();
    _phoneCtrl.dispose();
    _displayNameCtrl.dispose();
    super.dispose();
  }

  String? _validateRequired(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Este campo es requerido';
    return null;
  }

  String? _validateServerUrl(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null;

    // Accept both:
    // - host[:port][/path]
    // - http(s)://host[:port][/path]
    final normalized = _normalizeServerUrl(s);
    if (normalized == null || normalized.isEmpty) return 'Formato inválido';
    return null;
  }

  String? _normalizeServerUrl(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;

    // If scheme present, normalize to host-only (backend stores host without scheme).
    final hasScheme = s.startsWith('http://') || s.startsWith('https://');
    if (hasScheme) {
      final uri = Uri.tryParse(s);
      if (uri == null || uri.host.trim().isEmpty) return null;
      final port = uri.hasPort ? ':${uri.port}' : '';
      final path = uri.path == '/' ? '' : uri.path;
      final query = uri.hasQuery ? '?${uri.query}' : '';
      return '${uri.host}$port$path$query';
    }

    // host[:port][/path]
    final ok = RegExp(r'^[a-zA-Z0-9.-]+(:\d{2,5})?(/.*)?$').hasMatch(s);
    if (!ok) return null;
    return s;
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(crmRepositoryProvider);
      final current = await repo.getUserInstanceSettings();
      if (!mounted) return;
      _instanceNameCtrl.text = current?.instanceName ?? '';
      _apiKeyCtrl.text = current?.apiKey ?? '';
      _serverUrlCtrl.text = current?.serverUrl ?? '';
      _phoneCtrl.text = current?.phoneE164 ?? '';
      _displayNameCtrl.text = current?.displayName ?? '';
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() => _loading = true);
    try {
      final repo = ref.read(crmRepositoryProvider);
      await repo.saveUserInstanceSettings(
        CrmInstanceSettings(
          instanceName: _instanceNameCtrl.text.trim(),
          apiKey: _apiKeyCtrl.text.trim(),
          serverUrl: _normalizeServerUrl(_serverUrlCtrl.text) ??
              (_serverUrlCtrl.text.trim().isEmpty
                  ? null
                  : _serverUrlCtrl.text.trim()),
          phoneE164: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          displayName: _displayNameCtrl.text.trim().isEmpty
              ? null
              : _displayNameCtrl.text.trim(),
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuración guardada'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ModulePage(
      title: 'Mi Instancia',
      actions: [
        IconButton(
          tooltip: 'Recargar',
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh),
        ),
      ],
      child: ListView(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Configuración de instancia (por usuario)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _instanceNameCtrl,
                      enabled: !_loading,
                      decoration: const InputDecoration(
                        labelText: 'instanceName *',
                        border: OutlineInputBorder(),
                      ),
                      validator: _validateRequired,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _apiKeyCtrl,
                      enabled: !_loading,
                      obscureText: !_showApiKey,
                      decoration: InputDecoration(
                        labelText: 'apiKey *',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: _showApiKey ? 'Ocultar' : 'Mostrar',
                          onPressed: _loading
                              ? null
                              : () => setState(() => _showApiKey = !_showApiKey),
                          icon: Icon(
                            _showApiKey ? Icons.visibility_off : Icons.visibility,
                          ),
                        ),
                      ),
                      validator: _validateRequired,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _serverUrlCtrl,
                      enabled: !_loading,
                      decoration: const InputDecoration(
                        labelText: 'serverUrl',
                        hintText: 'host o dominio (sin http/https)',
                        border: OutlineInputBorder(),
                      ),
                      validator: _validateServerUrl,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneCtrl,
                      enabled: !_loading,
                      decoration: const InputDecoration(
                        labelText: 'phoneE164',
                        hintText: '+18095551234',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _displayNameCtrl,
                      enabled: !_loading,
                      decoration: const InputDecoration(
                        labelText: 'label / displayName',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: _loading ? null : _save,
                        icon: _loading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined),
                        label: const Text('Guardar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
