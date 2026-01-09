import 'package:flutter/material.dart';

import '../../../core/widgets/module_page.dart';

class AccountingReportsPage extends StatelessWidget {
  const AccountingReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ModulePage(
      title: 'Reports (Reportes)',
      actions: [
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.download_outlined),
          label: const Text('Export'),
        ),
      ],
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 240,
                    child: DropdownButtonFormField<String>(
                      initialValue: 'summary',
                      items: const [
                        DropdownMenuItem(
                          value: 'summary',
                          child: Text('Summary'),
                        ),
                        DropdownMenuItem(
                          value: 'biweekly',
                          child: Text('Biweekly Close'),
                        ),
                      ],
                      onChanged: (_) {},
                      decoration: const InputDecoration(
                        labelText: 'Report type',
                        prefixIcon: Icon(Icons.bar_chart_outlined),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'From',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      readOnly: true,
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'To',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      readOnly: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Expanded(
                child: Center(child: Text('Report output will appear here.')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
