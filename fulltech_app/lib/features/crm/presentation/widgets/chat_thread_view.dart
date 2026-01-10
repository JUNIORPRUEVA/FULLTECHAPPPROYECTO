import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/crm_thread.dart';
import '../../data/models/ai_suggestion.dart';
import '../../state/crm_messages_state.dart';
import '../../state/crm_providers.dart';
import 'message_bubble.dart';
import 'quick_replies_modal.dart';
import '../../../catalogo/models/producto.dart';

class ChatThreadView extends ConsumerStatefulWidget {
  final String threadId;
  final VoidCallback? onOpenRightPanel;

  const ChatThreadView({
    super.key,
    required this.threadId,
    this.onOpenRightPanel,
  });

  @override
  ConsumerState<ChatThreadView> createState() => _ChatThreadViewState();
}

class _ChatThreadViewState extends ConsumerState<ChatThreadView> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  ProviderSubscription<CrmMessagesState>? _messagesSub;
  bool _isNearBottom = true;
  int _pendingNewCount = 0;

  bool _aiEnabled = false;
  bool _aiLoading = false;
  String? _aiError;
  List<AiSuggestion> _aiSuggestions = const [];
  List<String> _aiUsedKnowledge = const [];
  String? _aiForCustomerMessageId;
  Timer? _aiDebounce;

  // Cache thread info for sending messages
  String? _cachedWaId;
  String? _cachedPhone;

  @override
  void initState() {
    super.initState();

    _scrollCtrl.addListener(_handleScroll);
    _listenToMessages(widget.threadId);

    Future.microtask(_loadAiSettings);

    Future.microtask(() async {
      await ref
          .read(crmMessagesControllerProvider(widget.threadId).notifier)
          .loadInitial();
      _scrollToBottom();
    });
  }

  @override
  void didUpdateWidget(covariant ChatThreadView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.threadId == widget.threadId) return;

    Future.microtask(() async {
      _pendingNewCount = 0;
      _aiForCustomerMessageId = null;
      _aiSuggestions = const [];
      _aiUsedKnowledge = const [];
      _aiError = null;

      _listenToMessages(widget.threadId);
      await ref
          .read(crmMessagesControllerProvider(widget.threadId).notifier)
          .loadInitial();
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messagesSub?.close();
    _aiDebounce?.cancel();
    _textCtrl.dispose();
    _scrollCtrl.removeListener(_handleScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final online = ref
        .watch(crmOnlineProvider)
        .maybeWhen(data: (v) => v, orElse: () => true);

    final threadsState = ref.watch(crmThreadsControllerProvider);
    final thread = threadsState.items
        .where((t) => t.id == widget.threadId)
        .cast<CrmThread?>()
        .firstOrNull;

    // Update cache whenever build runs with fresh thread data
    if (thread != null) {
      _cachedWaId = thread.waId;
      _cachedPhone = thread.phone;
    }

    final state = ref.watch(crmMessagesControllerProvider(widget.threadId));
    final notifier = ref.read(
      crmMessagesControllerProvider(widget.threadId).notifier,
    );

    final title =
        (thread?.displayName != null && thread!.displayName!.trim().isNotEmpty)
        ? thread.displayName!.trim()
        : (thread?.phone ?? thread?.waId ?? 'Chat');

    final subtitle = thread?.phone ?? thread?.waId ?? '';
    final statusText = online ? 'Conectado' : 'Offline';
    final statusColor = online
        ? theme.colorScheme.primary
        : theme.colorScheme.error;

    final productsAsync = ref.watch(crmProductsProvider);
    final hasProductId = (thread?.productId ?? '').trim().isNotEmpty;
    final product = !hasProductId
        ? null
        : (productsAsync.asData?.value ?? const <Producto>[])
              .where((p) => p.id == thread!.productId)
              .cast<Producto?>()
              .firstOrNull;

    return Card(
      child: Column(
        children: [
          // Header
          Builder(
            builder: (context) {
              Chip pill({
                required String text,
                required Color bg,
                required Color fg,
              }) {
                return Chip(
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: BorderSide(color: bg),
                  backgroundColor: bg,
                  labelPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 0,
                  ),
                  label: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  labelStyle: theme.textTheme.labelSmall?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w800,
                  ),
                );
              }

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: theme.dividerColor, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      child: Text(
                        _initials(title),
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (subtitle.isNotEmpty) ...[
                              TextSpan(
                                text: '  •  $subtitle',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.75),
                                ),
                              ),
                            ],
                            TextSpan(
                              text: '  •  ',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.6,
                                ),
                              ),
                            ),
                            TextSpan(
                              text: statusText,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (thread != null || hasProductId) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 340),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (thread != null)
                                  pill(
                                    text: thread.status.replaceAll('_', ' '),
                                    bg: theme.colorScheme.primaryContainer,
                                    fg: theme.colorScheme.onPrimaryContainer,
                                  ),
                                if (thread != null && hasProductId)
                                  const SizedBox(width: 8),
                                if (hasProductId)
                                  pill(
                                    text:
                                        (product?.nombre.trim().isNotEmpty ??
                                            false)
                                        ? product!.nombre.trim()
                                        : (productsAsync.isLoading
                                              ? 'Producto: Cargando...'
                                              : 'Producto: No encontrado'),
                                    bg: theme.colorScheme.secondaryContainer,
                                    fg: theme.colorScheme.onSecondaryContainer,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 6),
                    IconButton(
                      tooltip: 'Refrescar',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 34,
                        height: 34,
                      ),
                      onPressed: () async {
                        await notifier.loadInitial();
                        _scrollToBottom();
                      },
                      icon: const Icon(Icons.refresh, size: 20),
                    ),
                    if (widget.onOpenRightPanel != null)
                      IconButton(
                        tooltip: 'Gestión',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 34,
                          height: 34,
                        ),
                        onPressed: widget.onOpenRightPanel,
                        icon: const Icon(Icons.tune, size: 20),
                      ),
                  ],
                ),
              );
            },
          ),

          // Messages
          Expanded(
            child: Builder(
              builder: (context) {
                if (state.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.items.isEmpty) {
                  return const Center(child: Text('Sin mensajes'));
                }

                return Column(
                  children: [
                    if (state.error != null)
                      Container(
                        margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer.withOpacity(
                            0.3,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: theme.colorScheme.error,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                state.error!.length > 80
                                    ? '${state.error!.substring(0, 80)}...'
                                    : state.error!,
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: Stack(
                        children: [
                          ListView.builder(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.all(12),
                            itemCount: state.items.length,
                            itemBuilder: (context, i) {
                              return MessageBubble(
                                message: state.items[i],
                                displayName: thread?.displayName,
                                phone: thread?.phone,
                              );
                            },
                          ),
                          if (_pendingNewCount > 0 && !_isNearBottom)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 12,
                              child: Center(
                                child: FilledButton.tonalIcon(
                                  onPressed: () {
                                    setState(() {
                                      _pendingNewCount = 0;
                                    });
                                    _scrollToBottom();
                                  },
                                  icon: const Icon(Icons.arrow_downward),
                                  label: Text(
                                    _pendingNewCount > 1
                                        ? '↓ Nuevos ($_pendingNewCount)'
                                        : '↓ Nuevos',
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Composer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: theme.dividerColor, width: 1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_aiEnabled)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Sugerencias IA',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            if (_aiSuggestions.isNotEmpty)
                              TextButton(
                                onPressed: _openAiSuggestionsModal,
                                child: const Text('Ver más'),
                              ),
                          ],
                        ),
                        if (_aiLoading)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Generando sugerencias…',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (_aiError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _aiError!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                                height: 1.25,
                              ),
                            ),
                          ),
                        if (_aiSuggestions.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _aiSuggestions
                                  .map(
                                    (s) => ActionChip(
                                      backgroundColor: theme
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      labelStyle: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface,
                                            fontWeight: FontWeight.w700,
                                          ),
                                      label: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 320,
                                        ),
                                        child: Text(
                                          _oneLine(s.text),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      onPressed: () => _openAiEditor(s),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                      ],
                    ),
                  ),
                _MiniFormatBar(
                  onBold: () => _wrapSelection('*', '*'),
                  onItalic: () => _wrapSelection('_', '_'),
                  onStrike: () => _wrapSelection('~', '~'),
                  onMono: () => _wrapSelection('```', '```'),
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 420;
                    final iconButtons = <Widget>[
                      IconButton(
                        tooltip: 'Plantillas',
                        iconSize: 20,
                        visualDensity: VisualDensity.compact,
                        onPressed: _openQuickReplies,
                        icon: const Icon(Icons.bolt),
                      ),
                    ];

                    final inputField = Expanded(
                      child: TextField(
                        controller: _textCtrl,
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Escribe un mensaje…',
                          isDense: true,
                        ),
                        onSubmitted: (_) => _sendText(notifier),
                      ),
                    );

                    final sendButton = isNarrow
                        ? FilledButton(
                            onPressed: state.sending
                                ? null
                                : () => _sendText(notifier),
                            child: state.sending
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.send),
                          )
                        : FilledButton.icon(
                            onPressed: state.sending
                                ? null
                                : () => _sendText(notifier),
                            icon: state.sending
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.send),
                            label: const Text('Enviar'),
                          );

                    // Always use a 2-row layout to prevent overflows in
                    // narrow/right-side panels (Windows desktop often constrains
                    // the composer to ~200px).
                    return Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            spacing: 0,
                            runSpacing: 0,
                            children: iconButtons,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            inputField,
                            const SizedBox(width: 10),
                            sendButton,
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _wrapSelection(String left, String right) {
    final v = _textCtrl.value;
    final text = v.text;
    final sel = v.selection;

    final start = sel.start >= 0 ? sel.start : text.length;
    final end = sel.end >= 0 ? sel.end : text.length;

    if (start == end) {
      final inserted = '$left$right';
      final newText = text.replaceRange(start, start, inserted);
      _textCtrl.value = v.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: start + left.length),
        composing: TextRange.empty,
      );
      return;
    }

    final selected = text.substring(start, end);
    final wrapped = '$left$selected$right';
    final newText = text.replaceRange(start, end, wrapped);
    _textCtrl.value = v.copyWith(
      text: newText,
      selection: TextSelection(
        baseOffset: start + left.length,
        extentOffset: start + left.length + selected.length,
      ),
      composing: TextRange.empty,
    );
  }

  Future<void> _sendText(dynamic notifier) async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    _textCtrl.clear();
    await notifier.sendText(
      text,
      toWaId: _cachedWaId,
      toPhone: _cachedPhone,
    );

    unawaited(
      ref.read(crmThreadsControllerProvider.notifier).refresh().catchError((_) {}),
    );
    _scrollToBottom();
  }

  Future<void> _openQuickReplies() async {
    final threadsState = ref.read(crmThreadsControllerProvider);
    final thread = threadsState.items
        .where((t) => t.id == widget.threadId)
        .cast<CrmThread?>()
        .firstOrNull;

    final products =
        ref.read(crmProductsProvider).asData?.value ?? const <Producto>[];
    final product = thread?.productId == null
        ? null
        : products
              .where((p) => p.id == thread!.productId)
              .cast<Producto?>()
              .firstOrNull;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return QuickRepliesModal(
          onSelect: (reply) {
            final resolved = _resolveTemplate(reply.content, thread, product);
            _insertIntoInput(resolved);
          },
        );
      },
    );
  }

  static String _resolveTemplate(
    String content,
    CrmThread? thread,
    Producto? product,
  ) {
    String r = content;
    r = r.replaceAll('{nombre}', (thread?.displayName ?? '').trim());
    r = r.replaceAll('{telefono}', (thread?.phone ?? '').trim());
    r = r.replaceAll('{producto}', (product?.nombre ?? '').trim());
    r = r.replaceAll(
      '{precio}',
      product == null ? '' : product.precioVenta.toStringAsFixed(2),
    );
    r = r.replaceAll('{empresa}', '');
    return r;
  }

  void _insertIntoInput(String text) {
    final v = _textCtrl.value;
    final base = v.text;
    final next = base.trim().isEmpty ? text : '$base\n$text';
    _textCtrl.value = v.copyWith(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
      composing: TextRange.empty,
    );
  }

  void _scrollToBottom() {
    if (!_scrollCtrl.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      return;
    }
    final target = _scrollCtrl.position.maxScrollExtent;
    _scrollCtrl.animateTo(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _listenToMessages(String threadId) {
    _messagesSub?.close();
    _messagesSub = ref.listenManual<CrmMessagesState>(
      crmMessagesControllerProvider(threadId),
      (prev, next) {
        final prevLen = (prev?.items.length ?? 0);
        final nextLen = next.items.length;
        if (nextLen <= prevLen) return;

        final added = nextLen - prevLen;
        if (_isNearBottom) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _scrollToBottom();
          });
          if (_pendingNewCount != 0) {
            setState(() {
              _pendingNewCount = 0;
            });
          }
        } else {
          setState(() {
            _pendingNewCount += added;
          });
        }

        _maybeTriggerAiSuggest(prev, next);
      },
    );
  }

  void _maybeTriggerAiSuggest(CrmMessagesState? prev, CrmMessagesState next) {
    if (!_aiEnabled) return;
    if (next.items.isEmpty) return;

    final lastIn = next.items.reversed.firstWhere(
      (m) => !m.fromMe,
      orElse: () => next.items.first,
    );
    if (lastIn.fromMe) return;

    if (lastIn.id == _aiForCustomerMessageId) return;

    final prevLen = prev?.items.length ?? 0;
    final nextLen = next.items.length;
    if (nextLen <= prevLen) return;

    _aiForCustomerMessageId = lastIn.id;
    _aiDebounce?.cancel();
    _aiDebounce = Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      _runAiSuggest(lastIn.id, lastIn.body ?? '');
    });
  }

  Future<void> _loadAiSettings() async {
    try {
      final repo = ref.read(crmRepositoryProvider);
      final s = await repo.getAiSettingsPublic();
      if (!mounted) return;
      setState(() {
        _aiEnabled = s.enabled;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _aiEnabled = false;
      });
    }
  }

  Future<void> _runAiSuggest(String lastCustomerMessageId, String text) async {
    final t = text.trim();
    if (t.isEmpty) return;

    setState(() {
      _aiLoading = true;
      _aiError = null;
      _aiSuggestions = const [];
      _aiUsedKnowledge = const [];
    });

    try {
      final repo = ref.read(crmRepositoryProvider);
      final resp = await repo.suggestAi(
        chatId: widget.threadId,
        lastCustomerMessageId: lastCustomerMessageId,
        customerMessageText: t,
        quickRepliesEnabled: true,
      );

      if (!mounted) return;
      setState(() {
        _aiLoading = false;
        _aiSuggestions = resp.suggestions;
        _aiUsedKnowledge = resp.usedKnowledge;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _aiLoading = false;
        _aiError = _formatAiError(e);
      });
    }
  }

  String _formatAiError(Object e) {
    var s = e.toString();
    // Strip internal prefixes to keep the UI readable.
    s = s.replaceAll(RegExp(r'^\[CRM\]\[AI_SUGGEST\]\s*'), '');
    s = s.replaceAll(RegExp(r'^Exception:\s*'), '');
    if (s.contains('SocketException') ||
        s.toLowerCase().contains('failed host lookup')) {
      return 'Sin conexión con el servidor para generar sugerencias.';
    }
    if (s.toLowerCase().contains('timeout')) {
      return 'La IA tardó demasiado en responder. Intenta de nuevo.';
    }
    // Prevent huge error strings from breaking layout.
    s = s.trim();
    if (s.length > 240) {
      s = '${s.substring(0, 240)}…';
    }
    return s.isEmpty ? 'No se pudo generar sugerencias.' : s;
  }

  static String _oneLine(String input) {
    final v = input
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return v;
  }

  Future<void> _openAiSuggestionsModal() async {
    if (_aiSuggestions.isEmpty) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: const Text('Sugerencias IA'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _aiSuggestions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final s = _aiSuggestions[i];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  title: Text(
                    s.text,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.25),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _openAiEditor(s);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openAiEditor(AiSuggestion suggestion) async {
    final ctrl = TextEditingController(text: suggestion.text);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: const Text('Editar sugerencia'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: TextField(
              controller: ctrl,
              minLines: 4,
              maxLines: 10,
              style: theme.textTheme.bodyMedium,
              decoration: const InputDecoration(
                hintText: 'Edita antes de enviar…',
                isDense: true,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );

    if (ok != true) {
      ctrl.dispose();
      return;
    }

    final text = ctrl.text.trim();
    ctrl.dispose();
    if (text.isEmpty) return;

    if (kDebugMode) {
      debugPrint(
        '[CRM_UI] Sending AI suggestion: threadId=${widget.threadId} waId=$_cachedWaId phone=$_cachedPhone text=${text.length} chars',
      );
    }

    final notifier = ref.read(
      crmMessagesControllerProvider(widget.threadId).notifier,
    );
    unawaited(
      notifier
          .sendText(
            text,
            toWaId: _cachedWaId,
            toPhone: _cachedPhone,
            aiSuggestionId: suggestion.id,
            aiSuggestedText: suggestion.text,
            aiUsedKnowledge: _aiUsedKnowledge,
          )
          .catchError((e) {
            if (kDebugMode) {
              debugPrint('[CRM_UI] Send AI suggestion error: $e');
            }
          }),
    );

    if (!mounted) return;
    setState(() {
      _aiSuggestions = const [];
      _aiUsedKnowledge = const [];
      _aiError = null;
    });
  }

  void _handleScroll() {
    if (!_scrollCtrl.hasClients) return;
    final near = _scrollCtrl.position.extentAfter < 140;
    if (near == _isNearBottom) return;
    setState(() {
      _isNearBottom = near;
      if (_isNearBottom) _pendingNewCount = 0;
    });
  }

  static String _initials(String v) {
    final parts = v.trim().split(RegExp(r'\s+'));
    final a = parts.isNotEmpty ? parts.first : '';
    final b = parts.length > 1 ? parts[1] : '';
    final s = '${a.isNotEmpty ? a[0] : ''}${b.isNotEmpty ? b[0] : ''}'
        .toUpperCase();
    return s.isEmpty ? '?' : s;
  }
}

class _MiniFormatBar extends StatelessWidget {
  final VoidCallback onBold;
  final VoidCallback onItalic;
  final VoidCallback onStrike;
  final VoidCallback onMono;

  const _MiniFormatBar({
    required this.onBold,
    required this.onItalic,
    required this.onStrike,
    required this.onMono,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w800,
    );

    Widget btn(String label, VoidCallback onTap, {String? tooltip}) {
      return Padding(
        padding: const EdgeInsets.only(right: 4),
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            minimumSize: const Size(32, 28),
          ),
          child: Tooltip(
            message: tooltip ?? label,
            child: Text(label, style: style),
          ),
        ),
      );
    }

    return Row(
      children: [
        btn('B', onBold, tooltip: 'Negrita'),
        btn('I', onItalic, tooltip: 'Cursiva'),
        btn('S', onStrike, tooltip: 'Tachado'),
        btn('</>', onMono, tooltip: 'Mono'),
        const Spacer(),
      ],
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
