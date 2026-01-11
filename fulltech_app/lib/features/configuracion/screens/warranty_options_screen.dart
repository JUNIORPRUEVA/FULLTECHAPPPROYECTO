import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/module_page.dart';
import '../state/warranty_options_provider.dart';

class WarrantyOptionsScreen extends ConsumerWidget {
  const WarrantyOptionsScreen({super.key});

  Future<void> _upsert(
    BuildContext context,
    WidgetRef ref, {
    WarrantyOption? current,
  }) async {
    final ctrl = TextEditingController(text: current?.name ?? '');
    final next = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(current == null ? 'Nueva garantía' : 'Editar garantía'),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              hintText: 'Ej: 30 días, 3 meses, 1 año',
              isDense: true,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(ctrl.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    final name = (next ?? '').trim();
    if (name.isEmpty) return;

    final notifier = ref.read(warrantyOptionsProvider.notifier);
    if (current == null) {
      await notifier.addOption(name);
    } else {
      await notifier.renameOption(id: current.id, name: name);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(warrantyOptionsProvider);

    return ModulePage(
      title: 'Garantías (TPV)',
      actions: [
        IconButton(
          tooltip: 'Agregar',
          onPressed: () => _upsert(context, ref),
          icon: const Icon(Icons.add),
        ),
      ],
      child: Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Lista para seleccionar garantía en el TPV.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: items.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay garantías configuradas. Pulsa + para agregar.',
                        ),
                      )
                    : ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final it = items[i];
                          return ListTile(
                            title: Text(it.name),
                            leading: const Icon(Icons.verified_outlined),
                            onTap: () => _upsert(context, ref, current: it),
                            trailing: IconButton(
                              tooltip: 'Eliminar',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Eliminar garantía'),
                                    content: Text(
                                      '¿Deseas eliminar "${it.name}"?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text('Cancelar'),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: const Text('Eliminar'),
                                      ),
                                    ],
                                  ),
                                );
                                if (ok != true) return;
                                await ref
                                    .read(warrantyOptionsProvider.notifier)
                                    .removeOption(it.id);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
