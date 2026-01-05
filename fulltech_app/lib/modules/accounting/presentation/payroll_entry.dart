import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/module_page.dart';

/// Simple bridge route from Accounting to the existing Payroll module.
class PayrollEntryPage extends StatefulWidget {
  const PayrollEntryPage({super.key});

  @override
  State<PayrollEntryPage> createState() => _PayrollEntryPageState();
}

class _PayrollEntryPageState extends State<PayrollEntryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go(AppRoutes.nomina);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const ModulePage(
      title: 'Payroll',
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
