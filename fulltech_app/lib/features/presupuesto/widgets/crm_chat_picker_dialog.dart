import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../crm/data/models/crm_thread.dart';
import '../../crm/state/crm_providers.dart';

class CrmChatPickerDialog extends ConsumerStatefulWidget {
  const CrmChatPickerDialog({super.key});

  @override
  ConsumerState<CrmChatPickerDialog> createState() =>
      _CrmChatPickerDialogState();
}

class _CrmChatPickerDialogState extends ConsumerState<CrmChatPickerDialog> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(crmThreadsControllerProvider.notifier).refresh();
    });

    _searchCtrl.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        final notifier = ref.read(crmThreadsControllerProvider.notifier);
        notifier.setSearch(_searchCtrl.text);
        notifier.refresh();
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(crmThreadsControllerProvider);

    final items = st.items;

    return AlertDialog(
      title: const Text('Seleccionar chat'),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Buscar por nombre o teléfono',
                suffixIcon: _searchCtrl.text.trim().isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpiar',
                        onPressed: () {
                          _searchCtrl.clear();
                          final notifier = ref.read(
                            crmThreadsControllerProvider.notifier,
                          );
                          notifier.setSearch('');
                          notifier.refresh();
                        },
                        icon: const Icon(Icons.clear),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            if (st.loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (st.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  st.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final t = items[i];
                    return _ChatTile(
                      thread: t,
                      onTap: () => Navigator.of(context).pop(t),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancelar'),
        ),
        TextButton.icon(
          onPressed: () =>
              ref.read(crmThreadsControllerProvider.notifier).refresh(),
          icon: const Icon(Icons.refresh),
          label: const Text('Actualizar'),
        ),
      ],
    );
  }
}

class _ChatTile extends StatelessWidget {
  final CrmThread thread;
  final VoidCallback onTap;

  const _ChatTile({required this.thread, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = (thread.displayName ?? '').trim().isNotEmpty
        ? thread.displayName!.trim()
        : (thread.phone ?? thread.waId).trim();

    final subtitleParts = <String>[];
    final phone = (thread.phone ?? '').trim();
    if (phone.isNotEmpty) subtitleParts.add(phone);
    final preview = (thread.lastMessagePreview ?? '').trim();
    if (preview.isNotEmpty) subtitleParts.add(preview);

    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.chat_bubble_outline)),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: subtitleParts.isEmpty
          ? null
          : Text(
              subtitleParts.join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: thread.unreadCount > 0
          ? Badge(label: Text(thread.unreadCount.toString()))
          : null,
      onTap: onTap,
    );
  }
}
