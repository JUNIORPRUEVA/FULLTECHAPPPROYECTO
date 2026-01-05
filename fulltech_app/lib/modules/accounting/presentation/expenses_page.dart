import 'package:flutter/material.dart';

import '../../../core/widgets/module_page.dart';

class ExpensesPage extends StatelessWidget {
  const ExpensesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePage(
      title: 'Expenses (Gastos)',
      child: Card(child: Center(child: Text('Coming soon'))),
    );
  }
}
