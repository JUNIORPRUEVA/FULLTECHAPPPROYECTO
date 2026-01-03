import 'package:flutter/material.dart';

import '../services/app_config.dart';
import '../theme/app_colors.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        gradient: AppColors.appBarGradient,
        border: const Border(top: BorderSide(color: AppColors.sidebarDivider)),
      ),
      child: Text(
        'FULLTECH, SRL – Sistema interno · $year · v${AppConfig.appVersion}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white70,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
