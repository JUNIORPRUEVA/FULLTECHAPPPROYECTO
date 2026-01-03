import 'package:flutter/material.dart';
import 'presentation/pages/users_list_page.dart';

/// Integración del módulo de USUARIOS en el menú lateral
/// Asegúrate de que en tu main.dart o sidebar incluyas esta ruta

class UsuariosMenuItems {
  static const String usuariosRoute = '/usuarios';

  static MenuItem getMenuItem() {
    return MenuItem(
      label: 'Usuarios',
      icon: Icons.people,
      route: usuariosRoute,
      page: const UsersListPage(),
    );
  }
}

class MenuItem {
  final String label;
  final IconData icon;
  final String route;
  final Widget page;

  MenuItem({
    required this.label,
    required this.icon,
    required this.route,
    required this.page,
  });
}
