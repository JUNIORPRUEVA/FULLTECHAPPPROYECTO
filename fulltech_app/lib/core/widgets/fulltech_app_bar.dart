import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class FulltechAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String userName;
  final String? userRole;
  final VoidCallback onOpenProfile;
  final VoidCallback onLogout;

  const FulltechAppBar({
    super.key,
    required this.userName,
    required this.userRole,
    required this.onOpenProfile,
    required this.onLogout,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: AppColors.appBarGradient),
      ),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.25),
      titleSpacing: 12,
      title: Row(
        children: [
          // Logo (placeholder until you add assets).
          // TODO: add real logo asset and use Image.asset with pubspec assets.
          const Icon(Icons.business, color: Colors.white),
          const SizedBox(width: 10),
          Text(
            'FULLTECH CRM & Operaciones',
            style: textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    userName,
                    style: textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (userRole != null)
                    Text(
                      userRole!,
                      style: textTheme.labelSmall?.copyWith(color: Colors.white70),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Cerrar sesión',
                onPressed: onLogout,
                icon: const Icon(Icons.logout, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
