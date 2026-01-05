import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/biweekly_close_model.dart';

class BiweeklyCloseTable extends StatelessWidget {
  final List<BiweeklyCloseModel> items;
  final void Function(BiweeklyCloseModel item) onView;
  final void Function(BiweeklyCloseModel item) onEdit;
  final void Function(BiweeklyCloseModel item) onDelete;

  BiweeklyCloseTable({
    super.key,
    required this.items,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final NumberFormat _money = NumberFormat.currency(
    symbol: r'$',
    decimalDigits: 2,
  );

  String _date(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Card(
        child: Center(child: Text('No closes yet. Create your first close.')),
      );
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Period')),
              DataColumn(label: Text('Income')),
              DataColumn(label: Text('Expenses')),
              DataColumn(label: Text('Payroll Paid')),
              DataColumn(label: Text('Net Profit')),
              DataColumn(label: Text('Notes')),
              DataColumn(label: Text('Created At')),
              DataColumn(label: Text('Actions')),
            ],
            rows: [
              for (final r in items)
                DataRow(
                  cells: [
                    DataCell(
                      Text('${_date(r.startDate)} → ${_date(r.endDate)}'),
                    ),
                    DataCell(Text(_money.format(r.income))),
                    DataCell(Text(_money.format(r.expenses))),
                    DataCell(Text(_money.format(r.payrollPaid))),
                    DataCell(Text(_money.format(r.netProfit))),
                    DataCell(
                      SizedBox(
                        width: 220,
                        child: Text(
                          r.notes.isEmpty ? '—' : r.notes,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(Text(_date(r.createdAt))),
                    DataCell(
                      Wrap(
                        spacing: 6,
                        children: [
                          IconButton(
                            tooltip: 'View',
                            onPressed: () => onView(r),
                            icon: const Icon(Icons.visibility_outlined),
                          ),
                          IconButton(
                            tooltip: 'Edit',
                            onPressed: () => onEdit(r),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            onPressed: () => onDelete(r),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
