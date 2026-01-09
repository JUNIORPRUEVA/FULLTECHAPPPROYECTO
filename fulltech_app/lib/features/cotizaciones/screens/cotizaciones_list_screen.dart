import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fulltech_app/core/widgets/module_page.dart';
import 'package:fulltech_app/features/auth/state/auth_providers.dart';
import 'package:fulltech_app/features/cotizaciones/state/cotizaciones_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class CotizacionesListScreen extends ConsumerStatefulWidget {
  const CotizacionesListScreen({super.key});

  @override
  ConsumerState<CotizacionesListScreen> createState() => _CotizacionesListScreenState();
}

class _CotizacionesListScreenState extends ConsumerState<CotizacionesListScreen> {
  final _qCtrl = TextEditingController();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final session = await ref.read(localDbProvider).readSession();
    if (session == null) {
      setState(() {
        _loading = false;
        _error = 'Sesión no encontrada. Inicia sesión de nuevo.';
      });
      return;
    }
    final empresaId = session.user.empresaId;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = ref.read(quotationRepositoryProvider);

      // 1) Show local immediately
      final local = await repo.listLocal(
        empresaId: empresaId,
        q: _qCtrl.text,
        limit: 50,
        offset: 0,
      );
      setState(() => _items = local);

      // 2) Best-effort refresh from server
      await repo.refreshFromServer(
        empresaId: empresaId,
        q: _qCtrl.text,
        limit: 50,
        offset: 0,
      );

      final refreshed = await repo.listLocal(
        empresaId: empresaId,
        q: _qCtrl.text,
        limit: 50,
        offset: 0,
      );

      setState(() {
        _items = refreshed;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cotización'),
        content: const Text('¿Deseas eliminar esta cotización?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar')),
        ],
      ),
    );

    if (ok != true) return;

    final repo = ref.read(quotationRepositoryProvider);
    await repo.deleteRemoteAndLocal(id);
    await _load();
  }

  Future<void> _send(BuildContext context, String id) async {
    final toCtrl = TextEditingController();
    String channel = 'whatsapp';

    final res = await showDialog<Map<String, dynamic>?> (
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Enviar'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: channel,
                items: const [
                  DropdownMenuItem(value: 'whatsapp', child: Text('WhatsApp')),
                  DropdownMenuItem(value: 'email', child: Text('Email')),
                ],
                onChanged: (v) => setState(() => channel = v ?? 'whatsapp'),
                decoration: const InputDecoration(labelText: 'Canal'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: toCtrl,
                decoration: InputDecoration(
                  labelText: channel == 'whatsapp' ? 'Teléfono' : 'Correo',
                  hintText: channel == 'whatsapp' ? '521XXXXXXXXXX' : 'cliente@correo.com',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.of(context).pop({'channel': channel, 'to': toCtrl.text.trim()}), child: const Text('Continuar')),
          ],
        ),
      ),
    );

    if (res == null) return;

    final repo = ref.read(quotationRepositoryProvider);
    final resp = await repo.sendRemote(
      id,
      channel: res['channel'] as String,
      to: (res['to'] as String).isEmpty ? null : (res['to'] as String),
    );

    final url = resp['url']?.toString();
    if (url == null || url.isEmpty) return;

    final uri = Uri.tryParse(url);
    if (uri == null) return;

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return ModulePage(
      title: 'Cotizaciones',
      actions: [
        IconButton(
          tooltip: 'Actualizar',
          onPressed: _load,
          icon: const Icon(Icons.refresh),
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
                    controller: _qCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Buscar…',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _load(),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _load,
                  child: const Text('Buscar'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _items.isEmpty
                        ? const Center(child: Text('Sin cotizaciones'))
                        : ListView.separated(
                            itemCount: _items.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final it = _items[index];
                              final id = it['id']?.toString() ?? '';

                              return ListTile(
                                title: Text(it['numero']?.toString() ?? ''),
                                subtitle: Text(
                                  '${it['customer_name'] ?? ''} • ${it['status'] ?? ''}',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Enviar',
                                      onPressed: id.isEmpty ? null : () => _send(context, id),
                                      icon: const Icon(Icons.send),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (value) async {
                                        if (value == 'ver') {
                                          context.go('/cotizaciones/$id');
                                        } else if (value == 'duplicar') {
                                          final session = await ref
                                              .read(localDbProvider)
                                              .readSession();
                                          if (session == null) return;
                                          await ref.read(quotationRepositoryProvider).duplicateRemoteToLocal(
                                                id,
                                                empresaId: session.user.empresaId,
                                              );
                                          await _load();
                                        } else if (value == 'eliminar') {
                                          await _confirmDelete(context, id);
                                        }
                                      },
                                      itemBuilder: (context) => const [
                                        PopupMenuItem(value: 'ver', child: Text('Ver')),
                                        PopupMenuItem(value: 'duplicar', child: Text('Duplicar')),
                                        PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                                      ],
                                    ),
                                  ],
                                ),
                                onTap: id.isEmpty ? null : () => context.go('/cotizaciones/$id'),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
