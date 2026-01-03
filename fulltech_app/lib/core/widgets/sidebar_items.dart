import 'package:flutter/material.dart';

import '../routing/app_routes.dart';

class SidebarItem {
  final String label;
  final IconData icon;
  final String route;

  const SidebarItem({
    required this.label,
    required this.icon,
    required this.route,
  });
}

const primarySidebarItems = <SidebarItem>[
  SidebarItem(label: 'CRM', icon: Icons.chat_bubble_outline, route: AppRoutes.crm),
  SidebarItem(label: 'Presupuesto', icon: Icons.request_quote_outlined, route: AppRoutes.presupuesto),
  SidebarItem(label: 'Operaciones / Levantamiento', icon: Icons.assignment_outlined, route: AppRoutes.operaciones),
  SidebarItem(label: 'Garantía', icon: Icons.verified_outlined, route: AppRoutes.garantia),
  SidebarItem(label: 'Nómina', icon: Icons.payments_outlined, route: AppRoutes.nomina),
  SidebarItem(label: 'Ventas', icon: Icons.point_of_sale_outlined, route: AppRoutes.ventas),
  SidebarItem(label: 'Catálogo', icon: Icons.inventory_2_outlined, route: AppRoutes.catalogo),
  SidebarItem(label: 'Técnico', icon: Icons.engineering_outlined, route: AppRoutes.tecnico),
  SidebarItem(label: 'Contrato', icon: Icons.description_outlined, route: AppRoutes.contrato),
  SidebarItem(label: 'Guagua', icon: Icons.directions_car_filled_outlined, route: AppRoutes.guagua),
  SidebarItem(label: 'Contabilidad', icon: Icons.account_balance_outlined, route: AppRoutes.contabilidad),
  SidebarItem(label: 'Mantenimiento', icon: Icons.build_outlined, route: AppRoutes.mantenimiento),
  SidebarItem(label: 'Ponchado', icon: Icons.fingerprint_outlined, route: AppRoutes.ponchado),
  SidebarItem(label: 'RRHH', icon: Icons.groups_outlined, route: AppRoutes.rrhh),
  SidebarItem(label: 'Usuarios', icon: Icons.badge_outlined, route: AppRoutes.usuarios),
];

const secondarySidebarItems = <SidebarItem>[
  SidebarItem(label: 'Perfil', icon: Icons.person_outline, route: AppRoutes.perfil),
  SidebarItem(label: 'Configuración', icon: Icons.settings_outlined, route: AppRoutes.configuracion),
];
