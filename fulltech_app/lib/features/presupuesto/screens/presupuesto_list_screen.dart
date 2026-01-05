import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/module_page.dart';
import '../models/quotation_models.dart';
import '../state/quotation_builder_controller.dart';

class PresupuestoListScreen extends ConsumerStatefulWidget {
  const PresupuestoListScreen({super.key});

  @override
  ConsumerState<PresupuestoListScreen> createState() =>
      _PresupuestoListScreenState();
}

class _PresupuestoListScreenState extends ConsumerState<PresupuestoListScreen> {
  bool _loading = false;
  String? _error;
  List<QuotationSummary> _items = const [];

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
      final api = ref.read(quotationApiProvider);
      final raw = await api.listQuotations(limit: 20, offset: 0);
      final items = raw.map(QuotationSummary.fromJson).toList();
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModulePage(
      title: 'Presupuesto',
      actions: [
        IconButton(
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh),
          tooltip: 'Actualizar',
        ),
        FilledButton.icon(
          onPressed: () {
            context.go('${AppRoutes.presupuesto}/new');
          },
          icon: const Icon(Icons.add),
          label: const Text('Nueva cotización'),
        ),
      ],
      child: Card(
        child: Column(
          children: [
            if (_loading) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: _items.isEmpty
                  ? const Center(child: Text('Sin cotizaciones aún'))
                  : ListView.separated(
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final q = _items[i];
                        return ListTile(
                          title: Text('${q.numero} • ${q.customerName}'),
                          subtitle: Text(
                            'Total: ${q.total.toStringAsFixed(2)}',
                          ),
                          trailing: Text(
                            '${q.createdAt.day.toString().padLeft(2, '0')}/${q.createdAt.month.toString().padLeft(2, '0')}/${q.createdAt.year}',
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
