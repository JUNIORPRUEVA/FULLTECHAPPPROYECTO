import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/module_page.dart';
import '../../state/pos_providers.dart';

class PosCashboxGuard extends ConsumerWidget {
  const PosCashboxGuard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final openAsync = ref.watch(posCashboxOpenProvider);

    return openAsync.when(
      data: (open) {
        if (open) return child;

        return ModulePage(
          title: 'POS',
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Para usar POS debes abrir caja',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Abre la caja para habilitar TPV, inventario POS, reportes y compras.',
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: () => context.go(AppRoutes.posCaja),
                        icon: const Icon(Icons.lock_open_outlined),
                        label: const Text('Ir a Caja'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => ref.refresh(posCashboxOpenProvider),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const ModulePage(
        title: 'POS',
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => ModulePage(
        title: 'POS',
        child: Center(
          child: Text(
            'Error validando caja: $e',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
    );
  }
}

