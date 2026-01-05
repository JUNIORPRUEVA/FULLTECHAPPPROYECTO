import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/layout_provider.dart';
import '../../../../features/configuracion/state/display_settings_provider.dart';
import '../../data/models/punch_record.dart';
import '../../providers/punch_provider.dart';

class PunchAppBarFilters extends ConsumerStatefulWidget
    implements PreferredSizeWidget {
  final double height;
  final VoidCallback onPunch;
  final bool isPunching;

  const PunchAppBarFilters({
    super.key,
    this.height = 120,
    required this.onPunch,
    this.isPunching = false,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  ConsumerState<PunchAppBarFilters> createState() => _PunchAppBarFiltersState();
}

class _PunchAppBarFiltersState extends ConsumerState<PunchAppBarFilters> {
  PunchType? _selectedType;
  DateTimeRange? _selectedDateRange;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final isMobile = MediaQuery.of(context).size.width < 900;
    final displaySettings = ref.watch(displaySettingsProvider);
    final padX = displaySettings.fullScreen
        ? 0.0
        : (displaySettings.compact ? 8.0 : 12.0);
    final sidebarCollapsed = ref.watch(sidebarCollapsedProvider);
    final sidebarWidth = sidebarCollapsed ? 72.0 : 260.0;
    final leftInset = isMobile ? padX : (sidebarWidth + padX);

    return Material(
      color: colorScheme.surface,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 102),
            ),
          ),
        ),
        padding: EdgeInsets.fromLTRB(leftInset, 10, padX, 10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 900;

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
              tooltip: 'Limpiar filtros',
              onPressed: () {
                setState(() {
                  _selectedType = null;
                  _selectedDateRange = null;
                  _searchCtrl.text = '';
                });
                ref.read(punchesControllerProvider.notifier).clearFilters();
              },
              icon: const Icon(Icons.clear),
            );

            final filterBtn = OutlinedButton.icon(
              onPressed: () {
                ref
                    .read(punchesControllerProvider.notifier)
                    .loadPunches(reset: true);
              },
              icon: const Icon(Icons.tune),
              label: const Text('Filtrar'),
            );

            final punchBtn = FilledButton.icon(
              onPressed: widget.isPunching ? null : widget.onPunch,
              icon: widget.isPunching
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.fingerprint),
              label: Text(widget.isPunching ? 'Ponchando…' : 'Ponchar'),
            );

            // Search in first line, filters in second line (professional layout)
            final filtersWrap = Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                typeFilter,
                datePicker,
                filterBtn,
                clearBtn,
              ],
            );

            final searchLine = Row(
              children: [
                Expanded(child: searchBox),
              ],
            );

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  searchLine,
                  const SizedBox(height: 10),
                  filtersWrap,
                  const SizedBox(height: 10),
                  SizedBox(height: 44, child: punchBtn),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                searchLine,
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: filtersWrap),
                    const SizedBox(width: 12),
                    SizedBox(height: 44, child: punchBtn),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

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
}
