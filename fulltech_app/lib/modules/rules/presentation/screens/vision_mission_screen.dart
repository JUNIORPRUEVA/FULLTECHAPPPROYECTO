import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/module_page.dart';
import '../../data/models/rules_category.dart';
import '../../data/models/rules_content.dart';
import '../../data/models/rules_query.dart';
import '../../state/rules_providers.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/rule_editor_dialog.dart';
import '../widgets/rules_content_card.dart';

class VisionMissionScreen extends ConsumerStatefulWidget {
  const VisionMissionScreen({super.key});

  @override
  ConsumerState<VisionMissionScreen> createState() =>
      _VisionMissionScreenState();
}

class _VisionMissionScreenState extends ConsumerState<VisionMissionScreen> {
  Future<void> _createItem(RulesCategory category) async {
    final draft = await showDialog<RulesContent>(
      context: context,
      builder: (_) => RuleEditorDialog(
        title: 'Nuevo ${category.label}',
        lockedCategory: category,
        allowedCategories: const [
          RulesCategory.vision,
          RulesCategory.mission,
          RulesCategory.coreValues,
        ],
      ),
    );

    if (draft == null) return;

    try {
      await ref.read(rulesRepositoryProvider).create(draft);
      bumpRulesRefresh(ref);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo crear el elemento')),
      );
    }
  }

  Future<void> _editItem(RulesContent item) async {
    final edited = await showDialog<RulesContent>(
      context: context,
      builder: (_) => RuleEditorDialog(
        title: 'Editar ${item.category.label}',
        initial: item,
        lockedCategory: item.category,
        allowedCategories: const [
          RulesCategory.vision,
          RulesCategory.mission,
          RulesCategory.coreValues,
        ],
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar el elemento')),
      );
    }
  }

  Future<void> _deleteItem(RulesContent item) async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar el elemento')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(rulesIsAdminProvider);

    return DefaultTabController(
      length: 3,
      child: Builder(
        builder: (context) {
          final controller = DefaultTabController.of(context);

          return ModulePage(
            title: 'Visión, Misión y Valores',
            appBarBottom: const TabBar(
              tabs: [
                Tab(text: 'Visión'),
                Tab(text: 'Misión'),
                Tab(text: 'Valores'),
              ],
            ),
            actions: [
              if (isAdmin)
                FilledButton.icon(
                  onPressed: () {
                    final idx = controller.index;
                    final category = switch (idx) {
                      0 => RulesCategory.vision,
                      1 => RulesCategory.mission,
                      _ => RulesCategory.coreValues,
                    };
                    _createItem(category);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                ),
            ],
            child: TabBarView(
              children: [
                _CategoryListTab(
                  category: RulesCategory.vision,
                  isAdmin: isAdmin,
                  onEdit: _editItem,
                  onDelete: _deleteItem,
                ),
                _CategoryListTab(
                  category: RulesCategory.mission,
                  isAdmin: isAdmin,
                  onEdit: _editItem,
                  onDelete: _deleteItem,
                ),
                _CategoryListTab(
                  category: RulesCategory.coreValues,
                  isAdmin: isAdmin,
                  onEdit: _editItem,
                  onDelete: _deleteItem,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CategoryListTab extends ConsumerWidget {
  final RulesCategory category;
  final bool isAdmin;
  final ValueChanged<RulesContent> onEdit;
  final ValueChanged<RulesContent> onDelete;

  const _CategoryListTab({
    required this.category,
    required this.isAdmin,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = RulesQuery(category: category, limit: 200, sort: 'order');
    final asyncPage = ref.watch(rulesListProvider(query));

    return asyncPage.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No se pudieron cargar los elementos'),
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
              onEdit: isAdmin ? () => onEdit(item) : null,
              onDelete: isAdmin ? () => onDelete(item) : null,
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
    );
  }
}
