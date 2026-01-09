import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_config.dart';
import '../../../core/services/api_endpoint_settings.dart';
import '../../../core/state/api_endpoint_settings_provider.dart';
import '../../../core/widgets/module_page.dart';
import '../../auth/state/auth_providers.dart';
import '../../auth/state/auth_state.dart';

class ApiEndpointSettingsScreen extends ConsumerStatefulWidget {
  const ApiEndpointSettingsScreen({super.key});

  @override
  ConsumerState<ApiEndpointSettingsScreen> createState() =>
      _ApiEndpointSettingsScreenState();
}

class _ApiEndpointSettingsScreenState
    extends ConsumerState<ApiEndpointSettingsScreen> {
  late final TextEditingController _localUrlController;

  @override
  void initState() {
    super.initState();
    final current = ref.read(apiEndpointSettingsProvider).localBaseUrl;
    _localUrlController = TextEditingController(text: current);
  }

  @override
  void dispose() {
    _localUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(apiEndpointSettingsProvider);
    final auth = ref.watch(authControllerProvider);

    // Keep controller in sync when state changes externally (e.g. load).
    final desired = settings.localBaseUrl;
    if (_localUrlController.text != desired) {
      _localUrlController.text = desired;
      _localUrlController.selection = TextSelection.fromPosition(
        TextPosition(offset: _localUrlController.text.length),
      );
    }

    return ModulePage(
      title: 'Servidor',
      child: ListView(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'API Backend',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<ApiBackend>(
                    key: ValueKey(settings.backend),
                    initialValue: settings.backend,
                    decoration: const InputDecoration(labelText: 'Origen'),
                    items: const [
                      DropdownMenuItem(
                        value: ApiBackend.cloud,
                        child: Text('Nube (producción)'),
                      ),
                      DropdownMenuItem(
                        value: ApiBackend.local,
                        child: Text('Local (desarrollo)'),
                      ),
                    ],
                    onChanged: (v) async {
                      if (v == null) return;
                      if (v == settings.backend) return;

                      if (auth is AuthAuthenticated) {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Confirmación'),
                            content: const Text(
                              'Cambiar el servidor cerrará tu sesión porque los tokens son específicos del servidor.\n\n¿Deseas continuar?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Cancelar'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Sí, continuar'),
                              ),
                            ],
                          ),
                        );
                        if (ok != true) return;
                        await ref.read(authControllerProvider.notifier).logout();
                      }
                      ref
                          .read(apiEndpointSettingsProvider.notifier)
                          .setBackend(v);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _localUrlController,
                    decoration: const InputDecoration(
                      labelText: 'URL local',
                      hintText: 'http://localhost:3000/api',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: () async {
                        final next = _localUrlController.text.trim();
                        if (next.isEmpty) return;
                        if (next == settings.localBaseUrl) return;

                        if (auth is AuthAuthenticated) {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Confirmación'),
                              content: const Text(
                                'Cambiar el servidor cerrará tu sesión porque los tokens son específicos del servidor.\n\n¿Deseas continuar?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Cancelar'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('Sí, continuar'),
                                ),
                              ],
                            ),
                          );
                          if (ok != true) {
                            _localUrlController.text = settings.localBaseUrl;
                            return;
                          }
                          await ref.read(authControllerProvider.notifier).logout();
                        }

                        await ref
                            .read(apiEndpointSettingsProvider.notifier)
                            .setLocalBaseUrl(next);
                      },
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Guardar URL local'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Base efectiva: ${AppConfig.apiBaseUrl}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Nota: En Android emulador usa 10.0.2.2 para apuntar al host.',
                    style: Theme.of(context).textTheme.bodySmall,
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
