import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/module_page.dart';
import '../../data/models/crm_thread.dart';
import '../../state/crm_providers.dart';
import '../widgets/message_bubble.dart';

class ThreadChatPage extends StatelessWidget {
  final String threadId;

  const ThreadChatPage({super.key, required this.threadId});

  @override
  Widget build(BuildContext context) {
    return ModulePage(
      title: 'Chat',
      actions: [
        IconButton(
          tooltip: 'Volver',
          onPressed: () => context.go(AppRoutes.crm),
          icon: const Icon(Icons.arrow_back),
        ),
      ],
      child: Column(
        children: [
          Expanded(
            child: ThreadChatPanel(threadId: threadId),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: ThreadInfoPanel(threadId: threadId),
          ),
        ],
      ),
    );
  }
}

class ThreadChatPanel extends ConsumerStatefulWidget {
  final String threadId;

  const ThreadChatPanel({super.key, required this.threadId});

  @override
  ConsumerState<ThreadChatPanel> createState() => _ThreadChatPanelState();
}

class _ThreadChatPanelState extends ConsumerState<ThreadChatPanel> {
  final _textCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(crmMessagesControllerProvider(widget.threadId).notifier).loadInitial();
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(crmMessagesControllerProvider(widget.threadId));
    final notifier = ref.read(crmMessagesControllerProvider(widget.threadId).notifier);

    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Mensajes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                if (state.nextBefore != null)
                  TextButton.icon(
                    onPressed: state.loadingMore ? null : () => notifier.loadMore(),
                    icon: state.loadingMore
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.history),
                    label: const Text('Anterior'),
                  ),
                IconButton(
                  tooltip: 'Refrescar',
                  onPressed: () => notifier.loadInitial(),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Builder(
              builder: (context) {
                if (state.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.error != null) {
                  return Center(child: Text(state.error!));
                }
                if (state.items.isEmpty) {
                  return const Center(child: Text('Sin mensajes'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: state.items.length,
                  itemBuilder: (context, i) {
                    return MessageBubble(message: state.items[i]);
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Adjuntar archivo',
                  onPressed: state.sending ? null : () => _pickAndSendMedia(notifier),
                  icon: const Icon(Icons.attach_file),
                ),
                Expanded(
                  child: TextField(
                    controller: _textCtrl,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Escribe un mensaje...',
                    ),
                    onSubmitted: (_) => _send(notifier),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: state.sending ? null : () => _send(notifier),
                  icon: state.sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: const Text('Enviar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _send(dynamic notifier) {
    final text = _textCtrl.text;
    _textCtrl.clear();
    notifier.sendText(text);
    ref.read(crmThreadsControllerProvider.notifier).refresh();
  }

  Future<void> _pickAndSendMedia(dynamic notifier) async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: kIsWeb,
    );
    final file = res?.files.firstOrNull;
    if (file == null) return;

    await notifier.sendMedia(file);
    ref.read(crmThreadsControllerProvider.notifier).refresh();
  }
}

class ThreadInfoPanel extends ConsumerWidget {
  final String threadId;

  const ThreadInfoPanel({super.key, required this.threadId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadsState = ref.watch(crmThreadsControllerProvider);
    final thread = threadsState.items.where((t) => t.id == threadId).cast<CrmThread?>().firstOrNull;

    if (thread == null) {
      return const Card(child: Center(child: Text('Cargando detalles...')));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Detalles',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            Text('WhatsApp ID: ${thread.waId}'),
            const SizedBox(height: 6),
            Text('Teléfono: ${thread.phone ?? '-'}'),
            const SizedBox(height: 6),
            Text('Estado: ${thread.status}'),
            const SizedBox(height: 6),
            Text('No leídos: ${thread.unreadCount}'),
          ],
        ),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
