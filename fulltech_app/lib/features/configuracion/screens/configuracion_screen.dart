import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/module_page.dart';
import '../../../core/routing/app_routes.dart';
import '../../auth/state/auth_providers.dart';
import '../../auth/state/auth_state.dart';

class ConfiguracionScreen extends ConsumerWidget {
  const ConfiguracionScreen({super.key});

  bool _isAdmin(WidgetRef ref) {
    final auth = ref.read(authControllerProvider);
    if (auth is! AuthAuthenticated) return false;
    return auth.user.role == 'admin' || auth.user.role == 'administrador';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = _isAdmin(ref);

    final cards = <_SettingsCardModel>[
      if (isAdmin)
        _SettingsCardModel(
          icon: Icons.business,
          title: 'Empresa',
          description: 'Datos de la empresa y logo.',
          route: '${AppRoutes.configuracion}/empresa',
        ),
      if (isAdmin && kDebugMode)
        _SettingsCardModel(
          icon: Icons.cloud_sync,
          title: 'Servidor',
          description: 'Cambiar API nube/local.',
          route: '${AppRoutes.configuracion}/servidor',
        ),
      _SettingsCardModel(
        icon: Icons.palette,
        title: 'Apariencia',
        description: 'Tema y preferencias visuales.',
        route: '${AppRoutes.configuracion}/tema',
      ),
      if (isAdmin)
        _SettingsCardModel(
          icon: Icons.fullscreen,
          title: 'Pantalla',
          description: 'Pantalla completa y modo compacto.',
          route: '${AppRoutes.configuracion}/pantalla',
        ),
    ];

    return ModulePage(
      title: 'Configuración',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Administra la aplicación',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final cols = w >= 1200 ? 4 : (w >= 700 ? 2 : 1);

                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: cols == 1 ? 3.2 : 2.6,
                  ),
                  itemCount: cards.length,
                  itemBuilder: (context, i) {
                    final item = cards[i];
                    return _SettingsCard(
                      icon: item.icon,
                      title: item.title,
                      description: item.description,
                      onTap: () => context.go(item.route),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCardModel {
  final IconData icon;
  final String title;
  final String description;
  final String route;

  const _SettingsCardModel({
    required this.icon,
    required this.title,
    required this.description,
    required this.route,
  });
}

class _SettingsCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  State<_SettingsCard> createState() => _SettingsCardState();
}

class _SettingsCardState extends State<_SettingsCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: _hovered
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onTap,
          onHover: (v) => setState(() => _hovered = v),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(widget.icon, color: colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary.withOpacity(0.8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
