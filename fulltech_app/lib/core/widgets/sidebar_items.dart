import 'package:flutter/material.dart';

import '../routing/app_routes.dart';

class SidebarItem {
  final String label;
  final IconData icon;
  final String route;
  final List<SidebarItem> children;

  const SidebarItem({
    required this.label,
    required this.icon,
    required this.route,
    this.children = const [],
  });
}

// Primary (main modules)
const primarySidebarItems = <SidebarItem>[
  SidebarItem(
    label: 'CRM',
    icon: Icons.chat_bubble_outline,
    route: AppRoutes.crm,
  ),
  SidebarItem(
    label: 'Catálogo',
    icon: Icons.inventory_2_outlined,
    route: AppRoutes.catalogo,
  ),
  SidebarItem(
    label: 'Presupuesto',
    icon: Icons.calculate_outlined,
    route: AppRoutes.presupuesto,
  ),
  SidebarItem(
    label: 'Operaciones',
    icon: Icons.assignment_outlined,
    route: AppRoutes.operaciones,
  ),
  SidebarItem(
    label: 'Contabilidad',
    icon: Icons.account_balance_outlined,
    route: AppRoutes.contabilidad,
  ),
  SidebarItem(
    label: 'Ponchado',
    icon: Icons.schedule_outlined,
    route: AppRoutes.ponchado,
  ),
  SidebarItem(
    label: 'Ventas',
    icon: Icons.point_of_sale_outlined,
    route: AppRoutes.ventas,
  ),
  SidebarItem(
    label: 'Mantenimiento',
    icon: Icons.build_outlined,
    route: AppRoutes.mantenimiento,
  ),
  SidebarItem(
    label: 'Usuarios',
    icon: Icons.manage_accounts_outlined,
    route: AppRoutes.usuarios,
  ),
  SidebarItem(
    label: 'Rules',
    icon: Icons.rule_outlined,
    route: AppRoutes.rules,
  ),
];

// Secondary (utilities & settings)
const secondarySidebarItems = <SidebarItem>[
  SidebarItem(
    label: 'Configuración',
    icon: Icons.settings_outlined,
    route: AppRoutes.configuracion,
  ),
  SidebarItem(label: 'Perfil', icon: Icons.person_outline, route: AppRoutes.perfil),
];
