import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_config.dart';
import '../../../core/services/api_endpoint_settings.dart';
import '../../../core/state/api_endpoint_settings_provider.dart';
import '../../../core/widgets/module_page.dart';

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
                    onChanged: (v) {
                      if (v == null) return;
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
                    onFieldSubmitted: (v) {
                      ref
                          .read(apiEndpointSettingsProvider.notifier)
                          .setLocalBaseUrl(v);
                    },
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
