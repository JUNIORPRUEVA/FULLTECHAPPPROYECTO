import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/module_page.dart';
import '../../../../core/routing/app_routes.dart';

class RulesAccessDeniedScreen extends StatelessWidget {
  const RulesAccessDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ModulePage(
      title: 'Reglas',
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
                    'Acceso denegado',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No tienes permiso para acceder a esta sección.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => context.go(AppRoutes.rules),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Volver a Reglas'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
