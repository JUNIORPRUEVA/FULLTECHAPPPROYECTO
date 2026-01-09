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

class RoleResponsibilitiesScreen extends ConsumerStatefulWidget {
  const RoleResponsibilitiesScreen({super.key});

  @override
  ConsumerState<RoleResponsibilitiesScreen> createState() =>
      _RoleResponsibilitiesScreenState();
}

class _RoleResponsibilitiesScreenState
    extends ConsumerState<RoleResponsibilitiesScreen> {
  final _searchCtrl = TextEditingController();

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
        title: 'Nueva Responsabilidad',
        allowedCategories: [RulesCategory.roleResponsibilities],
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
        allowedCategories: const [RulesCategory.roleResponsibilities],
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
      title: 'Eliminar elemento',
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
    final currentRole = ref.watch(currentUserRoleProvider);

    final effectiveRole = isAdmin ? _roleFilter : currentRole;

    final query = RulesQuery(
      q: _searchCtrl.text,
      category: RulesCategory.roleResponsibilities,
      role: effectiveRole,
      active: isAdmin ? _activeFilter : null,
      limit: 100,
      sort: 'order',
    );

    final asyncPage = ref.watch(rulesListProvider(query));

    return ModulePage(
      title: 'Responsabilidades por Rol',
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
                  if (isAdmin)
                    SizedBox(
                      width: 280,
                      child: DropdownButtonFormField<String?>(
                        initialValue: _roleFilter,
                        decoration: const InputDecoration(
                          labelText: 'Rol',
                          border: OutlineInputBorder(),
                        ),
                        items: <DropdownMenuItem<String?>>[
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Todos los roles'),
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
                        onChanged: (v) => setState(() => _roleFilter = v),
                      ),
                    )
                  else
                    SizedBox(
                      width: 280,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Rol',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          currentRole == null ? '-' : roleLabel(currentRole),
                        ),
                      ),
                    ),
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<bool?>(
                      initialValue: isAdmin ? _activeFilter : null,
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
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _searchCtrl.clear();
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
                    const Text('No se pudieron cargar las responsabilidades'),
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
