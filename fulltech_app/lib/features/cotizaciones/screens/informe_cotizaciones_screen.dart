import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/module_page.dart';
import '../../auth/state/auth_providers.dart';
import '../../auth/state/auth_state.dart';
import '../models/letter_models.dart';
import '../state/letters_providers.dart';

class InformeCotizacionesScreen extends ConsumerStatefulWidget {
  const InformeCotizacionesScreen({super.key});

  @override
  ConsumerState<InformeCotizacionesScreen> createState() =>
      _InformeCotizacionesScreenState();
}

class _InformeCotizacionesScreenState
    extends ConsumerState<InformeCotizacionesScreen> {
  final _qCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  Timer? _debounce;

  String? _letterType;
  String? _status;

  bool _loading = false;
  bool _loadingMore = false;
  bool _serverRefreshing = false;
  String? _error;

  final _limit = 30;
  int _offset = 0;
  bool _hasMore = true;

  List<LetterRecord> _items = const [];

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    Future.microtask(() => _load(reset: true, refreshServer: true));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _qCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loadingMore || !_hasMore) return;
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    if (pos.extentAfter < 320) {
      _loadMore();
    }
  }

  String _fmtDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      final dd = d.day.toString().padLeft(2, '0');
      final mm = d.month.toString().padLeft(2, '0');
      final yy = d.year.toString();
      return '$dd/$mm/$yy';
    } catch (_) {
      return iso;
    }
  }

  Future<void> _load({required bool reset, required bool refreshServer}) async {
    final auth = ref.read(authControllerProvider);
    if (auth is! AuthAuthenticated) return;
    final empresaId = auth.user.empresaId;

    final repo = ref.read(lettersRepositoryProvider);
    final q = _qCtrl.text.trim();

    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _offset = 0;
        _hasMore = true;
        _items = const [];
      });
    } else {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      if (refreshServer) {
        setState(() => _serverRefreshing = true);
        try {
          await repo.refreshFromServer(
            empresaId: empresaId,
            q: q.isEmpty ? null : q,
            letterType: _letterType,
            status: _status,
            limit: _limit,
            offset: 0,
          );
        } finally {
          if (mounted) setState(() => _serverRefreshing = false);
        }
      }

      final local = await repo.listLocal(
        empresaId: empresaId,
        q: q.isEmpty ? null : q,
        letterType: _letterType,
        status: _status,
        limit: _limit,
        offset: 0,
      );

      if (!mounted) return;
      setState(() {
        _loading = false;
        _items = local;
        _offset = local.length;
        _hasMore = local.length == _limit;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadMore() async {
    final auth = ref.read(authControllerProvider);
    if (auth is! AuthAuthenticated) return;
    final empresaId = auth.user.empresaId;

    setState(() {
      _loadingMore = true;
      _error = null;
    });

    try {
      final repo = ref.read(lettersRepositoryProvider);
      final q = _qCtrl.text.trim();

      // Best-effort refresh server for this page.
      try {
        await repo.refreshFromServer(
          empresaId: empresaId,
          q: q.isEmpty ? null : q,
          letterType: _letterType,
          status: _status,
          limit: _limit,
          offset: _offset,
        );
      } catch (_) {
        // ignore, local still loads
      }

      final local = await repo.listLocal(
        empresaId: empresaId,
        q: q.isEmpty ? null : q,
        letterType: _letterType,
        status: _status,
        limit: _limit,
        offset: _offset,
      );

      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        _items = [..._items, ...local];
        _offset += local.length;
        _hasMore = local.length == _limit;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        _error = e.toString();
      });
    }
  }

  void _onQueryChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _load(reset: true, refreshServer: true);
    });
  }

  Future<void> _confirmAndDelete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar carta'),
        content: const Text('Se eliminará la carta (soft delete).'),
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

    try {
      await ref.read(lettersRepositoryProvider).deleteLetterLocalFirst(id: id);
      if (!mounted) return;
      await _load(reset: true, refreshServer: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar: $e')),
      );
    }
  }

  IconData _syncIcon(String s) {
    if (s == SyncStatus.synced) return Icons.check_circle_outline;
    if (s == SyncStatus.error) return Icons.error_outline;
    return Icons.sync;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final auth = ref.watch(authControllerProvider);
    if (auth is! AuthAuthenticated) {
      return const ModulePage(title: 'Cartas', child: SizedBox.shrink());
    }

    return ModulePage(
      title: 'Cartas',
      actions: [
        IconButton(
          tooltip: 'Nueva carta',
          onPressed: () => context.go(AppRoutes.crearCartas),
          icon: const Icon(Icons.add),
        ),
        IconButton(
          tooltip: 'Refrescar',
          onPressed: _loading ? null : () => _load(reset: true, refreshServer: true),
          icon: _serverRefreshing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
        ),
      ],
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 320,
                  child: TextField(
                    controller: _qCtrl,
                    onChanged: _onQueryChanged,
                    decoration: const InputDecoration(
                      labelText: 'Buscar',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                    ),
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: DropdownButtonFormField<String>(
                    initialValue: _letterType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Todos'),
                      ),
                      for (final t in LetterType.all)
                        DropdownMenuItem(value: t, child: Text(t)),
                    ],
                    onChanged: (v) {
                      setState(() => _letterType = v);
                      _load(reset: true, refreshServer: true);
                    },
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(
                      labelText: 'Estado',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Todos'),
                      ),
                      for (final s in LetterStatus.all)
                        DropdownMenuItem(value: s, child: Text(s)),
                    ],
                    onChanged: (v) {
                      setState(() => _status = v);
                      _load(reset: true, refreshServer: true);
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? Center(
                        child: Text(
                          _error ?? 'No hay cartas',
                          style: TextStyle(color: _error != null ? cs.error : null),
                        ),
                      )
                    : ListView.separated(
                        controller: _scrollCtrl,
                        itemCount: _items.length + (_loadingMore ? 1 : 0),
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          if (_loadingMore && index == _items.length) {
                            return const Padding(
                              padding: EdgeInsets.all(12),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final it = _items[index];
                          final subtitle =
                              '${it.customerName} • ${it.letterType} • ${it.status} • ${_fmtDate(it.createdAt)}';

                          return ListTile(
                            leading: Icon(
                              _syncIcon(it.syncStatus),
                              color: it.syncStatus == SyncStatus.error
                                  ? cs.error
                                  : cs.primary,
                            ),
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
                            trailing: Wrap(
                              spacing: 4,
                              children: [
                                IconButton(
                                  tooltip: 'Editar',
                                  onPressed: () => context.go(
                                    '${AppRoutes.crearCartas}?id=${Uri.encodeComponent(it.id)}',
                                  ),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip: 'Ver PDF',
                                  onPressed: () => context.go(
                                    '${AppRoutes.crearCartas}?id=${Uri.encodeComponent(it.id)}&openPdf=1',
                                  ),
                                  icon: const Icon(Icons.picture_as_pdf_outlined),
                                ),
                                IconButton(
                                  tooltip: 'Marcar enviada',
                                  onPressed: it.status == LetterStatus.sent
                                      ? null
                                      : () async {
                                          await ref
                                              .read(lettersRepositoryProvider)
                                              .markSent(
                                                empresaId: auth.user.empresaId,
                                                id: it.id,
                                              );
                                          if (!mounted) return;
                                          await _load(
                                            reset: true,
                                            refreshServer: false,
                                          );
                                        },
                                  icon: const Icon(Icons.send_outlined),
                                ),
                                IconButton(
                                  tooltip: 'Eliminar',
                                  onPressed: () => _confirmAndDelete(it.id),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          if (_error != null && _items.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: cs.errorContainer,
              child: Text(
                _error!,
                style: TextStyle(color: cs.onErrorContainer),
              ),
            ),
        ],
      ),
    );
  }
}
