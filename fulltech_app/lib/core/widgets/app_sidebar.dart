import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import 'layout_provider.dart';
import 'sidebar_items.dart';

class AppSidebar extends ConsumerWidget {
  final String currentRoute;

  const AppSidebar({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collapsed = ref.watch(sidebarCollapsedProvider);
    final textTheme = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      width: collapsed ? 72 : 260,
      decoration: const BoxDecoration(
        gradient: AppColors.sidebarGradient,
      ),
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
                    onPressed: () => ref.read(sidebarCollapsedProvider.notifier).state = !collapsed,
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
                  for (final item in primarySidebarItems)
                    _SidebarNavItem(
                      item: item,
                      isCollapsed: collapsed,
                      isSelected: currentRoute.startsWith(item.route),
                      onTap: () => context.go(item.route),
                    ),
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
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.item,
    required this.isCollapsed,
    required this.isSelected,
    required this.onTap,
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
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 230),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: widget.onTap,
          child: SizedBox(
            height: 46,
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 230),
                  curve: Curves.easeOut,
                  width: 4,
                  height: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.corporateBlueBright : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  widget.item.icon,
                  color: Colors.white.withOpacity(isSelected ? 1 : 0.82),
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
