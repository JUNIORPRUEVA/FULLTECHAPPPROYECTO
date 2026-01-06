import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/auto_sync.dart';
import 'core/widgets/large_screen_shell.dart';
import 'features/configuracion/state/theme_provider.dart';

class FulltechApp extends ConsumerWidget {
  const FulltechApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'FULLTECH CRM & Operaciones',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        return LargeScreenShell(
          child: AutoSync(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}
