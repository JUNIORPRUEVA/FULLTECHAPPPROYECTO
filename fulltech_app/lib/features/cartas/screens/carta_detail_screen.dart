import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/module_page.dart';
import '../models/letter_models.dart';
import '../state/cartas_providers.dart';

class CartaDetailScreen extends ConsumerStatefulWidget {
  final String cartaId;

  const CartaDetailScreen({super.key, required this.cartaId});

  @override
  ConsumerState<CartaDetailScreen> createState() => _CartaDetailScreenState();
}

class _CartaDetailScreenState extends ConsumerState<CartaDetailScreen> {
  bool _loading = false;
  String? _error;
  Letter? _carta;

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
      final res = await api.getCarta(widget.cartaId);
      if (!mounted) return;
      setState(() {
        _carta = res.item;
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

  String _fmtDate(DateTime dt) {
    final d = dt;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Color _statusColor(String status, ColorScheme cs) {
    switch (status.toUpperCase()) {
      case 'SENT':
        return cs.primaryContainer;
      case 'DRAFT':
      default:
        return cs.surfaceContainerHighest;
    }
  }

  Future<void> _delete() async {
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
      await api.deleteCarta(widget.cartaId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ Carta eliminada')));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ No se pudo eliminar: $e')));
    }
  }

  Future<void> _sendWhatsApp() async {
    final carta = _carta;
    if (carta == null) return;

    final ctrl = TextEditingController(text: carta.customerPhone ?? '');
    final phone = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enviar por WhatsApp'),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: ctrl,
            decoration: const InputDecoration(
              labelText: 'Teléfono (con código país si aplica)',
              hintText: 'Ej: 18095551234',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(ctrl.text),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (phone == null) return;

    try {
      final api = ref.read(cartasApiProvider);
      await api.sendWhatsApp(widget.cartaId, toPhone: phone);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Carta enviada por WhatsApp')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ No se pudo enviar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_loading) {
      return const ModulePage(
        title: 'Carta',
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_carta == null) {
      return ModulePage(
        title: 'Carta',
        actions: [
          IconButton(
            tooltip: 'Refrescar',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
        child: Center(child: Text(_error ?? 'Carta no encontrada')),
      );
    }

    final carta = _carta!;

    return ModulePage(
      title: 'Carta',
      actions: [
        IconButton(
          tooltip: 'Ver PDF',
          onPressed: () => context.go(AppRoutes.cartaPdf(widget.cartaId)),
          icon: const Icon(Icons.picture_as_pdf_outlined),
        ),
        IconButton(
          tooltip: 'Enviar WhatsApp',
          onPressed: _sendWhatsApp,
          icon: const Icon(Icons.send_outlined),
        ),
        PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'delete') _delete();
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Chip(
                          label: Text(carta.status),
                          backgroundColor: _statusColor(carta.status, cs),
                        ),
                        const Spacer(),
                        Text(
                          _fmtDate(carta.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      carta.subject,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Cliente',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(carta.customerName),
                    if ((carta.customerPhone ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        carta.customerPhone!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text('Tipo', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(carta.letterType),
                    if ((carta.quotationId ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Row(
                        children: [
                          Icon(Icons.attach_file, size: 16),
                          SizedBox(width: 4),
                          Text('Incluye cotización'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contenido',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    SelectableText(carta.body),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
