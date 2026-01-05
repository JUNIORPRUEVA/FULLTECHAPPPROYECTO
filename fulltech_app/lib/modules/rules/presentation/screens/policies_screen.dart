import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/module_page.dart';
import '../../data/models/rules_category.dart';
import '../../data/models/rules_content.dart';
import '../../data/models/rules_query.dart';
import '../../state/rules_providers.dart';
import '../utils/rules_ui.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/rule_editor_dialog.dart';
import '../widgets/rules_content_card.dart';

class PoliciesScreen extends ConsumerStatefulWidget {
  const PoliciesScreen({super.key});

  @override
  ConsumerState<PoliciesScreen> createState() => _PoliciesScreenState();
}

class _PoliciesScreenState extends ConsumerState<PoliciesScreen> {
  final _searchCtrl = TextEditingController();

  RulesCategory? _category = RulesCategory.policy;
  String? _roleFilter;
  bool? _activeFilter;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final draft = await showDialog<RulesContent>(
      context: context,
      builder: (_) => const RuleEditorDialog(
        title: 'Nueva Política / Norma',
        allowedCategories: [RulesCategory.policy, RulesCategory.general],
      ),
    );

    if (draft == null) return;

    try {
      await ref.read(rulesRepositoryProvider).create(draft);
      bumpRulesRefresh(ref);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No se pudo crear')));
    }
  }

  Future<void> _edit(RulesContent item) async {
    final edited = await showDialog<RulesContent>(
      context: context,
      builder: (_) => RuleEditorDialog(
        title: 'Editar',
        initial: item,
        allowedCategories: const [RulesCategory.policy, RulesCategory.general],
      ),
    );

    if (edited == null) return;

    try {
      await ref
          .read(rulesRepositoryProvider)
          .update(item.id, edited.toUpsertJson());
      bumpRulesRefresh(ref);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No se pudo actualizar')));
    }
  }

  Future<void> _delete(RulesContent item) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Eliminar política',
      message: 'Esta acción no se puede deshacer.',
      confirmText: 'Eliminar',
    );
    if (!ok) return;

    try {
      await ref.read(rulesRepositoryProvider).delete(item.id);
      bumpRulesRefresh(ref);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No se pudo eliminar')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(rulesIsAdminProvider);

    final query = RulesQuery(
      q: _searchCtrl.text,
      category: _category,
      role: isAdmin ? _roleFilter : null,
      active: isAdmin ? _activeFilter : null,
      limit: 100,
      sort: 'order',
    );

    final asyncPage = ref.watch(rulesListProvider(query));

    return ModulePage(
      title: 'Políticas / Normas de la Empresa',
      actions: [
        if (isAdmin)
          FilledButton.icon(
            onPressed: _create,
            icon: const Icon(Icons.add),
            label: const Text('Nuevo'),
          ),
      ],
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
                    width: 320,
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Buscar',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    child: DropdownButtonFormField<RulesCategory?>(
                      value: _category,
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Todas')),
                        DropdownMenuItem(
                          value: RulesCategory.policy,
                          child: Text('Política / Norma'),
                        ),
                        DropdownMenuItem(
                          value: RulesCategory.general,
                          child: Text('General'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _category = v),
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<bool?>(
                      value: isAdmin ? _activeFilter : null,
                      decoration: const InputDecoration(
                        labelText: 'Activo',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Todas')),
                        DropdownMenuItem(value: true, child: Text('Activas')),
                        DropdownMenuItem(value: false, child: Text('Inactivas')),
                      ],
                      onChanged: isAdmin
                          ? (v) => setState(() => _activeFilter = v)
                          : null,
                    ),
                  ),
                  SizedBox(
                    width: 260,
                    child: DropdownButtonFormField<String?>(
                      value: isAdmin ? _roleFilter : null,
                      decoration: const InputDecoration(
                        labelText: 'Visibilidad por rol',
                        border: OutlineInputBorder(),
                      ),
                      items: <DropdownMenuItem<String?>>[
                        const DropdownMenuItem(value: null, child: Text('Todos')),
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
                      onChanged: isAdmin
                          ? (v) => setState(() => _roleFilter = v)
                          : null,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _searchCtrl.clear();
                        _category = RulesCategory.policy;
                        _roleFilter = null;
                        _activeFilter = null;
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
                    const Text('No se pudieron cargar las políticas'),
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
                if (page.items.isEmpty) {
                  return const Center(child: Text('Aún no hay elementos'));
                }

                return ListView.separated(
                  itemCount: page.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final item = page.items[i];
                    return RulesContentCard(
                      item: item,
                      showAdminControls: isAdmin,
                      onEdit: isAdmin ? () => _edit(item) : null,
                      onDelete: isAdmin ? () => _delete(item) : null,
                      onToggleActive: isAdmin
                          ? (_) async {
                              try {
                                await ref
                                    .read(rulesRepositoryProvider)
                                    .toggleActive(item.id);
                                bumpRulesRefresh(ref);
                              } catch (_) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No se pudo cambiar el estado'),
                                  ),
                                );
                              }
                            }
                          : null,
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
