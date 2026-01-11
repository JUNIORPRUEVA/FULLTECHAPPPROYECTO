import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import 'package:fulltech_app/core/widgets/module_page.dart';
import 'package:fulltech_app/features/cotizaciones/state/cotizaciones_providers.dart';

class CotizacionDetailScreen extends ConsumerStatefulWidget {
  const CotizacionDetailScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<CotizacionDetailScreen> createState() =>
      _CotizacionDetailScreenState();
}

class _CotizacionDetailScreenState
    extends ConsumerState<CotizacionDetailScreen> {
  Map<String, dynamic>? _header;
  List<Map<String, dynamic>> _items = const [];
  bool _loading = true;
  String? _error;

  String _friendlyError(Object e, {required String fallback}) {
    if (kDebugMode) {
      debugPrint('[CotizacionDetail] $fallback: $e');
    }
    return fallback;
  }

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
      final repo = ref.read(quotationRepositoryProvider);
      final header = await repo.getLocal(widget.id);
      final items = await repo.listLocalItems(widget.id);
      setState(() {
        _header = header;
        _items = items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = _friendlyError(
          e,
          fallback: 'No se pudo cargar la cotización.',
        );
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = _header;

    return ModulePage(
      title: 'Cotización',
      actions: [
        IconButton(
          tooltip: 'Actualizar',
          onPressed: _load,
          icon: const Icon(Icons.refresh),
        ),
      ],
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : h == null
          ? const Center(child: Text('No encontrada'))
          : ListView(
              children: [
                ListTile(
                  title: Text(h['numero']?.toString() ?? ''),
                  subtitle: Text('Estado: ${h['status'] ?? ''}'),
                ),
                if ((h['customer_name'] ?? '').toString().isNotEmpty)
                  ListTile(
                    title: const Text('Cliente'),
                    subtitle: Text(h['customer_name']?.toString() ?? ''),
                  ),
                ListTile(
                  title: const Text('Total'),
                  subtitle: Text('${h['total'] ?? ''}'),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Conceptos',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                for (final it in _items)
                  ListTile(
                    title: Text(it['nombre']?.toString() ?? ''),
                    subtitle: Text(
                      '${it['cantidad'] ?? ''} x ${it['unit_price'] ?? ''}',
                    ),
                    trailing: Text(it['line_total']?.toString() ?? ''),
                  ),
              ],
            ),
    );
  }
}
