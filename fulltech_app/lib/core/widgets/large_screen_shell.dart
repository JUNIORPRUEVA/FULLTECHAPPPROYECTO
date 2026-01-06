import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../features/configuracion/state/display_settings_provider.dart';
import '../state/permissions_provider.dart';
import '../../features/auth/state/auth_providers.dart';

class ToggleLargeScreenIntent extends Intent {
  const ToggleLargeScreenIntent();
}

class LargeScreenShell extends ConsumerWidget {
  final Widget child;

  const LargeScreenShell({super.key, required this.child});

  Future<void> _persistUiSettings(WidgetRef ref) async {
    try {
      final s = ref.read(displaySettingsProvider);
      final dio = ref.read(apiClientProvider).dio;
      await dio.put(
        '/settings/ui',
        data: {
          'largeScreenMode': s.largeScreenMode,
          'hideSidebar': s.hideSidebar,
          'scale': s.scale,
        },
        options: Options(extra: {'offlineQueue': false, 'offlineCache': false}),
      );
    } catch (_) {
      // Best-effort only.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final display = ref.watch(displaySettingsProvider);

    final media = MediaQuery.of(context);
    final scaled = media.copyWith(
      textScaler: TextScaler.linear(display.scale),
    );

    return MediaQuery(
      data: scaled,
      child: Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.f1): ToggleLargeScreenIntent(),
        },
        child: Actions(
          actions: {
            ToggleLargeScreenIntent: CallbackAction<ToggleLargeScreenIntent>(
              onInvoke: (_) async {
                await ref.read(displaySettingsProvider.notifier).toggleLargeScreenMode();
                await _persistUiSettings(ref);
                return null;
              },
            ),
          },
          child: Focus(
            autofocus: true,
            child: child,
          ),
        ),
      ),
    );
  }
}

class PermissionsBootstrap extends ConsumerWidget {
  final Widget child;

  const PermissionsBootstrap({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // When authenticated, attempt to load permissions (best-effort).
    // Auth changes are handled by callers; this widget is safe to rebuild.
    ref.listen(permissionsProvider, (_, __) {});
    return child;
  }
}
