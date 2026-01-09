import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/crm_quick_reply.dart';
import '../../state/crm_providers.dart';
import '../../../auth/state/auth_providers.dart';
import '../../../auth/state/auth_state.dart';

class QuickRepliesModal extends ConsumerStatefulWidget {
  final void Function(CrmQuickReply reply) onSelect;

  const QuickRepliesModal({super.key, required this.onSelect});

  @override
  ConsumerState<QuickRepliesModal> createState() => _QuickRepliesModalState();
}

class _QuickRepliesModalState extends ConsumerState<QuickRepliesModal> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  bool _loading = false;
  String? _error;
  String? _category;
  List<CrmQuickReply> _items = const [];

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
    _searchCtrl.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 250), _load);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  bool get _isAdmin {
    final auth = ref.read(authControllerProvider);
    if (auth is! AuthAuthenticated) return false;
    final r = auth.user.role;
    return r == 'admin' || r == 'administrador';
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = ref.read(crmRepositoryProvider);
      final items = await repo.listQuickReplies(
        search: _searchCtrl.text,
        category: _category,
        isActive: true,
      );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          const Expanded(child: Text('Plantillas')),
          if (_isAdmin)
            IconButton(
              tooltip: 'Crear plantilla',
              onPressed: () async {
                final created = await _openUpsertDialog(context);
                if (created == true) await _load();
              },
              icon: const Icon(Icons.add),
            ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Buscar',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Todas')),
                DropdownMenuItem(value: 'Ventas', child: Text('Ventas')),
                DropdownMenuItem(value: 'Soporte', child: Text('Soporte')),
                DropdownMenuItem(value: 'Entrega', child: Text('Entrega')),
                DropdownMenuItem(value: 'Promos', child: Text('Promos')),
              ],
              onChanged: (v) {
                setState(() => _category = v);
                _load();
              },
            ),
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            const SizedBox(height: 8),
            Flexible(
              child: _items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Sin plantillas'),
                            if (_isAdmin) ...[
                              const SizedBox(height: 8),
                              FilledButton.icon(
                                onPressed: () async {
                                  final created = await _openUpsertDialog(
                                    context,
                                  );
                                  if (created == true) await _load();
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Crear la primera'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final r = _items[i];
                        return ListTile(
                          title: Text(
                            r.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            r.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          leading: CircleAvatar(
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            child: Text(
                              r.category.isNotEmpty ? r.category[0] : '?',
                            ),
                          ),
                          trailing: _isAdmin
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Editar',
                                      onPressed: () async {
                                        final ok = await _openUpsertDialog(
                                          context,
                                          existing: r,
                                        );
                                        if (ok == true) await _load();
                                      },
                                      icon: const Icon(Icons.edit),
                                    ),
                                    IconButton(
                                      tooltip: 'Eliminar',
                                      onPressed: () async {
                                        final ok = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text(
                                              'Eliminar plantilla',
                                            ),
                                            content: Text(
                                              '¿Eliminar "${r.title}"?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                                child: const Text('Cancelar'),
                                              ),
                                              FilledButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                                child: const Text('Eliminar'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (ok != true) return;
                                        await ref
                                            .read(crmRepositoryProvider)
                                            .deleteQuickReply(r.id);
                                        await _load();
                                      },
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                  ],
                                )
                              : null,
                          onTap: () {
                            widget.onSelect(r);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }

  Future<bool?> _openUpsertDialog(
    BuildContext context, {
    CrmQuickReply? existing,
  }) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final keywordsCtrl = TextEditingController(text: existing?.keywords ?? '');
    final contentCtrl = TextEditingController(text: existing?.content ?? '');
    String category = existing?.category ?? 'Ventas';
    bool isActive = existing?.isActive ?? true;
    bool allowComment = existing?.allowComment ?? true;
    String? formError;

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: Text(
                existing == null ? 'Nueva plantilla' : 'Editar plantilla',
              ),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        isDense: true,
                      ),
                    ),
                    if (formError != null) ...[
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Ventas',
                          child: Text('Ventas'),
                        ),
                        DropdownMenuItem(
                          value: 'Soporte',
                          child: Text('Soporte'),
                        ),
                        DropdownMenuItem(
                          value: 'Entrega',
                          child: Text('Entrega'),
                        ),
                        DropdownMenuItem(
                          value: 'Promos',
                          child: Text('Promos'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setLocal(() => category = v);
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: keywordsCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Palabras clave (separadas por coma)',
                        hintText:
                            'Ej: ubicacion, donde quedan, direccion, mapa',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: contentCtrl,
                      minLines: 3,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        labelText: 'Contenido',
                        hintText:
                            'Usa variables: {nombre} {telefono} {producto} {precio} {empresa}',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: isActive,
                      onChanged: (v) => setLocal(() => isActive = v),
                      title: const Text('Activa'),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: allowComment,
                      onChanged: (v) => setLocal(() => allowComment = v),
                      title: const Text('Permitir comentario'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    final title = titleCtrl.text.trim();
                    final content = contentCtrl.text.trim();
                    final keywords = keywordsCtrl.text.trim();
                    if (title.isEmpty || content.isEmpty) {
                      setLocal(() {
                        formError = 'Título y contenido son requeridos.';
                      });
                      return;
                    }
                    setLocal(() {
                      formError = null;
                    });

                    final repo = ref.read(crmRepositoryProvider);
                    if (existing == null) {
                      await repo.createQuickReply(
                        title: title,
                        category: category,
                        content: content,
                        keywords: keywords.isEmpty ? null : keywords,
                        allowComment: allowComment,
                        isActive: isActive,
                      );
                    } else {
                      await repo.updateQuickReply(
                        id: existing.id,
                        title: title,
                        category: category,
                        content: content,
                        keywords: keywords.isEmpty ? null : keywords,
                        allowComment: allowComment,
                        isActive: isActive,
                      );
                    }

                    if (context.mounted) Navigator.pop(context, true);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      titleCtrl.dispose();
      keywordsCtrl.dispose();
      contentCtrl.dispose();
    });
  }
}
