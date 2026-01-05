import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/module_page.dart';
import '../routes/accounting_routes.dart';
import 'widgets/accounting_card.dart';

class AccountingDashboardPage extends StatelessWidget {
  const AccountingDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = <_AccountingCardModel>[
      _AccountingCardModel(
        icon: Icons.payments_outlined,
        title: 'Nómina',
        description: 'Gestiona nómina, salarios, deducciones y pagos',
        onTap: () => context.go(AppRoutes.nomina),
      ),
      _AccountingCardModel(
        icon: Icons.calendar_month_outlined,
        title: 'Cierre Quincena',
        description: 'Cierra el período: ingresos, gastos y ganancia neta',
        onTap: () => context.go(AccountingRoutes.biweeklyClose),
      ),
      _AccountingCardModel(
        icon: Icons.receipt_long_outlined,
        title: 'Gastos',
        description: 'Registra y controla salidas y gastos (próximamente)',
        onTap: () => context.go(AccountingRoutes.expenses),
      ),
      _AccountingCardModel(
        icon: Icons.attach_money_outlined,
        title: 'Ingresos y Cobros',
        description: 'Registra ingresos, cobros y pagos (próximamente)',
        onTap: () => context.go(AccountingRoutes.incomePayments),
      ),
      _AccountingCardModel(
        icon: Icons.bar_chart_outlined,
        title: 'Reportes',
        description: 'Genera reportes contables y exportaciones',
        onTap: () => context.go(AccountingRoutes.reports),
      ),
      _AccountingCardModel(
        icon: Icons.account_tree_outlined,
        title: 'Cuentas y Categorías',
        description: 'Mapa de categorías y cuentas contables (próximamente)',
        onTap: () => context.go(AccountingRoutes.categories),
      ),
    ];

    return ModulePage(
      title: 'Contabilidad',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Acceso rápido a operaciones financieras',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final cols = w >= 1200 ? 4 : (w >= 900 ? 3 : 2);

                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: cols >= 3 ? 2.6 : 2.9,
                  ),
                  itemCount: cards.length,
                  itemBuilder: (context, i) {
                    final item = cards[i];
                    return AccountingCard(
                      icon: item.icon,
                      title: item.title,
                      description: item.description,
                      onTap: item.onTap,
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

class _AccountingCardModel {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _AccountingCardModel({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });
}
