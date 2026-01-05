import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BiweeklyCloseKpiCards extends StatelessWidget {
  final double totalIncome;
  final double totalExpenses;
  final double payrollPaid;
  final double netProfit;

  BiweeklyCloseKpiCards({
    super.key,
    required this.totalIncome,
    required this.totalExpenses,
    required this.payrollPaid,
    required this.netProfit,
  });

  final NumberFormat _money = NumberFormat.currency(
    symbol: r'$',
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context) {
    Widget kpi({
      required IconData icon,
      required String label,
      required double value,
    }) {
      return SizedBox(
        width: 260,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        label,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _money.format(value),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        kpi(
          icon: Icons.trending_up_outlined,
          label: 'Total Income (Ingresos)',
          value: totalIncome,
        ),
        kpi(
          icon: Icons.trending_down_outlined,
          label: 'Total Expenses (Salidas)',
          value: totalExpenses,
        ),
        kpi(
          icon: Icons.payments_outlined,
          label: 'Payroll Paid (Pagos Nómina)',
          value: payrollPaid,
        ),
        kpi(
          icon: Icons.calculate_outlined,
          label: 'Net Profit (Ganancia Neta)',
          value: netProfit,
        ),
      ],
    );
  }
}
