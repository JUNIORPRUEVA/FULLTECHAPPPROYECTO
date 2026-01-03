import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/state/auth_providers.dart';
import '../../features/auth/state/auth_state.dart';
import '../../features/configuracion/state/display_settings_provider.dart';
import '../routing/app_routes.dart';
import 'app_footer.dart';
import 'app_sidebar.dart';
import 'fulltech_app_bar.dart';
import 'sidebar_items.dart';
import '../theme/app_colors.dart';

class MainLayout extends ConsumerWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = GoRouter.maybeOf(context);
    final location =
        router?.routeInformationProvider.value.uri.toString() ?? '';
    final auth = ref.watch(authControllerProvider);

    final userName = auth is AuthAuthenticated ? auth.user.name : 'Usuario';
    final userRole = auth is AuthAuthenticated ? auth.user.role : null;

    final displaySettings = ref.watch(displaySettingsProvider);
    final contentPadding = displaySettings.fullScreen
        ? EdgeInsets.zero
        : EdgeInsets.all(displaySettings.compact ? 8 : 12);

    final isMobile = MediaQuery.of(context).size.width < 900;

    final sidebar = AppSidebar(currentRoute: location);

    return Scaffold(
      appBar: FulltechAppBar(
        userName: userName,
        userRole: userRole,
        onOpenProfile: () => context.go(AppRoutes.perfil),
        onLogout: () => ref.read(authControllerProvider.notifier).logout(),
      ),
      drawer: isMobile
          ? Drawer(
              backgroundColor: Colors.transparent,
              child: SafeArea(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.sidebarGradient,
                  ),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    children: [
                      const ListTile(
                        title: Text(
                          'Menú',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        leading: Icon(Icons.menu, color: Colors.white),
                      ),
                      const Divider(height: 1, color: AppColors.sidebarDivider),
                      const SizedBox(height: 8),
                      ...primarySidebarItems.map(
                        (item) => _DrawerNavTile(
                          item: item,
                          selected: location.startsWith(item.route),
                          onTap: () {
                            Navigator.of(context).pop();
                            context.go(item.route);
                          },
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Divider(
                          color: AppColors.sidebarDivider,
                          height: 24,
                        ),
                      ),
                      ...secondarySidebarItems.map(
                        (item) => _DrawerNavTile(
                          item: item,
                          selected: location.startsWith(item.route),
                          onTap: () {
                            Navigator.of(context).pop();
                            context.go(item.route);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                if (!isMobile) sidebar,
                Expanded(
                  child: Padding(padding: contentPadding, child: child),
                ),
              ],
            ),
          ),
          if (!displaySettings.fullScreen) const AppFooter(),
        ],
      ),
    );
  }
}

class _DrawerNavTile extends StatelessWidget {
  final SidebarItem item;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerNavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: selected ? AppColors.sidebarItemActiveBg : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: SizedBox(
            height: 48,
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 32,
                  margin: const EdgeInsets.only(left: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.corporateBlueBright
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  item.icon,
                  color: Colors.white.withOpacity(selected ? 1 : 0.82),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: (textTheme.labelLarge ?? const TextStyle()).copyWith(
                      color: Colors.white,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
