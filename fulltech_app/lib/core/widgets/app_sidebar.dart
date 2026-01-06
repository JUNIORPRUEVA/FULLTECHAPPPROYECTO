import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../../features/configuracion/state/display_settings_provider.dart';
import '../state/permissions_provider.dart';
import '../routing/app_routes.dart';
import 'layout_provider.dart';
import 'sidebar_items.dart';

class AppSidebar extends ConsumerWidget {
  final String currentRoute;

  const AppSidebar({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collapsed = ref.watch(sidebarCollapsedProvider);
    final displaySettings = ref.watch(displaySettingsProvider);
    final textTheme = Theme.of(context).textTheme;

    final permsAsync = ref.watch(permissionsProvider);

    bool can(String code) {
      return permsAsync.maybeWhen(
        data: (s) => s.has(code),
        orElse: () => false,
      );
    }

    bool allowRoute(String route) {
      // If permissions haven't loaded yet, keep current UX (don't hide).
      final loaded = permsAsync is AsyncData<PermissionsState>;
      if (!loaded) return true;

      if (route == AppRoutes.pos) return can('pos.sell');
      if (route == AppRoutes.posPurchases) return can('pos.purchases.manage');
      if (route == AppRoutes.posInventory) return can('pos.inventory.adjust');
      if (route == AppRoutes.posReports) return can('pos.reports.view');
      if (route == AppRoutes.usuarios) return can('users.view');
      return true;
    }

    final visiblePrimaryItems = primarySidebarItems
        .map(
          (it) => SidebarItem(
            label: it.label,
            icon: it.icon,
            route: it.route,
            children: it.children.where((c) => allowRoute(c.route)).toList(),
          ),
        )
        .where((it) => allowRoute(it.route))
        .toList();

    if (displaySettings.hideSidebar) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      width: collapsed ? 72 : 260,
      decoration: const BoxDecoration(gradient: AppColors.sidebarGradient),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    tooltip: collapsed ? 'Expandir menú' : 'Colapsar menú',
                    onPressed: () =>
                        ref.read(sidebarCollapsedProvider.notifier).state =
                            !collapsed,
                    icon: Icon(
                      collapsed ? Icons.chevron_right : Icons.chevron_left,
                      color: Colors.white,
                    ),
                  ),
                  if (!collapsed) ...[
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Menú',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                children: [
                  for (final item in visiblePrimaryItems) ...[
                    _SidebarNavItem(
                      item: item,
                      isCollapsed: collapsed,
                      isSelected: currentRoute.startsWith(item.route) ||
                          item.children.any(
                            (c) => currentRoute.startsWith(c.route),
                          ),
                      onTap: () => context.go(item.route),
                    ),
                    for (final child in item.children)
                      _SidebarNavItem(
                        item: child,
                        isCollapsed: collapsed,
                        isChild: true,
                        indent: collapsed ? 0 : 18,
                        isSelected: currentRoute.startsWith(child.route),
                        onTap: () => context.go(child.route),
                      ),
                  ],
                  const SizedBox(height: 10),
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    color: AppColors.sidebarDivider,
                  ),
                  const SizedBox(height: 10),
                  for (final item in secondarySidebarItems)
                    _SidebarNavItem(
                      item: item,
                      isCollapsed: collapsed,
                      isSelected: currentRoute.startsWith(item.route),
                      onTap: () => context.go(item.route),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarNavItem extends StatefulWidget {
  final SidebarItem item;
  final bool isCollapsed;
  final bool isSelected;
  final bool isChild;
  final double indent;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.item,
    required this.isCollapsed,
    required this.isSelected,
    required this.onTap,
    this.isChild = false,
    this.indent = 0,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isSelected = widget.isSelected;
    final isCollapsed = widget.isCollapsed;
    final isChild = widget.isChild;

    final bgColor = isSelected
        ? AppColors.sidebarItemActiveBg
        : _hover
        ? AppColors.sidebarItemHover
        : Colors.transparent;

    final textStyle = textTheme.labelLarge?.copyWith(
      color: Colors.white,
      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
    );

    return MouseRegion(
      onEnter: (_) {
        if (!mounted) return;
        setState(() => _hover = true);
      },
      onExit: (_) {
        if (!mounted) return;
        setState(() => _hover = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 230),
        curve: Curves.easeOut,
        margin: EdgeInsets.only(
          top: 4,
          bottom: 4,
          left: widget.indent,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: widget.onTap,
          child: SizedBox(
            height: isChild ? 40 : 46,
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 230),
                  curve: Curves.easeOut,
                  width: 4,
                  height: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.corporateBlueBright
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  widget.item.icon,
                  size: isChild ? 18 : 22,
                  color: Colors.white
                      .withOpacity(isSelected ? 1 : (isChild ? 0.7 : 0.82)),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 230),
                      curve: Curves.easeOut,
                      style: textStyle ?? const TextStyle(color: Colors.white),
                      child: Text(
                        widget.item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else ...[
                  const Spacer(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
