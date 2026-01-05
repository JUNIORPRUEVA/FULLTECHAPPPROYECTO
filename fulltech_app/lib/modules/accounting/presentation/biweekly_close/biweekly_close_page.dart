import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/module_page.dart';
import '../../data/accounting_repository.dart';
import '../../data/models/biweekly_close_model.dart';
import '../../state/accounting_providers.dart';
import 'widgets/biweekly_close_kpi_cards.dart';
import 'widgets/biweekly_close_table.dart';

class BiweeklyClosePage extends ConsumerWidget {
  const BiweeklyClosePage({super.key});

  String _date(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(biweeklyCloseControllerProvider);
    final ctrl = ref.read(biweeklyCloseControllerProvider.notifier);

    Future<void> pickFrom() async {
      final selected = await showDatePicker(
        context: context,
        initialDate: st.filterFrom ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (selected != null) ctrl.setFilterFrom(selected);
    }

    Future<void> pickTo() async {
      final selected = await showDatePicker(
        context: context,
        initialDate: st.filterTo ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (selected != null) ctrl.setFilterTo(selected);
    }

    return ModulePage(
      title: 'Biweekly Close',
      actions: [
        FilledButton.icon(
          onPressed: () => _openUpsertDialog(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('New Close'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 320,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search (notes or period)',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: ctrl.setSearch,
                ),
              ),
              OutlinedButton.icon(
                onPressed: pickFrom,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  st.filterFrom == null
                      ? 'From'
                      : 'From: ${_date(st.filterFrom!)}',
                ),
              ),
              OutlinedButton.icon(
                onPressed: pickTo,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  st.filterTo == null ? 'To' : 'To: ${_date(st.filterTo!)}',
                ),
              ),
              TextButton(
                onPressed: ctrl.clearFilters,
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          BiweeklyCloseKpiCards(
            totalIncome: st.totalIncome,
            totalExpenses: st.totalExpenses,
            payrollPaid: st.totalPayrollPaid,
            netProfit: st.totalNetProfit,
          ),
          const SizedBox(height: 12),
          if (st.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                st.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                BiweeklyCloseTable(
                  items: st.items,
                  onView: (item) => _openViewDialog(context, item),
                  onEdit: (item) =>
                      _openUpsertDialog(context, ref, existing: item),
                  onDelete: (item) => _confirmDelete(context, ref, item),
                ),
                if (st.loading)
                  const Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openViewDialog(BuildContext context, BiweeklyCloseModel item) {
    final money = NumberFormat.currency(symbol: r'$', decimalDigits: 2);

    return showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Biweekly Close'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Period: ${item.startDate.toIso8601String().split('T').first} → ${item.endDate.toIso8601String().split('T').first}',
                ),
                const SizedBox(height: 8),
                Text('Income: ${money.format(item.income)}'),
                Text('Expenses: ${money.format(item.expenses)}'),
                Text('Payroll Paid: ${money.format(item.payrollPaid)}'),
                const SizedBox(height: 8),
                Text(
                  'Net Profit: ${money.format(item.netProfit)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text('Notes: ${item.notes.isEmpty ? '—' : item.notes}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    BiweeklyCloseModel item,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete close?'),
          content: const Text('This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (ok == true && context.mounted) {
      await ref.read(biweeklyCloseControllerProvider.notifier).delete(item.id);
    }
  }

  Future<void> _openUpsertDialog(
    BuildContext context,
    WidgetRef ref, {
    BiweeklyCloseModel? existing,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) {
        return _BiweeklyCloseUpsertDialog(existing: existing);
      },
    );
  }
}

class _BiweeklyCloseUpsertDialog extends ConsumerStatefulWidget {
  final BiweeklyCloseModel? existing;

  const _BiweeklyCloseUpsertDialog({this.existing});

  @override
  ConsumerState<_BiweeklyCloseUpsertDialog> createState() =>
      _BiweeklyCloseUpsertDialogState();
}

class _BiweeklyCloseUpsertDialogState
    extends ConsumerState<_BiweeklyCloseUpsertDialog> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _startDate;
  late DateTime _endDate;

  late final TextEditingController _startDateCtrl;
  late final TextEditingController _endDateCtrl;

  late final TextEditingController _incomeCtrl;
  late final TextEditingController _expensesCtrl;
  late final TextEditingController _payrollCtrl;
  late final TextEditingController _notesCtrl;

  final NumberFormat _money = NumberFormat.currency(
    symbol: r'$',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    final existing = widget.existing;

    _startDate =
        existing?.startDate ?? DateTime(now.year, now.month, now.day - 14);
    _endDate = existing?.endDate ?? DateTime(now.year, now.month, now.day);

    _startDateCtrl = TextEditingController(text: _date(_startDate));
    _endDateCtrl = TextEditingController(text: _date(_endDate));

    _incomeCtrl = TextEditingController(
      text: existing == null ? '' : existing.income.toStringAsFixed(2),
    );
    _expensesCtrl = TextEditingController(
      text: existing == null ? '' : existing.expenses.toStringAsFixed(2),
    );
    _payrollCtrl = TextEditingController(
      text: existing == null ? '' : existing.payrollPaid.toStringAsFixed(2),
    );
    _notesCtrl = TextEditingController(text: existing?.notes ?? '');

    _incomeCtrl.addListener(_rebuild);
    _expensesCtrl.addListener(_rebuild);
    _payrollCtrl.addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _startDateCtrl.dispose();
    _endDateCtrl.dispose();
    _incomeCtrl.dispose();
    _expensesCtrl.dispose();
    _payrollCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String _date(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  double _parseAmount(String s) {
    final cleaned = s.trim().replaceAll(',', '');
    return double.tryParse(cleaned) ?? 0;
  }

  String? _validateAmount(String? v) {
    final txt = (v ?? '').trim();
    if (txt.isEmpty) return 'Required';
    final parsed = double.tryParse(txt.replaceAll(',', ''));
    if (parsed == null) return 'Invalid number';
    if (parsed < 0) return 'Must be ≥ 0';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final income = _parseAmount(_incomeCtrl.text);
    final expenses = _parseAmount(_expensesCtrl.text);
    final payrollPaid = _parseAmount(_payrollCtrl.text);
    final netProfit = income - (expenses + payrollPaid);

    final isEdit = widget.existing != null;

    Future<void> pickStart() async {
      final selected = await showDatePicker(
        context: context,
        initialDate: _startDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (selected != null) {
        setState(() {
          _startDate = selected;
          _startDateCtrl.text = _date(_startDate);
        });
      }
    }

    Future<void> pickEnd() async {
      final selected = await showDatePicker(
        context: context,
        initialDate: _endDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (selected != null) {
        setState(() {
          _endDate = selected;
          _endDateCtrl.text = _date(_endDate);
        });
      }
    }

    return AlertDialog(
      title: Text(isEdit ? 'Edit Close' : 'New Close'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Period start date',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      controller: _startDateCtrl,
                      onTap: pickStart,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Period end date',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      controller: _endDateCtrl,
                      onTap: pickEnd,
                      validator: (_) {
                        if (!_endDate.isAfter(_startDate)) {
                          return 'End date must be after start';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _incomeCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Total income amount',
                  prefixIcon: Icon(Icons.trending_up_outlined),
                ),
                validator: _validateAmount,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _expensesCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Total expenses amount',
                  prefixIcon: Icon(Icons.trending_down_outlined),
                ),
                validator: _validateAmount,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _payrollCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Payroll paid amount',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                validator: _validateAmount,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  prefixIcon: Icon(Icons.note_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Net Profit preview: ${_money.format(netProfit)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            final ok = _formKey.currentState?.validate() ?? false;
            if (!ok) return;

            final data = BiweeklyCloseUpsertData(
              startDate: _startDate,
              endDate: _endDate,
              income: _parseAmount(_incomeCtrl.text),
              expenses: _parseAmount(_expensesCtrl.text),
              payrollPaid: _parseAmount(_payrollCtrl.text),
              notes: _notesCtrl.text.trim(),
            );

            final ctrl = ref.read(biweeklyCloseControllerProvider.notifier);
            if (widget.existing == null) {
              await ctrl.create(data);
            } else {
              await ctrl.update(widget.existing!.id, data);
            }

            if (mounted) Navigator.of(context).pop();
          },
          child: Text(isEdit ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
