import 'package:flutter/material.dart';

String formatShortDate(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Roles aligned with backend `UserRole` (prisma + JWT).
const knownAppRoles = <String>[
  'admin',
  'administrador',
  'vendedor',
  'tecnico',
  'tecnico_fijo',
  'contratista',
  'asistente_administrativo',
];

String roleLabel(String role) {
  switch (role) {
    case 'admin':
      return 'Admin';
    case 'administrador':
      return 'Administración';
    case 'vendedor':
      return 'Ventas';
    case 'tecnico':
      return 'Técnico';
    case 'tecnico_fijo':
      return 'Técnico (Fijo)';
    case 'contratista':
      return 'Contratista';
    case 'asistente_administrativo':
      return 'Asistente Administrativo';
    default:
      return role.replaceAll('_', ' ');
  }
}

Widget categoryChip(BuildContext context, String label) {
  return Chip(
    label: Text(label),
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: VisualDensity.compact,
  );
}
