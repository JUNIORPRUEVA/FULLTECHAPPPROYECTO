import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/module_page.dart';
import '../../models/pos_models.dart';
import '../../state/pos_providers.dart';
import '../widgets/pos_supplier_form_dialog.dart';

class PosSuppliersPage extends ConsumerStatefulWidget {
  const PosSuppliersPage({super.key});

  @override
  ConsumerState<PosSuppliersPage> createState() => _PosSuppliersPageState();
}

class _PosSuppliersPageState extends ConsumerState<PosSuppliersPage> {
  final _search = TextEditingController();

  Future<List<PosSupplier>>? _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _refresh() {
    final repo = ref.read(posRepositoryProvider);
    setState(() {
      _future = repo.listSuppliers(search: _query);
    });
  }

  Future<void> _createSupplier() async {
    final created = await showDialog<PosSupplier>(
      context: context,
      builder: (_) => const PosSupplierFormDialog(),
    );
    if (created != null && mounted) {
      _refresh();
    }
  }

  Future<void> _editSupplier(PosSupplier supplier) async {
    final updated = await showDialog<PosSupplier>(
      context: context,
      builder: (_) => PosSupplierFormDialog(initial: supplier),
    );
    if (updated != null && mounted) {
      _refresh();
    }
  }

  Future<void> _deleteSupplier(PosSupplier supplier) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar proveedor'),
        content: Text('¿Eliminar "${supplier.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );

    if (ok != true) return;

    try {
      final repo = ref.read(posRepositoryProvider);
      await repo.deleteSupplier(supplier.id);
      if (!mounted) return;
      _toast('Proveedor eliminado');
      _refresh();
    } catch (e) {
      _toast('Error eliminando: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModulePage(
      title: 'POS / Proveedores',
      actions: [
        IconButton(
          tooltip: 'Nuevo proveedor',
          onPressed: _createSupplier,
          icon: const Icon(Icons.add_business_outlined),
        ),
      ],
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Buscar proveedor',
                      hintText: 'Nombre, teléfono, RNC, email',
                    ),
                    onSubmitted: (v) {
                      _query = v.trim();
                      _refresh();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    _query = _search.text.trim();
                    _refresh();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Buscar'),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<PosSupplier>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }

                final rows = snap.data ?? const [];
                if (rows.isEmpty) {
                  return const Center(child: Text('No hay proveedores'));
                }

                return ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final s = rows[i];
                    final secondary = [s.phone, s.rnc, s.email]
                        .whereType<String>()
                        .where((e) => e.trim().isNotEmpty)
                        .toList();

                    return ListTile(
                      title: Text(s.name),
                      subtitle: secondary.isEmpty ? null : Text(secondary.join(' · ')),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          IconButton(
                            tooltip: 'Editar',
                            onPressed: () => _editSupplier(s),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: 'Eliminar',
                            onPressed: () => _deleteSupplier(s),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
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
