import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/configuracion/state/display_settings_provider.dart';
import '../../data/models/punch_record.dart';
import '../../providers/punch_provider.dart';

class PunchFiltersBar extends ConsumerStatefulWidget {
  const PunchFiltersBar({super.key});

  @override
  ConsumerState<PunchFiltersBar> createState() => _PunchFiltersBarState();
}

class _PunchFiltersBarState extends ConsumerState<PunchFiltersBar> {
  PunchType? _selectedType;
  DateTimeRange? _selectedDateRange;
  final TextEditingController _searchCtrl = TextEditingController();

  String _getTypeLabel(PunchType type) {
    switch (type) {
      case PunchType.in_:
        return 'Entrada';
      case PunchType.lunchStart:
        return 'Inicio Almuerzo';
      case PunchType.lunchEnd:
        return 'Fin Almuerzo';
      case PunchType.out:
        return 'Salida';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displaySettings = ref.watch(displaySettingsProvider);
    final padX = displaySettings.fullScreen
        ? 0.0
        : (displaySettings.compact ? 8.0 : 12.0);

    return Container(
      padding: EdgeInsets.fromLTRB(16 + padX, 16, 16 + padX, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 13),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 700;
          final typeFilter = SizedBox(
            width: isNarrow ? constraints.maxWidth : 260,
            child: DropdownButtonFormField<PunchType?>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Tipo',
                prefixIcon: Icon(Icons.filter_list),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem<PunchType?>(
                  value: null,
                  child: Text('Todos'),
                ),
                ...PunchType.values.map((type) {
                  return DropdownMenuItem<PunchType?>(
                    value: type,
                    child: Text(_getTypeLabel(type)),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() => _selectedType = value);
                ref
                    .read(punchesControllerProvider.notifier)
                    .setTypeFilter(value);
              },
            ),
          );

          final datePicker = SizedBox(
            width: isNarrow ? constraints.maxWidth : 320,
            child: OutlinedButton.icon(
              onPressed: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  initialDateRange: _selectedDateRange,
                  builder: (context, child) =>
                      Theme(data: Theme.of(context), child: child!),
                );

                if (range != null) {
                  setState(() => _selectedDateRange = range);
                  ref
                      .read(punchesControllerProvider.notifier)
                      .setDateRange(
                        range.start.toIso8601String().split('T')[0],
                        range.end.toIso8601String().split('T')[0],
                      );
                }
              },
              icon: const Icon(Icons.date_range),
              label: Text(
                _selectedDateRange == null
                    ? 'Fecha'
                    : '${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );

          final searchBox = SizedBox(
            width: isNarrow ? constraints.maxWidth : 360,
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                labelText: 'Buscar (entrada/salida)',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) =>
                  ref.read(punchesControllerProvider.notifier).setSearch(v),
            ),
          );

          final clearBtn = IconButton(
            onPressed: () {
              setState(() {
                _selectedType = null;
                _selectedDateRange = null;
                _searchCtrl.text = '';
              });
              ref.read(punchesControllerProvider.notifier).clearFilters();
            },
            icon: const Icon(Icons.clear),
            tooltip: 'Limpiar filtros',
          );

          final filtersWrap = Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [typeFilter, datePicker, clearBtn],
          );

          final searchLine = Row(children: [Expanded(child: searchBox)]);

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [searchLine, const SizedBox(height: 10), filtersWrap],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              searchLine,
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Expanded(child: filtersWrap)],
              ),
            ],
          );
        },
      ),
    );
  }
}
