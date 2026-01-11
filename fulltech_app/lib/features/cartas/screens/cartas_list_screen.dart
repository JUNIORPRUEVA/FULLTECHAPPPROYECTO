import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/module_page.dart';
import '../models/letter_models.dart';
import '../state/cartas_providers.dart';

class CartasListScreen extends ConsumerStatefulWidget {
  final String? presupuestoId;

  const CartasListScreen({super.key, required this.presupuestoId});

  @override
  ConsumerState<CartasListScreen> createState() => _CartasListScreenState();
}

class _CartasListScreenState extends ConsumerState<CartasListScreen> {
  bool _loading = false;
  String? _error;
  List<Letter> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = ref.read(cartasApiProvider);
      final items = await api.listCartas(presupuestoId: widget.presupuestoId);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _confirmDelete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar carta'),
        content: const Text('¿Deseas eliminar esta carta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      final api = ref.read(cartasApiProvider);
      await api.deleteCarta(id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ Carta eliminada')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ No se pudo eliminar: $e')));
    }
  }

  String _fmtDate(DateTime dt) {
    final d = dt;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final presupuestoId = widget.presupuestoId;

    return ModulePage(
      title: 'Cartas',
      actions: [
        IconButton(
          tooltip: 'Refrescar',
          onPressed: _loading ? null : _load,
          icon: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (presupuestoId == null)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text('Mostrando todas las cartas'),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text('Presupuesto: $presupuestoId'),
            ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : (_items.isEmpty)
                ? Center(
                    child: Text(
                      _error ?? 'No hay cartas para este presupuesto',
                    ),
                  )
                : ListView.separated(
                    itemCount: _items.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final it = _items[i];
                      final subtitle =
                          '${it.customerName} • ${it.letterType} • ${it.status} • ${_fmtDate(it.createdAt)}';

                      return ListTile(
                        leading: const Icon(Icons.mail_outline),
                        title: Text(
                          it.subject,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'delete') {
                              _confirmDelete(it.id);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text(
                                    'Eliminar',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        onTap: () => context.go(AppRoutes.cartaDetail(it.id)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
