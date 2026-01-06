import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../core/widgets/module_page.dart';
import '../../auth/state/auth_providers.dart';
import '../state/display_settings_provider.dart';

class DisplaySettingsScreen extends ConsumerWidget {
  const DisplaySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(displaySettingsProvider);

    return ModulePage(
      title: 'Pantalla',
      child: ListView(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Preferencias de visualización',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    value: settings.fullScreen,
                    title: const Text('Pantalla completa'),
                    subtitle: const Text('Reduce espacios y oculta el footer.'),
                    onChanged: (v) => ref
                        .read(displaySettingsProvider.notifier)
                        .setFullScreen(v),
                  ),
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    value: settings.largeScreenMode,
                    title: const Text('Modo pantalla grande (F1)'),
                    subtitle: const Text('Activa escala, pantalla completa y oculta el sidebar.'),
                    onChanged: (v) async {
                      await ref
                          .read(displaySettingsProvider.notifier)
                          .setLargeScreenMode(v);
                      try {
                        final dio = ref.read(apiClientProvider).dio;
                        await dio.put(
                          '/settings/ui',
                          data: {
                            'largeScreenMode': v,
                            'hideSidebar': v,
                            'scale': v ? 1.15 : 1.0,
                          },
                          options: Options(extra: {'offlineQueue': false, 'offlineCache': false}),
                        );
                      } catch (_) {
                        // Best-effort only.
                      }
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    value: settings.compact,
                    title: const Text('Modo compacto'),
                    subtitle: const Text('Reduce el padding del contenido.'),
                    onChanged: (v) => ref
                        .read(displaySettingsProvider.notifier)
                        .setCompact(v),
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
