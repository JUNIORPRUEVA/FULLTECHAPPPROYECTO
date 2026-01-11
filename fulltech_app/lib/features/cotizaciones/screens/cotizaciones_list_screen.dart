import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fulltech_app/core/routing/app_routes.dart';
import 'package:fulltech_app/core/widgets/module_page.dart';
import 'package:fulltech_app/features/auth/state/auth_providers.dart';
import 'package:fulltech_app/features/cotizaciones/state/cotizaciones_providers.dart';
import 'package:fulltech_app/modules/pos/models/pos_models.dart';
import 'package:fulltech_app/modules/pos/models/pos_ticket.dart';
import 'package:fulltech_app/modules/pos/state/pos_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class CotizacionesListScreen extends ConsumerStatefulWidget {
  const CotizacionesListScreen({super.key});

  @override
  ConsumerState<CotizacionesListScreen> createState() =>
      _CotizacionesListScreenState();
}

class _CotizacionesListScreenState
    extends ConsumerState<CotizacionesListScreen> {
  final _qCtrl = TextEditingController();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = const [];

  String _friendlyError(Object e, {required String fallback}) {
    if (kDebugMode) {
      debugPrint('[Cotizaciones] $fallback: $e');
    }
    return fallback;
  }

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
    final userId = session.user.id;

    setState(() {
      _loading = true;
      _error = null;
    });

    final repo = ref.read(quotationRepositoryProvider);

    // 1) Show local immediately (never blocked by server errors)
    try {
      final local = await repo.listLocal(
        empresaId: empresaId,
        q: _qCtrl.text,
        limit: 50,
        offset: 0,
      );
      if (mounted) setState(() => _items = local);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _friendlyError(
            e,
            fallback: 'No se pudo leer las cotizaciones guardadas localmente.',
          );
          _loading = false;
        });
      }
      return;
    }

    // 2) Best-effort refresh from server
    try {
      await repo.refreshFromServer(
        empresaId: empresaId,
        userId: userId,
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

      if (mounted) {
        setState(() {
          _items = refreshed;
        });
      }
    } catch (e) {
      // Keep showing local data; surface the error as a warning.
      if (mounted) {
        setState(() {
          _error = _friendlyError(
            e,
            fallback:
                'No se pudo sincronizar con el servidor. Mostrando datos locales.',
          );
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cotización'),
        content: const Text('¿Deseas eliminar esta cotización?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final repo = ref.read(quotationRepositoryProvider);
    await repo.deleteRemoteAndLocal(id);
    await _load();
  }

  void _edit(BuildContext context, String id) {
    // Navigate to presupuesto with quotation ID to edit
    context.go('/presupuesto?quotationId=$id');
  }

  Future<void> _duplicate(BuildContext context, id) async {
    final session = await ref.read(localDbProvider).readSession();
    if (session == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('❌ No hay sesión activa')));
      }
      return;
    }

    try {
      final session = await ref.read(localDbProvider).readSession();
      if (session == null) {
        throw StateError('missing_session');
      }
      await ref
          .read(quotationRepositoryProvider)
          .duplicateRemoteToLocal(
            id,
            empresaId: session.user.empresaId,
            userId: session.user.id,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cotización duplicada')));
      }
      await _load();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _friendlyError(e, fallback: 'No se pudo duplicar la cotización.'),
            ),
          ),
        );
      }
    }
  }

  Future<void> _convertToTicket(BuildContext context, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Convertir a Ticket'),
        content: const Text(
          '¿Deseas convertir esta cotización en un ticket de venta?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Convertir'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final repo = ref.read(quotationRepositoryProvider);
      await repo.convertToTicket(id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cotización convertida a ticket'),
            duration: Duration(seconds: 3),
          ),
        );

        // Reload list to show updated status
        await _load();

        // Optionally navigate to sales/ticket view
        // final ticketId = result['ticketId'] as String?;
        // if (ticketId != null) {
        //   context.go('/ventas/$ticketId');
        // }
      }
    } catch (e) {
      if (context.mounted) {
        final message = _friendlyError(
          e,
          fallback: 'No se pudo convertir a ticket.',
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _sendToPosTicket(BuildContext context, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pasar a Ticket Pendiente (POS)'),
        content: const Text(
          'Esto crear\xe1 un ticket pendiente en el TPV para esta cotizaci\xf3n.\n\n'
          'Luego podr\xe1s cobrarlo desde POS.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final quoteRepo = ref.read(quotationRepositoryProvider);
      final full = await quoteRepo.getRemote(id);
      final items = (full['items'] as List?)?.cast<Map>() ?? const [];

      bool isUuid(String s) =>
          RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
              .hasMatch(s);

      final drafts = <PosSaleItemDraft>[];
      for (final raw in items) {
        final m = raw.cast<String, dynamic>();
        final productId = (m['product_id'] ?? '').toString();
        if (!isUuid(productId)) {
          throw StateError(
            'La cotizaci\xf3n contiene items sin producto vinculado. Abre el TPV y agr\xe9galos manualmente.',
          );
        }

        final nombre = (m['nombre'] ?? '').toString();
        final qty = (m['cantidad'] as num?)?.toDouble() ?? 0;
        final unitPrice = (m['unit_price'] as num?)?.toDouble() ?? 0;
        final disc = (m['discount_amount'] as num?)?.toDouble() ?? 0;

        drafts.add(
          PosSaleItemDraft(
            product: PosProduct(
              id: productId,
              nombre: nombre.isEmpty ? 'Producto' : nombre,
              precioVenta: unitPrice,
              costPrice: (m['unit_cost'] as num?)?.toDouble() ?? 0,
              stockQty: 0,
              minStock: 0,
              maxStock: 0,
              allowNegativeStock: false,
              lowStock: false,
              suggestedReorderQty: 0,
              categoria: null,
              imagenUrl: null,
            ),
            qty: qty <= 0 ? 0 : qty,
            unitPrice: unitPrice < 0 ? 0 : unitPrice,
            discountAmount: disc < 0 ? 0 : disc,
          ),
        );
      }

      if (drafts.isEmpty) {
        throw StateError('La cotizaci\xf3n no tiene items.');
      }

      final customerName = (full['customer_name'] ?? '').toString().trim();
      final numero = (full['numero'] ?? '').toString().trim();
      final title = [
        if (numero.isNotEmpty) 'Cot $numero',
        if (customerName.isNotEmpty) customerName,
      ].join(' - ');

      final ticket = PosTicket(
        id: 'quote-$id',
        name: title.isEmpty ? 'Cotizaci\xf3n' : title,
        isCustomName: true,
        customerId: (full['customer_id'] ?? '').toString().trim().isEmpty
            ? null
            : (full['customer_id'] ?? '').toString(),
        customerName: customerName.isEmpty ? null : customerName,
        customerPhone: (full['customer_phone'] ?? '').toString().trim().isEmpty
            ? null
            : (full['customer_phone'] ?? '').toString(),
        customerRnc: (full['customer_rnc'] ?? '').toString().trim().isEmpty
            ? null
            : (full['customer_rnc'] ?? '').toString(),
        discountType: PosDiscountType.fixed,
        discountValue: 0,
        itbisEnabled: full['itbis_enabled'] == true,
        itbisRate: (full['itbis_rate'] as num?)?.toDouble() ?? 0.18,
        ncfEnabled: false,
        selectedNcfDocType: null,
        warrantyEnabled: false,
        selectedWarrantyId: null,
        selectedWarrantyName: null,
        items: drafts,
      );

      ref.read(posTpvControllerProvider.notifier).importTicket(ticket);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket pendiente creado en POS')),
        );
        context.go(AppRoutes.pos);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _friendlyError(e, fallback: 'No se pudo pasar a Ticket POS.'),
            ),
          ),
        );
      }
    }
  }

  Future<void> _send(BuildContext context, String id) async {
    final toCtrl = TextEditingController();
    String channel = 'whatsapp';

    final res = await showDialog<Map<String, dynamic>?>(
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
                  hintText: channel == 'whatsapp'
                      ? '521XXXXXXXXXX'
                      : 'cliente@correo.com',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(
                context,
              ).pop({'channel': channel, 'to': toCtrl.text.trim()}),
              child: const Text('Continuar'),
            ),
          ],
        ),
      ),
    );

    if (res == null) return;

    final repo = ref.read(quotationRepositoryProvider);
    Map<String, dynamic> resp;
    try {
      resp = await repo.sendRemote(
        id,
        channel: res['channel'] as String,
        to: (res['to'] as String).isEmpty ? null : (res['to'] as String),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _friendlyError(e, fallback: 'No se pudo generar el envío.'),
            ),
          ),
        );
      }
      return;
    }

    final url = resp['url']?.toString();
    if (url == null || url.isEmpty) return;

    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace de envío.')),
      );
    }
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
                FilledButton(onPressed: _load, child: const Text('Buscar')),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                ? (_error != null
                      ? Center(child: Text(_error!))
                      : const Center(child: Text('Sin cotizaciones')))
                : Column(
                    children: [
                      if (_error != null)
                        MaterialBanner(
                          content: Text(
                            _error!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          leading: const Icon(Icons.warning_amber_rounded),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          actions: [
                            TextButton(
                              onPressed: () => setState(() => _error = null),
                              child: const Text('Cerrar'),
                            ),
                          ],
                        ),
                      Expanded(
                        child: ListView.separated(
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final it = _items[index];
                            final id = it['id']?.toString() ?? '';
                            final status = it['status']?.toString() ?? '';
                            final isConverted = status == 'converted';

                            return ListTile(
                              title: Text(it['numero']?.toString() ?? ''),
                              subtitle: Text(
                                '${it['customer_name'] ?? ''} • ${it['status'] ?? ''}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!isConverted)
                                    IconButton(
                                      tooltip: 'Editar',
                                      onPressed: id.isEmpty
                                          ? null
                                          : () => _edit(context, id),
                                      icon: const Icon(Icons.edit),
                                    ),
                                  if (!isConverted)
                                    IconButton(
                                      tooltip: 'Convertir a Ticket',
                                      onPressed: id.isEmpty
                                          ? null
                                          : () => _convertToTicket(context, id),
                                      icon: const Icon(Icons.point_of_sale),
                                    ),
                                  if (!isConverted)
                                    IconButton(
                                      tooltip: 'Pasar a Ticket POS',
                                      onPressed: id.isEmpty
                                          ? null
                                          : () => _sendToPosTicket(context, id),
                                      icon: const Icon(Icons.shopping_bag_outlined),
                                    ),
                                  PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      if (value == 'ver') {
                                        context.go('/cotizaciones/$id');
                                      } else if (value == 'editar') {
                                        _edit(context, id);
                                      } else if (value == 'duplicar') {
                                        await _duplicate(context, id);
                                      } else if (value == 'convertir' &&
                                          !isConverted) {
                                        await _convertToTicket(context, id);
                                      } else if (value == 'pos_ticket' &&
                                          !isConverted) {
                                        await _sendToPosTicket(context, id);
                                      } else if (value == 'enviar') {
                                        await _send(context, id);
                                      } else if (value == 'eliminar') {
                                        await _confirmDelete(context, id);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'ver',
                                        child: Text('Ver Detalle'),
                                      ),
                                      if (!isConverted)
                                        const PopupMenuItem(
                                          value: 'editar',
                                          child: Text('Editar'),
                                        ),
                                      const PopupMenuItem(
                                        value: 'duplicar',
                                        child: Text('Duplicar'),
                                      ),
                                      if (!isConverted)
                                        const PopupMenuItem(
                                          value: 'convertir',
                                          child: Text('Convertir a Ticket'),
                                        ),
                                      if (!isConverted)
                                        const PopupMenuItem(
                                          value: 'pos_ticket',
                                          child: Text('Pasar a Ticket POS'),
                                        ),
                                      const PopupMenuItem(
                                        value: 'enviar',
                                        child: Text('Enviar'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'eliminar',
                                        child: Text('Eliminar'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              onTap: id.isEmpty
                                  ? null
                                  : () => context.go('/cotizaciones/$id'),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
