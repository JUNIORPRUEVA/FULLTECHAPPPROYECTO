import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/module_page.dart';
import '../../data/models/rules_category.dart';
import '../../data/models/rules_query.dart';
import '../../state/rules_providers.dart';
import '../utils/rules_ui.dart';
import '../widgets/rules_content_card.dart';

class RulesSearchScreen extends ConsumerStatefulWidget {
  const RulesSearchScreen({super.key});

  @override
  ConsumerState<RulesSearchScreen> createState() => _RulesSearchScreenState();
}

class _RulesSearchScreenState extends ConsumerState<RulesSearchScreen> {
  final _searchCtrl = TextEditingController();

  RulesCategory? _category;
  DateTime? _fromDate;
  DateTime? _toDate;

  String? _roleFilter;
  bool? _activeFilter;

  int _page = 1;
  int _limit = 50;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked == null) return;
    setState(() {
      _fromDate = DateTime(picked.year, picked.month, picked.day);
      _page = 1;
    });
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked == null) return;
    setState(() {
      _toDate = DateTime(picked.year, picked.month, picked.day);
      _page = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(rulesIsAdminProvider);

    final query = RulesQuery(
      q: _searchCtrl.text,
      category: _category,
      fromDate: _fromDate,
      toDate: _toDate,
      role: isAdmin ? _roleFilter : null,
      active: isAdmin ? _activeFilter : null,
      page: _page,
      limit: _limit,
      sort: 'order',
    );

    final asyncPage = ref.watch(rulesListProvider(query));

    return ModulePage(
      title: 'Búsqueda de Reglas',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 360,
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Buscar',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() => _page = 1),
                    ),
                  ),
                  SizedBox(
                    width: 260,
                    child: DropdownButtonFormField<RulesCategory?>(
                      initialValue: _category,
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Todas')),
                        ...RulesCategory.values.map(
                          (c) =>
                              DropdownMenuItem(value: c, child: Text(c.label)),
                        ),
                      ],
                      onChanged: (v) => setState(() {
                        _category = v;
                        _page = 1;
                      }),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _pickFromDate,
                    icon: const Icon(Icons.event),
                    label: Text(
                      _fromDate == null
                          ? 'Desde fecha'
                          : 'Desde: ${formatShortDate(_fromDate!)}',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _pickToDate,
                    icon: const Icon(Icons.event),
                    label: Text(
                      _toDate == null
                          ? 'Hasta fecha'
                          : 'Hasta: ${formatShortDate(_toDate!)}',
                    ),
                  ),
                  if (isAdmin)
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<bool?>(
                        initialValue: _activeFilter,
                        decoration: const InputDecoration(
                          labelText: 'Activo',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Todas')),
                          DropdownMenuItem(value: true, child: Text('Activas')),
                          DropdownMenuItem(
                            value: false,
                            child: Text('Inactivas'),
                          ),
                        ],
                        onChanged: (v) => setState(() {
                          _activeFilter = v;
                          _page = 1;
                        }),
                      ),
                    ),
                  if (isAdmin)
                    SizedBox(
                      width: 280,
                      child: DropdownButtonFormField<String?>(
                        initialValue: _roleFilter,
                        decoration: const InputDecoration(
                          labelText: 'Visibilidad por rol',
                          border: OutlineInputBorder(),
                        ),
                        items: <DropdownMenuItem<String?>>[
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Todos'),
                          ),
                          const DropdownMenuItem(
                            value: 'ALL',
                            child: Text('Visible para todos'),
                          ),
                          ...knownAppRoles.map(
                            (r) => DropdownMenuItem(
                              value: r,
                              child: Text(roleLabel(r)),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() {
                          _roleFilter = v;
                          _page = 1;
                        }),
                      ),
                    ),
                  SizedBox(
                    width: 140,
                    child: DropdownButtonFormField<int>(
                      initialValue: _limit,
                      decoration: const InputDecoration(
                        labelText: 'Tamaño de página',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 25, child: Text('25')),
                        DropdownMenuItem(value: 50, child: Text('50')),
                        DropdownMenuItem(value: 100, child: Text('100')),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          _limit = v;
                          _page = 1;
                        });
                      },
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _searchCtrl.clear();
                        _category = null;
                        _fromDate = null;
                        _toDate = null;
                        _roleFilter = null;
                        _activeFilter = null;
                        _page = 1;
                        _limit = 50;
                      });
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Restablecer'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: asyncPage.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No se pudo buscar'),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => bumpRulesRefresh(ref),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
              data: (page) {
                final totalPages = (page.total / page.pageSize).ceil().clamp(
                  1,
                  1 << 30,
                );

                return Column(
                  children: [
                    Row(
                      children: [
                        Text('Total: ${page.total}'),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Página anterior',
                          onPressed: _page > 1
                              ? () => setState(() => _page--)
                              : null,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Text('Página ${page.page} / $totalPages'),
                        IconButton(
                          tooltip: 'Página siguiente',
                          onPressed: page.page < totalPages
                              ? () => setState(() => _page++)
                              : null,
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: page.items.isEmpty
                          ? const Center(child: Text('Sin resultados'))
                          : ListView.separated(
                              itemCount: page.items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, i) {
                                final item = page.items[i];
                                return RulesContentCard(
                                  item: item,
                                  showAdminControls: false,
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
