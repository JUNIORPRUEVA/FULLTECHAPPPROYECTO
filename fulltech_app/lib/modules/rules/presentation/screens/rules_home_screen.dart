import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/module_page.dart';
import '../../../../core/routing/app_routes.dart';
import '../../state/rules_providers.dart';

class RulesHomeScreen extends ConsumerWidget {
  const RulesHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(rulesIsAdminProvider);

    final items = <_HubItem>[
      _HubItem(
        title: 'Visión, Misión y Valores',
        subtitle: 'Propósito, dirección y valores de la empresa',
        icon: Icons.flag_outlined,
        onTap: () => context.go('${AppRoutes.rules}/vision-mission'),
      ),
      _HubItem(
        title: 'Políticas / Normas de la Empresa',
        subtitle: 'Políticas, normas y reglamentos internos',
        icon: Icons.policy_outlined,
        onTap: () => context.go('${AppRoutes.rules}/policies'),
      ),
      _HubItem(
        title: 'Responsabilidades por Rol',
        subtitle: 'Funciones y responsabilidades por rol',
        icon: Icons.badge_outlined,
        onTap: () => context.go('${AppRoutes.rules}/responsibilities'),
      ),
      _HubItem(
        title: 'Procedimientos / Guías',
        subtitle: 'Qué hacer y qué no, procedimientos y guías',
        icon: Icons.rule_outlined,
        onTap: () => context.go('${AppRoutes.rules}/procedures'),
      ),
      _HubItem(
        title: 'Buscar y Filtrar',
        subtitle: 'Encuentra contenido en todas las reglas',
        icon: Icons.search,
        onTap: () => context.go('${AppRoutes.rules}/search'),
      ),
      if (isAdmin)
        _HubItem(
          title: 'Administrar Contenido',
          subtitle: 'Panel de administración para crear/editar/eliminar',
          icon: Icons.admin_panel_settings_outlined,
          onTap: () => context.go('${AppRoutes.rules}/admin'),
        ),
    ];

    return ModulePage(
      title: 'Reglas',
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GridView.builder(
            padding: const EdgeInsets.only(bottom: 8),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 420,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.2,
            ),
            itemCount: items.length,
            itemBuilder: (context, i) => _HubCard(item: items[i]),
          );
        },
      ),
    );
  }
}

class _HubItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _HubItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}

class _HubCard extends StatelessWidget {
  final _HubItem item;

  const _HubCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(item.icon, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
